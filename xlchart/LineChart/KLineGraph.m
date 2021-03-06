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
#import "KLineElement.h"

//y轴刻度值的label宽高，显示价格、涨幅的提示框。宽高 恰好显示完整2.123, -10.00%即可
static const CGFloat kYLabelWidth = 46;//y轴刻度值的label长度，显示价格、涨幅的提示框的长度。刚好显示完默认的12号字体-10.00%
static const CGFloat kYLabelHeight = 15;
//x轴刻度值的label长度，同self.heightXAxisLabel一起，恰好显示完整2016-10即可
static const CGFloat kXLabelWidth = 67;//50刚好显示完默认的12号字体“2016-10”，67刚好显示完“2016-10-10”。但是marker需要显示“2016-10-10”，故用67
static const CGFloat kCandleWidthRatio = 0.9;//蜡烛图宽度占positionStepX宽度比例

@interface KLineGraph()
@property (assign, nonatomic) CGFloat shadowLineWidth;//上影线、下影线宽度
@property (strong, nonatomic) NSMutableArray *lines;//array of LineChartDataRenderer *
@property (strong, nonatomic) NSArray *kLineData;//array of KLineElement
@property (strong, nonatomic) UILabel *ma5Label;
@property (strong, nonatomic) UILabel *ma10Label;
@property (strong, nonatomic) UILabel *ma20Label;
@property (strong, nonatomic) UIView *volumeGraph;//成交量柱状图📊
@property (assign, nonatomic) CGFloat volumeGraphHeight;//成交量柱状图高度
@property (assign, nonatomic) CGFloat offsetFromVolumeToAxis;//成交量柱状图比曲线坐标图的x起点偏移
@property (strong, nonatomic) UILabel *markerBottom;//x轴下方显示时间的提示框
@end

@implementation KLineGraph
@synthesize kLinePeriod;
@synthesize delegate;
@synthesize dataSource;
@synthesize textUpColor;
@synthesize textDownColor;
@synthesize maxBarWidth;
@synthesize volumeHeightRatio;

@synthesize shadowLineWidth;
@synthesize lines;
@synthesize kLineData;
@synthesize ma5Label;
@synthesize ma10Label;
@synthesize ma20Label;
@synthesize volumeGraph;
@synthesize volumeGraphHeight;
@synthesize offsetFromVolumeToAxis;
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
        self.isXAtCenter = YES;
        
        self.showMarker = YES;
        self.shouldDrawPoints = NO;
        
        textUpColor = [UIColor redColor];
        textDownColor = [UIColor greenColor];
        maxBarWidth = 6;
        volumeHeightRatio = 0.25;
    }
    return self;
}

//返回x轴的时间点字符串
-(NSString *)xAxisDateString:(int)xIndex forMarker:(BOOL)isMarker{
    NSString *dateString = self.xAxisArray[xIndex];
    //x轴刻度值显示年月2016-10。marker显示日期2010-10-10
    return isMarker ? dateString : [dateString substringToIndex:7];
}

- (CGPoint)optimizedPoint:(CGPoint)point{
    return point;//因为分时图的线很密，两个点的坐标差值可能小于1，故不能对点坐标取整处理
}

-(CGFloat)widthXAxis{
    //x轴的长度 == graph除两边margin外的区域
    return [self widthGraph];
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
    /*y轴显示3个刻度值，最高价+0.1、中值、最低价-0.1。如果没有点，则显示为1, 0.5, 0；如果只有一个点值（也即最高价和最低价相同），则为+0.1， 该值，-0.1。
     x轴分三段，由2个竖直虚线间隔，加上两边的竖直实线，也即4个刻度值。每个刻度值对应竖线的k线日期，刻度值只显示年月，如“2016-09”
     x轴刻度值对应蜡烛图的中心，也即刻度段和蜡烛图对齐，成交量柱状图也和刻度段对齐。
     positionStepX 不超过 maxBarWidth。
     右上角显示MA5、MA10、MA20。
     成交量柱状图，线宽同positionStepX，分红色和绿色显示。
     显示十字线marker时，竖直线和x轴刻度值对齐，只显示markerBottom日期。
     */
    
    //在[super reloadGraph]代码基础上修改
    [self dismissMarker];
    
    [self setupDataWithDataSource];
    
    [self calculatePositionStepX];
    [self calculatePointRadius];
    [self calculateYAxis];
    self.originalPoint = CGPointMake([self xPositionAtIndex:0], ((NSNumber *)self.positionYOfYAxisValues.firstObject).floatValue);
    
    [self createGraphBackground];
    [self drawXAxis];
    [self drawYAxis];
    [self drawCandleStick];
    [self drawLines];
    [self drawMALabels];
    [self drawVolumeGraphBars];
    [self createMarker];
}

