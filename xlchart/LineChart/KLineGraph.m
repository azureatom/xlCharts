//
//  KLineGraph.m
//  xlchart
//
//  Created by lei xue on 16/9/12.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "KLineGraph.h"
#import "LineChartDataRenderer.h"
#import "Tool.h"

static const NSUInteger kMinutesBetweenHours = 59;//每相邻小时（如9:30至10:30）之间间隔59个一分钟
static const NSUInteger kNumberOfXAxisLabels = 5;//x轴总共显示5个刻度值：9:30, 10:30, 11:30, 14:00, 15:00

//y轴刻度值的label宽高，显示价格、涨幅的提示框。宽高 恰好显示完整2.123, -10.00%即可
static const CGFloat kYLabelWidth = 46;//y轴刻度值的label长度，显示价格、涨幅的提示框的长度。刚好显示完默认的12号字体-10.00%
static const CGFloat kYLabelHeight = 15;
//x轴刻度值的label长度，同self.heightXAxisLabel一起，恰好显示完整10:30即可
static const CGFloat kXLabelWidth = 32;//刚好显示完默认的12号字体

@interface KLineGraph()
@property (strong, nonatomic) NSMutableArray *lines;//array of LineChartDataRenderer *
@property (strong, nonatomic) NSMutableArray *rightYAxisValues;//array of NSNumber，最右边线从下到上的刻度值，百分数
@property (strong, nonatomic) NSArray *volumeArray;//成交量
@property (strong, nonatomic) UIView *volumeGraph;//成交量柱状图📊
@property (assign, nonatomic) CGFloat volumeGraphHeight;//成交量柱状图高度
@property (strong, nonatomic) NSMutableArray *volumeLayers;//显示在volumeGraph的所有竖条
@property (strong, nonatomic) CAShapeLayer *currentVolumeLayer;//当前选中的竖条
@property (strong, nonatomic) UILabel *markerLeft;//y轴右侧显示价格的提示框
@property (strong, nonatomic) UILabel *markerRight;//右边线左侧显示涨幅的提示框
@property (strong, nonatomic) UILabel *markerBottom;//x轴下方显示时间的提示框
@end

@implementation KLineGraph
@synthesize delegate;
@synthesize dataSource;
@synthesize yesterdayClosePrice;
@synthesize minPriceChangePercent;
@synthesize textUpColor;
@synthesize textDownColor;
@synthesize volumeColor;
@synthesize lines;
@synthesize rightYAxisValues;
@synthesize volumeArray;
@synthesize volumeGraph;
@synthesize volumeGraphHeight;
@synthesize volumeLayers;
@synthesize currentVolumeLayer;
@synthesize markerLeft;
@synthesize markerRight;
@synthesize markerBottom;

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.animationDuration = 0;
        self.graphMarginL = 5;
        self.graphMarginR = 5;
        self.graphMarginV = 0;
        self.heightXAxisLabel = kYLabelHeight;
        self.fractionDigits = 3;
        
        self.showMarker = YES;
        self.shouldDrawPoints = NO;
        
        yesterdayClosePrice = 0;
        minPriceChangePercent = 0.02;
        textUpColor = [UIColor redColor];
        textDownColor = [UIColor greenColor];
        volumeColor = [UIColor grayColor];
        
        NSMutableArray *emptyBetweenHours = [[NSMutableArray alloc] initWithCapacity:kMinutesBetweenHours];
        for (int i = 0; i < kMinutesBetweenHours; ++i) {
            [emptyBetweenHours addObject:@""];
        }
        NSMutableArray *allMinutes = [[NSMutableArray alloc] initWithCapacity:kMaxMinutesInTimeLine + 1];//每根成交量柱线对应一个positionStepX，一共kMaxMinutesInTimeLine根柱线
        [allMinutes addObject:@"9:30"];
        [allMinutes addObjectsFromArray:emptyBetweenHours];
        [allMinutes addObject:@"10:30"];
        [allMinutes addObjectsFromArray:emptyBetweenHours];
        [allMinutes addObject:@"11:30"];//对应11:30
        [allMinutes addObject:@""];//对应13:00
        [allMinutes addObjectsFromArray:emptyBetweenHours];
        [allMinutes addObject:@"14:00"];
        [allMinutes addObjectsFromArray:emptyBetweenHours];
        [allMinutes addObject:@"15:00"];
        [allMinutes addObject:@""];//对应15:01的刻度值
        self.xAxisArray = allMinutes;
    }
    return self;
}