#pragma mark Setup all data with dataSource
- (void)setupDataWithDataSource{
    self.xAxisArray = [self.dataSource xAxisDataInKLine:self];
    self.xAxisLabels = [[NSMutableArray alloc] init];
    self.yAxisValues = [[NSMutableArray alloc] init];
    self.positionYOfYAxisValues = [[NSMutableArray alloc] init];
    self.kLineData = [self.dataSource kLineDataInkLine:self];
    volumeGraphHeight = [super heightGraph] * volumeHeightRatio;
    offsetFromVolumeToAxis = self.graphMarginL;
    
    lines = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < [self.dataSource numberOfLinesInkLine:self]; ++i) {
        LineChartDataRenderer *line = [[LineChartDataRenderer alloc] init];
        line.lineColor = [self.dataSource kLine:self lineColor:i];
        line.lineWidth = [self.dataSource kLine:self lineWidth:i];
        line.fillGraph = NO;
        line.drawPoints = self.shouldDrawPoints;
        line.yAxisArray = [self.dataSource kLine:self yAxisDataForline:i];
        [lines addObject:line];
    }
}

#pragma mark - 计算x轴和y轴的各种长度
-(BOOL)calculatePositionStepX{
    self.positionStepX = self.xAxisArray.count > 0 ? [self widthGraph] / self.xAxisArray.count : 0;
    if (self.positionStepX > maxBarWidth) {
        self.positionStepX = maxBarWidth;
    }
    //蜡烛图中，上影线的宽度 = MIN(1, 蜡烛图的宽度/2)
    shadowLineWidth = MIN(1, self.positionStepX / 4);
    return YES;
}

/**
 *  计算yAxisValues、positionStepY、positionYOfYAxisValues
 */
- (void)calculateYAxis{
    double minPrice = MAXFLOAT / 2;
    double maxPrice = -MAXFLOAT / 2;
    double middlePrice = 0;
    if (kLineData.count == 0) {
        //没有点
        maxPrice = 1;
        minPrice = 0;
        middlePrice = 0.5;
    }
    else{
        for (KLineElement *e in kLineData) {
            if (e.lowPrice < minPrice) {
                minPrice = e.lowPrice;
            }
            if (e.highPrice > maxPrice) {
                maxPrice = e.highPrice;
            }
        }
        maxPrice += 0.1;
        minPrice -= 0.1;
        if (minPrice < 0) {
            minPrice = 0;
        }
        //使中间价向上保留3位小数，同时距离minPrice和maxPrice相同
        middlePrice = [self fractionFloorOrCeiling:(minPrice + maxPrice) / 2 ceiling:YES];
        maxPrice = middlePrice + (middlePrice - minPrice);
    }
    
    //画横线的区域，最高点和最低点的y
    const CGFloat positionYTop = self.graphMarginV;
    const CGFloat positionYBottom = self.graphMarginV + [self heightYAxis];
    
    [self.yAxisValues addObject:[NSNumber numberWithDouble:minPrice]];//原点的y轴刻度值，价格下限
    [self.yAxisValues addObject:[NSNumber numberWithDouble:middlePrice]];
    [self.yAxisValues addObject:[NSNumber numberWithDouble:maxPrice]];//最高横线的y轴刻度值，价格上限
    
    self.positionStepY = (positionYBottom - positionYTop) / 2;
    [self.positionYOfYAxisValues addObject:@(positionYBottom)];//x轴的位置
    [self.positionYOfYAxisValues addObject:@(positionYBottom - self.positionStepY)];
    [self.positionYOfYAxisValues addObject:@(positionYTop)];//最高横线位置
}