//返回x轴的时间点字符串
-(NSString *)xAxisTimeString:(int)xIndex{
    if (xIndex < 121) {
        int hour = 9 + xIndex / 60;
        int minute = 30 + xIndex % 60;
        if (minute >= 60) {
            minute -= 60;
            hour += 1;
        }
        return [NSString stringWithFormat:@"%d:%02d", hour, minute];
    }
    else{
        xIndex -= 121;
        int hour = 13 + xIndex / 60;
        int minute = xIndex % 60;
        return [NSString stringWithFormat:@"%d:%02d", hour, minute];
    }
}

- (CGPoint)optimizedPoint:(CGPoint)point{
    return point;//因为分时图的线很密，两个点的坐标差值可能小于1，故不能对点坐标取整处理
}

/*竖直方向
 graphBackgroundView
 *  graphMarginV
 *  曲线坐标轴
 *  heightXAxisLabel
 成交量柱状图
 */
-(CGFloat)heightGraph{
    return [super heightGraph] - volumeGraphHeight;
}

-(CGFloat)heightYAxis{
    return [self heightGraph] - self.graphMarginV - self.heightXAxisLabel;
}

//返回成交量柱状图的frame
-(CGRect)volumeFrame{
    //volumeGraph 紧贴 graphBackgroundView 下方，左方空白为graphMarginL，长度同坐标系
    CGRect tempFrame = [self axisFrame];
    tempFrame.origin.y = CGRectGetMaxY(self.graphBackgroundView.frame);
    tempFrame.size.height = volumeGraphHeight;
    return tempFrame;
}

- (void)reloadGraph{
    /*原点对应9:30:00，x轴第一个刻度值对应9:31:00，倒数第二个刻度值对应15:00:00，最后一个刻度值对应15:01:00。刻度值只显示9:30, 10:30, 11:30(之后一个刻度值为13:00), 14:00, 15:00
     曲线上的点都是对应的x轴的刻度值，然后将各个点用线段连接。
     显示十字线marker时，竖直线和x轴刻度值对齐，而不是两个刻度值中点。显示markerLeft、markerRight、markerBottom三个提示框，但是不会显示成交量的提示框，因为网易分钟线的成交量误差较大。
     //删除该逻辑，因为实际不会有15:01的分钟线数据（如果选中的closestPointIndex对应的是刻度值15:01，则改为刻度值15:00的点，也即closestPointIndex改为kMaxMinutesInTimeLine - 1，closestPoint改为前一个点）。
     成交量柱状图volumeGraph，每条竖线对齐刻度值，线宽同gridLineWidth。十字线对应的当前柱状图，线宽扩大为positionStepX。
     */
    [super reloadGraph];
    [self createVolumeGraph];
}

#pragma mark Setup all data with dataSource
- (void)setupDataWithDataSource{
    self.xAxisLabels = [[NSMutableArray alloc] init];
    self.yAxisValues = [[NSMutableArray alloc] init];
    self.positionYOfYAxisValues = [[NSMutableArray alloc] init];
    rightYAxisValues = [[NSMutableArray alloc] init];
    if ([self.dataSource respondsToSelector:@selector(volumeDataInkLine:)]) {
        volumeArray = [self.dataSource volumeDataInkLine:self];
        volumeGraphHeight = [super heightGraph] * kVolumeHeightRatio;
        volumeLayers = [[NSMutableArray alloc] init];
    }
    else{
        volumeArray = nil;
        volumeGraphHeight = 0;
        volumeLayers = nil;
    }
    
    lines = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < [self.dataSource numberOfLinesInkLine:self]; ++i) {
        LineChartDataRenderer *line = [[LineChartDataRenderer alloc] init];
        line.lineColor = [self.dataSource kLine:self lineColor:i];
        line.lineWidth = [self.dataSource kLine:self lineWidth:i];
        line.fillGraph = NO;
        line.drawPoints = self.shouldDrawPoints;
        line.yAxisArray = [self.dataSource kLine:self yAxisDataForline:i];
        if (line.yAxisArray.count >= kMaxMinutesInTimeLine) {
            //最多不能超过kMaxMinutesInTimeLine个分钟
            line.yAxisArray = [line.yAxisArray subarrayWithRange:NSMakeRange(0, kMaxMinutesInTimeLine)];
        }
        [lines addObject:line];
    }
}

#pragma mark - 计算x轴和y轴的各种长度
-(BOOL)calculatePositionStepX{
    self.positionStepX = [self widthGraph] / (self.xAxisArray.count - 1);
    return YES;
}

-(void)calculatePointRadius{
    self.pointRadius = self.maxPointRadius;
    for (LineChartDataRenderer *line in self.lines) {
        if (line.lineWidth < self.pointRadius) {
            self.pointRadius = line.lineWidth;
        }
    }
}

/**
 *  计算yAxisValues、positionStepY、positionYOfYAxisValues
 */
- (void)calculateYAxis{
    double minPrice = yesterdayClosePrice * (1 - minPriceChangePercent);
    double maxPrice = yesterdayClosePrice * (1 + minPriceChangePercent);
    for (LineChartDataRenderer *l in lines) {
        for (NSNumber *n in l.yAxisArray) {
            double d = n.doubleValue;
            if (d < minPrice) {
                minPrice = d;
            }
            if (d > maxPrice) {
                maxPrice = d;
            }
        }
    }
    //获取最高价/最低价（取上下变动幅度至少为2%），计算得出和昨日收盘价的最大偏离值maxPriceChange。取上下偏离昨日收盘价maxPriceChange 的价格作为对称的上下价格范围，作为y轴最小值和最大值
    double maxPriceChange = fabs(maxPrice - yesterdayClosePrice);
    if (fabs(yesterdayClosePrice - minPrice) > maxPriceChange) {
        maxPriceChange = fabs(yesterdayClosePrice - minPrice);
    }
    maxPrice = yesterdayClosePrice + maxPriceChange;//价格上限
    minPrice = yesterdayClosePrice - maxPriceChange;//价格下限
    
    double increaseRate = yesterdayClosePrice == 0 ? 0 : maxPriceChange / yesterdayClosePrice * 100;//涨幅百分比上限
    double decreaseRate = yesterdayClosePrice == 0 ? 0 : -maxPriceChange / yesterdayClosePrice * 100;//跌幅百分比下限
    [rightYAxisValues addObject:[NSNumber numberWithDouble:decreaseRate]];
    [rightYAxisValues addObject:[NSNumber numberWithDouble:0]];
    [rightYAxisValues addObject:[NSNumber numberWithDouble:increaseRate]];
    
    //画横线的区域，最高点和最低点的y
    const CGFloat positionYTop = self.graphMarginV;
    const CGFloat positionYBottom = self.graphMarginV + [self heightYAxis];
    
    [self.yAxisValues addObject:[NSNumber numberWithDouble:minPrice]];//原点的y轴刻度值，价格下限
    [self.yAxisValues addObject:[NSNumber numberWithDouble:yesterdayClosePrice]];//昨日收盘价
    [self.yAxisValues addObject:[NSNumber numberWithDouble:maxPrice]];//最高横线的y轴刻度值，价格上限
    
    self.positionStepY = (positionYBottom - positionYTop) / 2;
    [self.positionYOfYAxisValues addObject:@(positionYBottom)];//x轴的位置
    [self.positionYOfYAxisValues addObject:@(positionYBottom - self.positionStepY)];
    [self.positionYOfYAxisValues addObject:@(positionYTop)];//最高横线位置
}

#pragma mark - 创建曲线背景，画x轴、y轴、曲线
-(void)createGraphBackground{
    [super createGraphBackground];
    [self addSubview:self.graphBackgroundView];
    [self.graphBackgroundView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapPanLongPress:)]];
    [self.graphBackgroundView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapPanLongPress:)]];
}