#pragma mark - 创建曲线背景，画x轴、y轴、曲线
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
    
    //画x轴上的竖线前先创建volumeGraph，因为其和x轴的竖线位置相同，可以同时画竖线
    [self createVolumeGraph];
    
    //划线的最高点和最低点的y
    const CGFloat positionYTop = self.graphMarginV;
    const CGFloat positionYBottom = self.graphMarginV + [self heightYAxis];//y轴竖线的下端点位置，也即x轴刻度值label的y位置
    const CGFloat lineStartX = self.graphMarginL;
    const CGFloat spaceBetweenXLabels = [self widthXAxis] / 3;
    
    //x轴分三段，前后两根竖线为实线，中间2根竖线为虚线
    CGFloat x = lineStartX;
    [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];
    int xAxisIndex = [self indexOfXForPosition:x];
    if (xAxisIndex >= 0) {
        createXAxisLabel([self xAxisDateString:xAxisIndex forMarker:NO], x, positionYBottom, NSTextAlignmentLeft);
    }
    
    x += spaceBetweenXLabels;
    [self.graphBackgroundView.layer addSublayer:[Tool layerDashedFrom:CGPointMake(x, positionYTop) to:CGPointMake(x, positionYBottom) dashHeight:self.gridLineWidth dashLength:2 spaceLength:1 dashColor:self.gridLineColor]];
    xAxisIndex = [self indexOfXForPosition:x];
    if (xAxisIndex >= 0) {
        createXAxisLabel([self xAxisDateString:xAxisIndex forMarker:NO], x - kXLabelWidth / 2, positionYBottom, NSTextAlignmentCenter);
    }
    //成交量柱状图竖直虚线
    [self.volumeGraph.layer addSublayer:[Tool layerDashedFrom:CGPointMake(x - offsetFromVolumeToAxis, 0) to:CGPointMake(x - offsetFromVolumeToAxis, volumeGraphHeight) dashHeight:self.gridLineWidth dashLength:2 spaceLength:1 dashColor:self.gridLineColor]];
    
    x += spaceBetweenXLabels;
    [self.graphBackgroundView.layer addSublayer:[Tool layerDashedFrom:CGPointMake(x, positionYTop) to:CGPointMake(x, positionYBottom) dashHeight:self.gridLineWidth dashLength:2 spaceLength:1 dashColor:self.gridLineColor]];
    xAxisIndex = [self indexOfXForPosition:x];
    if (xAxisIndex >= 0) {
        createXAxisLabel([self xAxisDateString:xAxisIndex forMarker:NO], x - kXLabelWidth / 2, positionYBottom, NSTextAlignmentCenter);
    }
    //成交量柱状图竖直虚线
    [self.volumeGraph.layer addSublayer:[Tool layerDashedFrom:CGPointMake(x - offsetFromVolumeToAxis, 0) to:CGPointMake(x - offsetFromVolumeToAxis, volumeGraphHeight) dashHeight:self.gridLineWidth dashLength:2 spaceLength:1 dashColor:self.gridLineColor]];
    
    x += spaceBetweenXLabels;
    [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];
    xAxisIndex = [self indexOfXForPosition:x];
    if (xAxisIndex >= 0) {
        createXAxisLabel([self xAxisDateString:xAxisIndex forMarker:NO], x - kXLabelWidth, positionYBottom, NSTextAlignmentRight);
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
            if (self.showTopYLine) {
                [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(lineStartX, positionY) end:CGPointMake(lineEndX, positionY)]];
            }
            labelY = positionY;
        }
        else{
            //虚线
            [self.graphBackgroundView.layer addSublayer:[Tool layerDashedFrom:CGPointMake(lineStartX, positionY) to:CGPointMake(lineEndX, positionY) dashHeight:self.gridLineWidth dashLength:2 spaceLength:1 dashColor:self.gridLineColor]];
            labelY = positionY - kYLabelHeight / 2;
        }
        createYAxisLabel([self formattedStringForNumber:self.yAxisValues[i]], CGRectMake(lineStartX, labelY, kYLabelWidth, kYLabelHeight), NSTextAlignmentLeft, self.textColor);
    }
}

-(void)drawLines{
    for (LineChartDataRenderer *line in [self.lines reverseObjectEnumerator]) {
        if (line.yAxisArray.count == 1) {
            //只有一个点时，画一条长为positionStepX的横线，占满一个positionStepX
            CGFloat xLeft = [self xPositionAtIndex:0] - self.positionStepX / 2;
            CGFloat xRight = xLeft + self.positionStepX;
            CGFloat y = [self yPositionAtIndex:0 inLine:line];
            [self.graphBackgroundView.layer addSublayer:[Tool layerLineFrom:CGPointMake(xLeft, y) to:CGPointMake(xRight, y) width:self.gridLineWidth color:self.gridLineColor]];
        }
        else{
            [self drawOneLine:line];
        }
    }
}