//设置x坐标和grid竖线，创建yAxisView并在其上显示y轴。根据x轴的宽度设置graphBackgroundView的宽度和backgroundScrollView.contentSize
- (void)drawXAxis{
    void(^createXAxisLabel)(NSString *, CGFloat, CGFloat, NSTextAlignment) = ^(NSString *s, CGFloat x, CGFloat top, NSTextAlignment alignment){
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, top, kXLabelWidth, self.heightXAxisLabel)];
        l.font = self.axisFont;
        l.textColor = self.textColor;
        l.text = s;
        l.textAlignment = alignment;
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.7;
        [self.graphBackgroundView addSubview:l];
        [self.xAxisLabels addObject:l];
    };
    
    //划线的最高点和最低点的y
    const CGFloat positionYTop = self.graphMarginV;
    const CGFloat positionYBottom = self.graphMarginV + [self heightYAxis];
    const CGFloat yOfXAxisLabel = positionYBottom + self.graphMarginV;//x轴刻度值label的y位置
    
    //显示竖线（包括y轴）和x轴刻度值（包括原点）
    int showingLineIndex = 0;//显示的是第几根竖线
    int i = 0;
    while (i < self.xAxisArray.count) {
        NSString *xText = self.xAxisArray[i];
        if (xText.length > 0) {
            CGFloat x = [self xPositionOfAxis:i];
            /*显示x轴刻度值和竖线
             其中第一个（y轴）和最右边线为实线，其他为虚线。其中最右边线在刻度值往外positionStepX处。
             右边线的刻度值显示在左侧，其他显示在竖线的右侧
             */
            if (showingLineIndex == 0) {
                createXAxisLabel(xText, x, yOfXAxisLabel, NSTextAlignmentLeft);
                [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];
            }
            else if (showingLineIndex == kNumberOfXAxisLabels - 1){
                createXAxisLabel(xText, x - kXLabelWidth, yOfXAxisLabel, NSTextAlignmentRight);
                x = [self xPositionOfAxis:i + 1];
                [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];
            }
            else{
                createXAxisLabel(xText, x - kXLabelWidth / 2, yOfXAxisLabel, NSTextAlignmentLeft);
                //虚线
                [self.graphBackgroundView.layer addSublayer:[Tool layerDashedFrom:CGPointMake(x, positionYTop) to:CGPointMake(x, positionYBottom) dashHeight:self.gridLineWidth dashLength:2 spaceLength:1 dashColor:self.gridLineColor]];
            }
            i += kMinutesBetweenHours;//相邻刻度值至少间隔kMinutesBetweenHours个positionStepX
            ++showingLineIndex;
        }
        else{
            ++i;
        }
    }
}

- (void)drawYAxis{
    void(^createYAxisLabel)(NSString *, CGRect, NSTextAlignment, UIColor *) = ^(NSString *s, CGRect labelFrame, NSTextAlignment alignment, UIColor *tColor){
        UILabel *l = [[UILabel alloc] initWithFrame:labelFrame];
        l.textColor = tColor;
        l.font = self.axisFont;
        l.text = s;
        l.textAlignment = alignment;
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.7;
        [self.graphBackgroundView addSubview:l];
    };
    
    const CGFloat lineStartX = self.graphMarginL;
    const CGFloat lineEndX = self.graphMarginL + [self widthXAxis];
    
    //显示x轴等横线，y轴刻度值（包括原点）
    for (int i = 0; i < self.positionYOfYAxisValues.count; ++i) {
        CGFloat positionY = ((NSNumber *)self.positionYOfYAxisValues[i]).floatValue;
        CGFloat labelY;
        if (i == 0){
            [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(lineStartX, positionY) end:CGPointMake(lineEndX, positionY)]];
            labelY = positionY - kYLabelHeight;
        }
        else if (i == self.positionYOfYAxisValues.count - 1){
            [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(lineStartX, positionY) end:CGPointMake(lineEndX, positionY)]];
            labelY = positionY;
        }
        else{
            //虚线
            [self.graphBackgroundView.layer addSublayer:[Tool layerDashedFrom:CGPointMake(lineStartX, positionY) to:CGPointMake(lineEndX, positionY) dashHeight:self.gridLineWidth dashLength:2 spaceLength:1 dashColor:self.gridLineColor]];
            labelY = positionY - kYLabelHeight / 2;
        }
        UIColor *yLabelColor = (i == 0 ? self.textDownColor : (i == self.positionYOfYAxisValues.count - 1 ? self.textUpColor : self.textColor));
        createYAxisLabel([self formattedStringForNumber:self.yAxisValues[i]], CGRectMake(lineStartX, labelY, kYLabelWidth, kYLabelHeight), NSTextAlignmentLeft, yLabelColor);
        createYAxisLabel([NSString stringWithFormat:@"%.02f%%", ((NSNumber *)rightYAxisValues[i]).doubleValue], CGRectMake(lineEndX - kYLabelWidth, labelY, kYLabelWidth, kYLabelHeight), NSTextAlignmentRight, yLabelColor);
    }
}