-(void)drawCandleStick{
    CGFloat candleWidth = self.positionStepX * kCandleWidthRatio;
    for (int i = 0; i < kLineData.count; ++i) {
        KLineElement *e = kLineData[i];
        UIColor *candleColor = e.closePrice >= e.openPrice ? self.textUpColor : self.textDownColor;
        CGFloat xCenter = [self xPositionAtIndex:i];
        //上下影线
        [self.graphBackgroundView.layer addSublayer:[Tool layerLineFrom:CGPointMake(xCenter, [self yPositionOfValue:e.highPrice]) to:CGPointMake(xCenter, [self yPositionOfValue:e.lowPrice]) width:shadowLineWidth color:candleColor]];
        //蜡烛图实体。红色蜡烛图采用空心？
        [self.graphBackgroundView.layer addSublayer:[Tool layerLineFrom:CGPointMake(xCenter, [self yPositionOfValue:e.openPrice]) to:CGPointMake(xCenter, [self yPositionOfValue:e.closePrice]) width:candleWidth color:candleColor]];
    }
}

-(void)drawMALabels{
    if (ma5Label != nil) {
        [ma5Label removeFromSuperview];
    }
    if (ma10Label != nil) {
        [ma10Label removeFromSuperview];
    }
    if (ma20Label != nil) {
        [ma20Label removeFromSuperview];
    }
    
    CGRect axisF = [self axisFrame];
    CGFloat maLabelWidth = axisF.size.width / 5;//坐标系x轴分5部分，后三部分显示MA5:2.123等
    
    CGRect labelFrame = CGRectMake(CGRectGetMaxX(axisF) - maLabelWidth, axisF.origin.y, maLabelWidth, 20);
    ma20Label = [[UILabel alloc] initWithFrame:labelFrame];

    labelFrame.origin.x -= maLabelWidth;
    ma10Label = [[UILabel alloc] initWithFrame:labelFrame];
    
    labelFrame.origin.x -= maLabelWidth;
    ma5Label = [[UILabel alloc] initWithFrame:labelFrame];
    
    NSArray *maLabels = @[ma5Label, ma10Label, ma20Label];
    for (UILabel *l in maLabels) {
        l.textAlignment = NSTextAlignmentLeft;
        l.font = [UIFont systemFontOfSize:9];
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.7;
        [self.graphBackgroundView addSubview:l];
    }
    //maLabels的数目应该 <= lines的数目
    for (int i = 0; i < lines.count && i < maLabels.count; ++i) {
        //设置maLabels的文字颜色
        LineChartDataRenderer *l = lines[i];
        ((UILabel *)maLabels[i]).textColor = l.lineColor;
    }
    
    [self restoreMALabels];
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
    
    markerBottom = [[UILabel alloc] initWithFrame:CGRectMake(0, self.graphMarginV + [self heightYAxis], kXLabelWidth, self.heightXAxisLabel)];//只需修改x位置
    markerBottom.font = [UIFont fontWithName:self.axisFont.fontName size:self.axisFont.pointSize - 2];//使用小点的字体，使文字左右留出空间好看
    markerBottom.textColor = self.markerTextColor;
    markerBottom.backgroundColor = self.markerBgColor;
    markerBottom.textAlignment = NSTextAlignmentCenter;
    markerBottom.adjustsFontSizeToFitWidth = YES;
    markerBottom.minimumScaleFactor = 0.7;
    markerBottom.layer.masksToBounds = YES;
    markerBottom.layer.cornerRadius = self.heightXAxisLabel / 4;
    markerBottom.hidden = YES;
    [self.graphBackgroundView addSubview:markerBottom];
}

- (void)createVolumeGraph{
    if (volumeGraph != nil) {
        [volumeGraph removeFromSuperview];
        volumeGraph = nil;
    }
    if (volumeGraphHeight == 0) {
        return;
    }
    
    volumeGraph = [[UIView alloc] initWithFrame:[self volumeFrame]];
    //volumeGraph四边为实线
    volumeGraph.layer.borderColor = self.gridLineColor.CGColor;
    volumeGraph.layer.borderWidth = self.gridLineWidth;
    [self insertSubview:volumeGraph belowSubview:self.graphBackgroundView];//volumeGraph必须放在graphBackgroundView下方，这样marker十字线才能显示在成交量柱状图上面
}