-(void)drawLines{
    for (LineChartDataRenderer *line in self.lines) {
        if (line.yAxisArray.count == 1) {
            //只有一个点时，将pointRadius设为positionStepX，这样看起来比较明显
            self.pointRadius = self.positionStepX;
            [self drawPointsOnLine:[self pointAtIndex:0 inLine:line] withColor:line.lineColor];
        }
        else{
            //曲线上不单独画点
            [self drawOneLine:line];
        }
    }
}

-(void)createMarker{
    if (self.xMarker != nil) {
        [self.xMarker removeFromSuperlayer];
        self.xMarker = nil;
    }
    if (self.yMarker != nil) {
        [self.yMarker removeFromSuperlayer];
        self.yMarker = nil;
    }
    if (markerLeft != nil) {
        [markerLeft removeFromSuperview];
        markerLeft = nil;
    }
    if (markerRight != nil) {
        [markerRight removeFromSuperview];
        markerRight = nil;
    }
    if (markerBottom != nil) {
        [markerBottom removeFromSuperview];
        markerBottom = nil;
    }
    
    if (!self.showMarker) {
        return;
    }
    
    self.xMarker = [[CAShapeLayer alloc] init];
    [self.xMarker setStrokeColor:self.markerColor.CGColor];
    [self.xMarker setLineWidth:self.markerWidth];
    [self.xMarker setName:@"x_marker_layer"];
    [self.xMarker setHidden:YES];
    [self.graphBackgroundView.layer addSublayer:self.xMarker];
    
    self.yMarker = [[CAShapeLayer alloc] init];
    [self.yMarker setStrokeColor:self.markerColor.CGColor];
    [self.yMarker setLineWidth:self.markerWidth];
    [self.yMarker setName:@"y_marker_layer"];
    [self.yMarker setHidden:YES];
    [self.graphBackgroundView.layer addSublayer:self.yMarker];
    
    markerLeft = [[UILabel alloc] initWithFrame:CGRectMake(self.graphMarginL, 0, kYLabelWidth, kYLabelHeight)];//只需修改y位置
    markerLeft.font = self.axisFont;
    markerLeft.textColor = self.markerTextColor;
    markerLeft.backgroundColor = self.markerBgColor;
    markerLeft.textAlignment = NSTextAlignmentCenter;
    markerLeft.adjustsFontSizeToFitWidth = YES;
    markerLeft.minimumScaleFactor = 0.7;
    markerLeft.hidden = YES;
    [self.graphBackgroundView addSubview:markerLeft];
    
    markerRight = [[UILabel alloc] initWithFrame:CGRectMake(self.graphMarginL + [self widthXAxis] - kYLabelWidth, 0, kYLabelWidth, kYLabelHeight)];//只需修改y位置
    markerRight.font = self.axisFont;
    markerRight.textColor = self.markerTextColor;
    markerRight.backgroundColor = self.markerBgColor;
    markerRight.textAlignment = NSTextAlignmentCenter;
    markerRight.adjustsFontSizeToFitWidth = YES;
    markerRight.minimumScaleFactor = 0.7;
    markerRight.hidden = YES;
    [self.graphBackgroundView addSubview:markerRight];
    
    markerBottom = [[UILabel alloc] initWithFrame:CGRectMake(0, self.graphMarginV + [self heightYAxis], kXLabelWidth, self.heightXAxisLabel)];//只需修改x位置
    markerBottom.font = self.axisFont;
    markerBottom.textColor = self.markerTextColor;
    markerBottom.backgroundColor = self.markerBgColor;
    markerBottom.textAlignment = NSTextAlignmentCenter;
    markerBottom.adjustsFontSizeToFitWidth = YES;
    markerBottom.minimumScaleFactor = 0.7;
    markerBottom.hidden = YES;
    [self.graphBackgroundView addSubview:markerBottom];
}

- (CGFloat)xPositionOfVolume:(NSUInteger)pointIndex{
    //第pointIndex个成交量线的位置，实际等于坐标系的点x除去左方空白graphMarginL
    return self.positionStepX * pointIndex;//等于[self xPositionOfAxis:pointIndex] - self.graphMarginL
}

- (void)createVolumeGraph{
    for (CAShapeLayer *l in volumeLayers) {
        [l removeFromSuperlayer];
    }
    [volumeLayers removeAllObjects];
    currentVolumeLayer = nil;//currentVolumeLayer是volumeLayers中的元素
    
    if (volumeGraph != nil) {
        [volumeGraph removeFromSuperview];
        volumeGraph = nil;
    }
    if (volumeGraphHeight == 0) {
        return;
    }
    
    volumeGraph = [[UIView alloc] initWithFrame:[self volumeFrame]];
    [self addSubview:volumeGraph];
    
    //volumeGraph四边为实线
    volumeGraph.layer.borderColor = self.gridLineColor.CGColor;
    volumeGraph.layer.borderWidth = self.gridLineWidth;
    
    //竖线的最高点和最低点的y
    const CGFloat volumeGraphYTop = 0;//成交量柱状图的高度范围
    const CGFloat volumeGraphYBottom = volumeGraphYTop + volumeGraphHeight;
    
    //显示竖线，实线和虚线的逻辑同drawXAxis方法
    int showingLineIndex = 0;//显示的是第几根竖线
    int i = 0;
    while (i < self.xAxisArray.count) {
        NSString *xText = self.xAxisArray[i];
        if (xText.length > 0) {
            CGFloat x = [self xPositionOfVolume:i];
            //中间的线都为虚线
            if (showingLineIndex != 0 && showingLineIndex != kNumberOfXAxisLabels - 1){
                [self.volumeGraph.layer addSublayer:[Tool layerDashedFrom:CGPointMake(x, volumeGraphYTop) to:CGPointMake(x, volumeGraphYBottom) dashHeight:self.gridLineWidth dashLength:2 spaceLength:1 dashColor:self.gridLineColor]];
            }
            i += kMinutesBetweenHours;//相邻刻度值至少间隔kMinutesBetweenHours个positionStepX
            ++showingLineIndex;
        }
        else{
            ++i;
        }
    }
    
    //最大成交量对应线高为volumeGraphHeight，其他成交量线高按比例
    long long maxVolume = 0;
    for (NSNumber * n in volumeArray) {
        if (n.longLongValue > maxVolume) {
            maxVolume = n.longLongValue;
        }
    }
    for (int i = 0; i < volumeArray.count; ++i) {
        long long volume = ((NSNumber *)volumeArray[i]).longLongValue;
        CGFloat volumeLineHeight = maxVolume == 0 ? 0 : volumeGraphHeight * volume / maxVolume;
        CGFloat x = [self xPositionOfVolume:i];
        CAShapeLayer *vLayer = [Tool layerLineFrom:CGPointMake(x, volumeGraphYBottom) to:CGPointMake(x, volumeGraphYBottom - volumeLineHeight) width:self.gridLineWidth color:volumeColor];
        [volumeLayers addObject:vLayer];
        [self.volumeGraph.layer addSublayer:vLayer];
    }
    
    //最后将最大成交量作为最大刻度值写到volumeGraph左上部
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, volumeGraphYTop, volumeGraph.frame.size.width, kYLabelHeight)];
    l.textColor = self.textColor;
    l.font = self.axisFont;
    l.text = [NSString stringWithFormat:@"%lld手", maxVolume / 100];
    l.textAlignment = NSTextAlignmentLeft;
    l.adjustsFontSizeToFitWidth = YES;
    l.minimumScaleFactor = 0.7;
    [self.volumeGraph addSubview:l];
}

- (void)dismissMarker{
    [super dismissMarker];
    if (self.markerLeft != nil) {
        self.markerLeft.hidden = YES;
    }
    if (self.markerRight != nil) {
        self.markerRight.hidden = YES;
    }
    if (self.markerBottom != nil) {
        self.markerBottom.hidden = YES;
    }
    if (currentVolumeLayer != nil) {
        currentVolumeLayer.lineWidth = self.gridLineWidth;
    }
    if ([self.delegate respondsToSelector:@selector(markerDidDismissInKLine:)]) {
        [self.delegate markerDidDismissInKLine:self];
    }
}