- (void)drawVolumeGraphBars{
    //竖线的最高点和最低点的y
    const CGFloat volumeGraphYTop = 0;//成交量柱状图的高度范围
    const CGFloat volumeGraphYBottom = volumeGraphYTop + volumeGraphHeight;
    const CGFloat volumeWidth = self.positionStepX * kCandleWidthRatio;
    
    //最大成交量对应线高为volumeGraphHeight，其他成交量线高按比例
    double maxVolume = 0;//成交量单位为手
    for (KLineElement *e in kLineData) {
        if (e.volume > maxVolume) {
            maxVolume = e.volume;
        }
    }
    for (int i = 0; i < kLineData.count; ++i) {
        KLineElement *e = kLineData[i];
        CGFloat volumeBarHeight = maxVolume == 0 ? 0 : volumeGraphHeight * e.volume / maxVolume;
        CGFloat x = [self xPositionAtIndex:i] - offsetFromVolumeToAxis;
        //volume bar占满x刻度段，收盘价>=开盘价 为红色，否则为绿色
        CAShapeLayer *vLayer = [Tool layerLineFrom:CGPointMake(x, volumeGraphYBottom) to:CGPointMake(x, volumeGraphYBottom - volumeBarHeight) width:volumeWidth color:(e.closePrice >= e.openPrice ? self.textUpColor : self.textDownColor)];
        [self.volumeGraph.layer addSublayer:vLayer];
    }

    //最后将最大成交量作为最大刻度值写到volumeGraph左上部
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, volumeGraphYTop, volumeGraph.frame.size.width, kYLabelHeight)];
    l.textColor = self.textColor;
    l.font = self.axisFont;
    l.text = [[Tool smartNumberRepresentation:maxVolume] stringByAppendingString:@"手"];
    l.textAlignment = NSTextAlignmentLeft;
    l.adjustsFontSizeToFitWidth = YES;
    l.minimumScaleFactor = 0.7;
    [self.volumeGraph addSubview:l];
}

-(void)restoreMALabels{
    if (kLineData.count == 0) {
        ma5Label.text = @"MA5:";
        ma10Label.text = @"MA10:";
        ma20Label.text = @"MA20:";
    }
    else{
        KLineElement *e = kLineData.lastObject;
        ma5Label.text = [NSString stringWithFormat:@"MA5:%.03f", e.ma5];
        ma10Label.text = [NSString stringWithFormat:@"MA10:%.03f", e.ma10];
        ma20Label.text = [NSString stringWithFormat:@"MA20:%.03f", e.ma20];
    }
}

- (void)dismissMarker{
    [super dismissMarker];
    if (self.markerBottom != nil) {
        self.markerBottom.hidden = YES;
    }
    [self restoreMALabels];
    if ([self.delegate respondsToSelector:@selector(didMarkerDismissInKLine:)]) {
        [self.delegate didMarkerDismissInKLine:self];
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
    if (closestPointIndex == -1) {
        //曲线没有点
        return NO;
    }
    
    //距离过远的点不处理
    if (!checkXDistanceOnly && minDistance > (self.positionStepX + self.positionStepY) * 0.8) {
        //不能简单比较 positionStepX / 2，如果x轴刻度很密集则该限制过紧，如果只有一个点则为0，所以需要综合positionStepX + positionStepY考虑
        return NO;
    }
    
    closestPoint = [self optimizedPoint:closestPoint];
    
    self.xMarker.path = [self pathFrom:CGPointMake(closestPoint.x, CGRectGetMaxY([self volumeFrame])) to:CGPointMake(closestPoint.x, ((NSNumber *)self.positionYOfYAxisValues.lastObject).floatValue)].CGPath;
    self.xMarker.hidden = NO;
    
    self.yMarker.path = [self pathFrom:CGPointMake(self.originalPoint.x, closestPoint.y) to:CGPointMake([self xPositionAtIndex:self.xAxisArray.count <= 1 ? 1 : self.xAxisArray.count - 1], closestPoint.y)].CGPath;
    self.yMarker.hidden = NO;
    
    CGRect tempFrame = self.markerBottom.frame;
    tempFrame.origin.x = closestPoint.x - tempFrame.size.width / 2;
    //markerBottom必须在y轴和右边线之间，不能超出两边
    CGFloat maxValidX = self.graphMarginL + [self widthXAxis] - kXLabelWidth;
    tempFrame.origin.x = MIN(tempFrame.origin.x, maxValidX);
    tempFrame.origin.x = MAX(tempFrame.origin.x, self.graphMarginL);
    self.markerBottom.frame = tempFrame;
    self.markerBottom.text = [self xAxisDateString:closestPointIndex forMarker:YES];
    self.markerBottom.hidden = NO;
    
    KLineElement *e = kLineData[closestPointIndex];
    ma5Label.text = [NSString stringWithFormat:@"MA5:%.03f", e.ma5];
    ma10Label.text = [NSString stringWithFormat:@"MA10:%.03f", e.ma10];
    ma20Label.text = [NSString stringWithFormat:@"MA20:%.03f", e.ma20];
    
    if ([self.delegate respondsToSelector:@selector(kLine:didTapLine:atPoint:)]) {
        [self.delegate kLine:self didTapLine:0 atPoint:closestPointIndex];
    }
    return YES;
}

@end