- (BOOL)showMakerNearPoint:(CGPoint)pointTouched checkXDistanceOnly:(BOOL)checkXDistanceOnly{
    [super showMakerNearPoint:pointTouched checkXDistanceOnly:checkXDistanceOnly];
    
    if (lines.count == 0) {
        //没有曲线
        return NO;
    }
    
    LineChartDataRenderer *line = lines.firstObject;
    CGFloat minDistance;
    CGPoint closestPoint;//距离最近的点
    int closestPointIndex = [self calculateClosestPoint:&closestPoint near:pointTouched distance:&minDistance inLine:line checkXDistanceOnly:checkXDistanceOnly];
    //实际不会有15:01的分钟线数据
    //closestPointIndex = MIN(closestPointIndex, kMaxMinutesInTimeLine - 1);//15:01的点index改为15:00
    //closestPoint = 前一个点
    if (closestPointIndex == -1) {
        //曲线没有点
        return NO;
    }
    
    //距离过远的点不处理
    if (!checkXDistanceOnly && minDistance > (self.positionStepX + self.positionStepY) * 0.8) {
        //不能简单比较 positionStepX / 2，如果x轴刻度很密集则该限制过紧，如果只有一个点则为0，所以需要综合positionStepX + positionStepY考虑
        return NO;
    }
    
    //选中的volumeLayer的线宽扩大为positionStepX
    if (volumeLayers.count > closestPointIndex) {
        currentVolumeLayer = volumeLayers[closestPointIndex];
        currentVolumeLayer.lineWidth = self.positionStepX;
    }
    
    closestPoint = [self optimizedPoint:closestPoint];
    
    self.xMarker.path = [self pathFrom:CGPointMake(closestPoint.x, CGRectGetMaxY([self volumeFrame])) to:CGPointMake(closestPoint.x, ((NSNumber *)self.positionYOfYAxisValues.lastObject).floatValue)].CGPath;
    self.xMarker.hidden = NO;
    
    self.yMarker.path = [self pathFrom:CGPointMake(self.originalPoint.x, closestPoint.y) to:CGPointMake([self xPositionOfAxis:self.xAxisArray.count <= 1 ? 1 : self.xAxisArray.count - 1], closestPoint.y)].CGPath;
    self.yMarker.hidden = NO;
    
    NSString *xTimeString = [self xAxisTimeString:closestPointIndex];
    NSNumber *priceNumber = line.yAxisArray[closestPointIndex];
    double changeRate = (priceNumber.doubleValue / yesterdayClosePrice - 1) * 100;//价格变动百分比
    NSString *priceString = [self formattedStringForNumber:priceNumber];
    NSString *changeRateString = [NSString stringWithFormat:@"%.02f%%", changeRate];
    
    //markerLeft和markerRight必须在x轴和最高横线之间，不能超出上下两边
    CGFloat maxValidY = self.graphMarginV + [self heightYAxis] - kYLabelHeight;
    
    CGRect tempFrame = self.markerLeft.frame;
    tempFrame.origin.y = closestPoint.y - tempFrame.size.height / 2;
    tempFrame.origin.y = MIN(tempFrame.origin.y, maxValidY);
    tempFrame.origin.y = MAX(tempFrame.origin.y, self.graphMarginV);
    self.markerLeft.frame = tempFrame;
    self.markerLeft.text = priceString;
    self.markerLeft.hidden = NO;
    
    tempFrame = self.markerRight.frame;
    tempFrame.origin.y = closestPoint.y - tempFrame.size.height / 2;
    tempFrame.origin.y = MIN(tempFrame.origin.y, maxValidY);
    tempFrame.origin.y = MAX(tempFrame.origin.y, self.graphMarginV);
    self.markerRight.frame = tempFrame;
    self.markerRight.text = changeRateString;
    self.markerRight.hidden = NO;
    
    tempFrame = self.markerBottom.frame;
    tempFrame.origin.x = closestPoint.x - tempFrame.size.width / 2;
    //markerBottom必须在y轴和右边线之间，不能超出两边
    CGFloat maxValidX = self.graphMarginL + [self widthXAxis] - kXLabelWidth;
    tempFrame.origin.x = MIN(tempFrame.origin.x, maxValidX);
    tempFrame.origin.x = MAX(tempFrame.origin.x, self.graphMarginL);
    self.markerBottom.frame = tempFrame;
    self.markerBottom.text = xTimeString;
    self.markerBottom.hidden = NO;
    
    if ([self.delegate respondsToSelector:@selector(kLine:didTapLine:atPoint:)]) {
        [self.delegate kLine:self didTapLine:0 atPoint:closestPointIndex];
    }
    return YES;
}

@end
