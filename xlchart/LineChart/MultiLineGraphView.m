//
//  MultiLineGraphView.m
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "MultiLineGraphView.h"
#import "LineGraphMarker.h"
#import "DRScrollView.h"
#import "Constants.h"
#import "LineChartDataRenderer.h"

const static CGFloat k_xAxisLabelHeight = 15;//x轴刻度值的高度
const static CGFloat k_graphVerticalMargin = 8;//x轴和x轴刻度值之间的空白、表格上方的空白(用于显示最上面的y刻度值的上半部分)
const static CGFloat k_graphHorizontalMargin = OFFSET_X * 2;//y轴刻度值的宽度，图标右侧的空白

@interface MultiLineGraphView()<UIScrollViewDelegate>{
    CGFloat width;
    CGFloat height;
}

@property (assign, nonatomic) CGFloat positionStepX;//相邻点的x方向距离，默认采用用户设置minPositionStepX。如果值过小，会修改以保证填满横向宽度
@property (assign, nonatomic) CGFloat positionStepY;
@property (assign, nonatomic) CGFloat yCeil;//实际采用的y轴刻度值的最大值，可能有点的y坐标比其还大。对于y坐标更大的点，画在最高的两条横线之间。
@property (assign, nonatomic) CGFloat yFloor;//实际采用的y轴刻度值的最小值，可能有点的y坐标比其还小。对于y坐标更小的点，画在x轴和次低横线之间。

@property (nonatomic, strong) CAShapeLayer *xMarker;//点击显示十字线的竖线
@property (nonatomic, strong) CAShapeLayer *yMarker;//点击显示十字线的横线
@property (nonatomic, strong) LineGraphMarker *marker;//点击显示的提示信息view
@property (nonatomic, strong) UIView *customMarkerView;//点击显示的自定义提示信息view

//self(graphScrollView(x-axis, y-axis, graphView 曲线图(), maker, customMarkerView), legendView)
@property (nonatomic, strong) LegendView *legendView;
@property (nonatomic, strong) DRScrollView *graphScrollView;
@property (nonatomic, strong) UIView *yAxisView;//固定的y轴和y刻度值
@property (nonatomic, strong) UIView *graphView;

@property (nonatomic, strong) NSArray *xAxisArray;//array of NSString, x轴的刻度，@""表示不显示该刻度值和竖直刻度线
@property (strong, nonatomic) NSMutableArray *xAxisLabels;//array of UILabel, 显示x轴的刻度值的label
@property (strong, nonatomic) NSMutableArray *yAxisValues;//array of NSNumber，y轴从下到上的刻度值，第一个yAxisValues[0]和最后一个yAxisValues[last]分别是数据点的y最小值和最大值，但是最小值和最大值如果差距太大则不会显示在y轴刻度上，其它元素之间的差值等于positionStepY。
@property (strong, nonatomic) NSMutableArray *positionYOfYAxisValues;//arrray of NSNumber，yAxisValues对应的y轴刻度值的view的y位置，从原点到最高点。

@property (nonatomic, strong) NSMutableArray *legendArray;//array of LegendDataRenderer
@property (nonatomic, strong) NSMutableArray *lineDataArray;//array of LineChartDataRenderer

@property (assign, nonatomic) CGFloat lastScale;
@property (assign, nonatomic) CGFloat scaleFactor;
@end

@implementation MultiLineGraphView
@synthesize delegate;
@synthesize dataSource;
@synthesize textFont;
@synthesize textColor;
@synthesize drawGridX;
@synthesize drawGridY;
@synthesize gridLineColor;
@synthesize gridLineWidth;
@synthesize enablePinch;
@synthesize showMarker;
@synthesize showCustomMarkerView;
@synthesize markerColor;
@synthesize markerTextColor;
@synthesize markerWidth;
@synthesize showLegend;
@synthesize legendViewType;
@synthesize minPositionStepX;
@synthesize segmentsOfYAxis;
@synthesize customMaxValidY;
@synthesize customMinValidY;
@synthesize presion;

@synthesize positionStepX;
@synthesize positionStepY;
@synthesize yCeil;
@synthesize yFloor;
@synthesize xMarker;
@synthesize yMarker;
@synthesize marker;
@synthesize customMarkerView;
@synthesize legendView;
@synthesize graphScrollView;
@synthesize yAxisView;
@synthesize graphView;
@synthesize xAxisArray;
@synthesize xAxisLabels;
@synthesize yAxisValues;
@synthesize positionYOfYAxisValues;
@synthesize legendArray;
@synthesize lineDataArray;
@synthesize lastScale;
@synthesize scaleFactor;

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.drawGridY = TRUE;
        self.drawGridX = TRUE;
        
        self.gridLineColor = [UIColor lightGrayColor];
        self.gridLineWidth = 0.3;
        
        self.textColor = [UIColor blackColor];
        self.textFont = [UIFont systemFontOfSize:12];
        
        self.markerColor = [UIColor orangeColor];
        self.markerTextColor = [UIColor whiteColor];
        self.markerWidth = 0.4;
        
        self.showLegend = TRUE;
        self.legendViewType = LegendTypeVertical;
        
        self.enablePinch = YES;
        self.showMarker = YES;
        self.showCustomMarkerView = NO;
        
        minPositionStepX = 30;
        segmentsOfYAxis = 5;
        customMaxValidY = MAXFLOAT / 4;
        customMinValidY = -MAXFLOAT / 4;
        self.presion = 0;
        
        scaleFactor = 1;
        lastScale = 1;
    }
    return self;
}

- (void)reloadGraph{
    [self.yAxisView removeFromSuperview];
    [self.graphScrollView removeFromSuperview];
    [self.legendView removeFromSuperview];
    
    [self drawGraph];
}

- (NSString *)yStringByPresion:(CGFloat)y{
    //返回y的精确度为presion的NSString
    NSString *formatter = [NSString stringWithFormat:@"%%.%zif", presion];
    return [NSString stringWithFormat:formatter, y];
}

#pragma mark Setup all data with dataSource
- (void)setupDataWithDataSource{
    self.xAxisArray = [self.dataSource xDataForLineToBePlotted];
    xAxisLabels = [[NSMutableArray alloc] init];
    yAxisValues = [[NSMutableArray alloc] init];
    positionYOfYAxisValues = [[NSMutableArray alloc] init];
    self.lineDataArray = [[NSMutableArray alloc] init];
    self.legendArray = [[NSMutableArray alloc] init];
    
    for (int i = 0 ; i < [self.dataSource numberOfLinesToBePlotted]; i++) {
        LineChartDataRenderer *lineData = [[LineChartDataRenderer alloc] init];
        lineData.lineColor = [self.dataSource colorForTheLineWithLineNumber:i];
        lineData.lineWidth = [self.dataSource widthForTheLineWithLineNumber:i];
        lineData.graphName = [self.dataSource nameForTheLineWithLineNumber:i];
        lineData.fillGraph = [self.dataSource shouldFillGraphWithLineNumber:i];
        lineData.drawPoints = [self.dataSource shouldDrawPointsWithLineNumber:i];
        lineData.yAxisArray = [self.dataSource dataForLineWithLineNumber:i];
        [self.lineDataArray addObject:lineData];
        
        LegendDataRenderer *data = [[LegendDataRenderer alloc] init];
        [data setLegendText:lineData.graphName];
        [data setLegendColor:lineData.lineColor];
        [self.legendArray addObject:data];
    }
}

#pragma mark Draw Graph: createXAxisLine, createYAxisLine, createGraph
- (void)drawGraph{
    [self setupDataWithDataSource];
    
    const CGFloat selfWidth = self.frame.size.width;
    CGFloat graphScrollHeight = self.frame.size.height;
    if (self.showLegend) {
        graphScrollHeight -= [LegendView getLegendHeightWithLegendArray:self.legendArray legendType:self.legendViewType withFont:self.textFont width:selfWidth - 2 * SIDE_PADDING];
    }
    /*
     ******界面布局******
     y轴和y轴刻度值在self上，覆盖在graphScrollView上面，这样在graphScrollView左右滑动时y轴刻度值仍会显示
     x轴和x轴刻度值、曲线在graphScrollView上，随graphScrollView左右滑动。
     x轴和y轴的刻度值都是label中点对准刻度线。
     原点的
        x刻度值xAxisLabel显示在y轴的正下方，也即xAxisLabel中心和y轴对齐。当x轴刻度值label左滑超过y轴，且超过label一半长度后，继续左滑逐渐变透明，也即xAxisLabel.alpha = xAxisLabel在y轴右边的长度/xAxisLabel半长。
        y刻度值显示在x轴的正左方，也即文字中点和x轴对齐，因此x轴下方余出k_graphVerticalMargin再显示x刻度值。
     由于x轴刻度值左滑过y轴才会逐渐透明，因此self、graphView、graphScrollView宽度一样，但在self左部覆盖一个柱形yAxisView遮住graphScrollView左小半部。
     
     ******view排列关系******
     self水平方向：
        self(yAxisView(宽度k_graphHorizontalMargin，显示y轴和y轴刻度值),
             graphScrollView(左小半部k_graphHorizontalMargin范围被yAxisView覆盖)
            )
     self竖直方向：
        graphScrollView
        LegendView
     
     如果y比y轴最大的刻度值还大，则y轴往上延伸一段表示无穷大，超大的数据点用空心而不是实心
     
     graphView占满graphScrollView，曲线点少则x相邻刻度值长度拉长，以保证graphView长度==graphScrollView长度；曲线点多则超过graphScrollView长度，需要左右滑动。graphScrollView.contentSize = graphView.frame.size
     水平方向：
        左边空白 k_graphHorizontalMargin
        曲线和各刻度线表格
        右边空白 k_graphHorizontalMargin
     竖直方向：
        空白 k_graphVerticalMargin
        曲线和各刻度线表格
        x轴
        空白 k_graphVerticalMargin
        x轴刻度值 k_xAxisLabelHeight
     */
    self.graphScrollView = [[DRScrollView alloc] initWithFrame:CGRectMake(0, 0, selfWidth, graphScrollHeight)];
    self.graphScrollView.showsVerticalScrollIndicator = NO;
    self.graphScrollView.showsHorizontalScrollIndicator = NO;
    self.graphScrollView.bounces = NO;
    self.graphScrollView.delegate = self;
    [self addSubview:self.graphScrollView];
    
    //长按后即使拖拽也不会触发scroll操作，即使 shouldRecognizeSimultaneouslyWithGestureRecognizer:返回YES也不行
    [self.graphScrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
    
    if (self.enablePinch) {
        [self.graphScrollView addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGraphZoom:)]];
    }
    
    self.graphView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, graphScrollHeight)];
    self.graphView.userInteractionEnabled = YES;
    [self.graphScrollView addSubview:self.graphView];
    
    self.yAxisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, k_graphHorizontalMargin, graphScrollHeight - k_xAxisLabelHeight)];
    self.yAxisView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.yAxisView];

    [self createXAxisLine];//设置x坐标和grid竖线，同时设置graphView的宽度。在yAxisView上显示y轴
    self.graphScrollView.contentSize = self.graphView.frame.size;
    //注意，如果self是navigationcontroller的第一个view，graphScrollView.contentInset.top自动设为64，需要设置viewController.automaticallyAdjustsScrollViewInsets = NO;
    [self createYAxisLine];//设置y坐标和grid横线。在yAxisView上显示y轴刻度值
    [self createGraph];
    
//
//    if (self.showMarker) {
//        [self createMarker];
//    }
//    if (self.showLegend) {
//        [self createLegend];
//    }
}

- (void)createXAxisLine{
    if (self.xAxisArray.count == 0) {
        return;//无x数据
    }
    
    void(^createXAxisLabel)() = ^(NSString *s, CGFloat centerX, CGFloat top){
        NSAttributedString *attrString = [LegendView getAttributedString:s withFont:self.textFont];
        CGSize textSize = [attrString boundingRectWithSize:CGSizeMake(MAXFLOAT, k_xAxisLabelHeight) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(centerX - textSize.width/2, top, textSize.width, textSize.height)];
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.7;
        l.attributedText = attrString;
        l.textColor = self.textColor;
        [self.graphView addSubview:l];
        [self.xAxisLabels addObject:l];
    };
    
    //如果self.xAxisArray只有一个，则只会显示y轴
    CGFloat everagePStepX = self.xAxisArray.count > 1 ? (self.graphScrollView.frame.size.width - k_graphHorizontalMargin * 2) / (self.xAxisArray.count - 1) : 0;
    positionStepX = MAX(minPositionStepX, everagePStepX);//保持相邻点的x方向距离>=minPositionStepX，同时尽量占满显示区域
    
    //划线的最高点和最低点的y
    const CGFloat positionYTop = k_graphVerticalMargin;
    const CGFloat positionYBottom = self.graphView.frame.size.height - k_graphVerticalMargin - k_xAxisLabelHeight;
    CGFloat x = k_graphHorizontalMargin;
    const CGFloat yOfXAxisLabel = positionYBottom + k_graphVerticalMargin;
    
    //在yAxisView上显示y轴
    [self.yAxisView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];;
    
    //在graphView上显示原点的x轴刻度值
    createXAxisLabel(self.xAxisArray[0], x, yOfXAxisLabel);
    
    //显示原点外的竖直刻度线和x轴刻度值。不显示@""的刻度，只显示非空的刻度，因此两个刻度之间可能包含多个曲线点
    for (int i = 1; i < self.xAxisArray.count; ++i) {
        x += positionStepX;
        NSString *xAxisString = self.xAxisArray[i];//x轴刻度
        if (xAxisString.length > 0) {//只显示非空的刻度值
            if (self.drawGridX) {
                //在graphView上显示其它竖线
                [self.graphView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];
            }
            //显示x轴刻度值
            createXAxisLabel(xAxisString, x, yOfXAxisLabel);
        }
    }
    
//    NSLog(@"x轴positionStepX[%f], 坐标：%@", positionStepX, self.xAxisArray);
    CGRect graphViewFrame = graphView.frame;
    graphViewFrame.size.width = x + k_graphHorizontalMargin;
    graphView.frame = graphViewFrame;
}

- (void)createYAxisLine{
    CGFloat minY = MAXFLOAT;
    CGFloat maxY = -MAXFLOAT;
    NSMutableSet *allPointsSet = [[NSMutableSet alloc] init];//所有曲线中不同的y值。注意[NSNumber numberWithFloat:]和[NSNumber numberWithDouble:]不同
    NSMutableArray *allPointsYOfLines = [NSMutableArray new];//所有曲线的所有点的y值，包括y相同的值
    for (LineChartDataRenderer *lineData in self.lineDataArray) {
        [allPointsSet addObjectsFromArray:lineData.yAxisArray];
        for (NSNumber *n in lineData.yAxisArray) {
            [allPointsYOfLines addObject:n];
            if (n.floatValue > maxY) {
                maxY = n.floatValue;
            }
            if (n.floatValue < minY) {
                minY = n.floatValue;
            }
        }
    }
    if (allPointsSet.count == 0) {
        return;//所有的lineDataArray.yAxisArray都没有点
    }
    
    void(^createYAxisLabel)() = ^(NSString *s, CGFloat right, CGFloat centerY){
        NSAttributedString *attrString = [LegendView getAttributedString:s withFont:self.textFont];
        CGSize textSize = [attrString boundingRectWithSize:CGSizeMake(k_graphHorizontalMargin, MAXFLOAT) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(right - textSize.width, centerY - textSize.height / 2, textSize.width, textSize.height)];
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.7;
        l.attributedText = attrString;
        l.textColor = self.textColor;
        [self.yAxisView addSubview:l];//在yAxisView上显示y刻度值
    };
    
    //画横线的区域，最高点和最低点的y
    const CGFloat positionYTop = k_graphVerticalMargin;
    const CGFloat positionYBottom = self.graphView.frame.size.height - k_graphVerticalMargin - k_xAxisLabelHeight;
    
    //是否应该显示最高横线、x轴的y刻度值。如果最高/最低的2根横线之间的刻度值和距离同其他横线按比例计算，则显示刻度值，否则不显示
    BOOL shouldShowMaxYLabel = YES;
    BOOL shouldShowMinYLabel = YES;
    
    if (allPointsSet.count <= 2) {//包含了所有点的y值相等，也即minY == maxY的情况
        //所有曲线的点y值相等或只有2种值，则除x轴外再画2个横线，最大的点在中间的横线上，另一个点在x轴上（若y值都相同则也在中间横线上），最高的横线上没有点
        //如果只有一种y值，则positionStepY设为该y值绝对值的一半，否则设为最大值和最小值的差
        self.positionStepY = (minY == maxY ? fabs(maxY / 2) : maxY - minY);//需要用绝对值，防止minY和maxY都为负数
        
        [yAxisValues addObject:@(maxY - self.positionStepY)];//原点的y轴刻度值
        [yAxisValues addObject:@(maxY)];//中间横线的y轴刻度值
        [yAxisValues addObject:@(maxY + self.positionStepY)];//最高横线的y轴刻度值
        
        [positionYOfYAxisValues addObject:@(positionYBottom)];//x轴的位置
        [positionYOfYAxisValues addObject:@((positionYTop + positionYBottom) / 2)];
        [positionYOfYAxisValues addObject:@(positionYTop)];//最高横线位置
        
        yCeil = maxY;
        yFloor = minY;
    }
    else{
        const CGFloat validYRange = customMaxValidY - customMinValidY;
        
        //如果有曲线>=3个点，可能某个点距其它2个点特别远，导致曲线不好看，需要检查最大最小值的差距是否 <= validYRange
        if (maxY - minY <= validYRange) {
            //在范围内，则直接将yCeil设为最大值，yFloor设为最小值
            yCeil = maxY;
            yFloor = minY;
        }
        else{
            //超过范围，选取满足 yCeil-yFloor>=validRange && 范围内包含80%以上的点、差值最小的yCeil和yFloor，其中yCeil和yFloor必然是2个不同点的y值（因为包含了80%以上的点）
            //注意，最后满足条件时可能出现yCeil == maxY && yFloor == minY，比如只有三个y值
            [allPointsYOfLines sortWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                return [obj1 compare:obj2];//所有点y值升序排列
            }];
            const int requiredNumber = ceil(allPointsYOfLines.count * 0.8);//最少要包含80%的点
            CGFloat currentMetRange = MAXFLOAT;//当前满足条件的yCeil-yFloor的范围差
            for (int i = 0; i <= allPointsYOfLines.count - requiredNumber; ++i) {
                CGFloat yAtIndexI = ((NSNumber *)allPointsYOfLines[i]).floatValue;
                int j = i + requiredNumber - 1;
                for (; j < allPointsYOfLines.count; ++j) {
                    CGFloat rangeBetweenIJ = ((NSNumber *)allPointsYOfLines[j]).floatValue - yAtIndexI;
                    if (rangeBetweenIJ >= validYRange) {
                        if (rangeBetweenIJ < currentMetRange) {
                            currentMetRange = rangeBetweenIJ;
                            yFloor = yAtIndexI;
                            yCeil = ((NSNumber *)allPointsYOfLines[j]).floatValue;
                        }
                        break;
                    }
                }
            }
        }
        
        //根据 yCeil跟maxY、yFloor跟minY 是否相等来计算positionStepY、y轴刻度值yAxisValues、刻度值在view中的y坐标positionYOfYAxisValues
        if (yCeil == maxY && yFloor == minY) {
            self.positionStepY = (positionYBottom - positionYTop) / segmentsOfYAxis;//totestwith @[@300, @300, @200, @-100, @-100]
            CGFloat valueStepY = (yCeil - yFloor) / segmentsOfYAxis;
            //x轴及全部横线的 位置、y轴刻度值
            for (int i = 0; i <= segmentsOfYAxis; ++i) {
                [yAxisValues addObject:@(yFloor + valueStepY * i)];
                [positionYOfYAxisValues addObject:@(positionYBottom - positionStepY * i)];
            }
        }
        else{//计算[yFloor, yCeil]两端的y刻度值和相邻刻度线长度
            //yFloor跟minY、yCeil跟maxY 不全相等，因此最低或最高两根横线的距离 <> 其他相邻横线通常距离positionStepY，受view高度限制规定最多为positionStepY的1.5倍，为了好看又限制>=positionStepY。
            const CGFloat maxMultipleMoreThanPositionStepY = 0.5;//最低或最高两根横线的距离比positionStepY多的最大倍数，多0.5倍也就是等于1.5倍
            if (yFloor == minY) {//x轴y刻度值为minY
                CGFloat valueStepY = (yCeil - yFloor) / (segmentsOfYAxis - 1);
                CGFloat valueOfYTop;//最高横线的y刻度值
                /*
                 原则：最高2横线的距离比通常距离大 0至maxMultipleMoreThanPositionStepY倍。(maxY - yCeil) / valueStepY <= 1.5倍时，最高横线的y刻度值和高度（1至1.5倍通常高度）成正比；大于等于1.5倍时，最高横线的y刻度值(为超大数)和高度（仍限定为1.5倍通常高度）不按比例，具体逻辑：
                 1. 如果maxY - yCeil <= valueStepY，则最高横线的y刻度值 设为 次高横线刻度值yCeil+valueStepY，最高2横线间距离同positionStepY，也即最高横线位置为positionYTop
                 2. 否则
                 2.1 如果maxY - yCeil > valueStepY 且 (maxY - yCeil - valueStepY) / valueStepY < maxMultipleMoreThanPositionStepY，则最高横线的刻度值设为maxY，最高2横线间的距离设为 positionStepY * (1 + 实际多的倍数)，根据positionStepY的计算方法可知最高横线位置恰好为positionYTop
                 2.2 否则，最高横线的刻度值设为maxY，最高横线间的距离设为 positionStepY * (1 + maxMultipleMoreThanPositionStepY)，也即最高横线位置为positionYTop
                 */
                if (maxY - yCeil <= valueStepY) {//最高2横线的实际距离同positionStepY
                    positionStepY = (positionYBottom - positionYTop) / segmentsOfYAxis;//totestwith @[@330, @300, @200, @-80, @-100]
                    valueOfYTop = yCeil + valueStepY;//>= maxY
                }
                else{
                    if ((maxY - yCeil - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {//最高2横线的实际距离按比例计算
                        positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + (maxY - yCeil - valueStepY) / valueStepY);//totestwith @[@420, @300, @200, @-80, @-100]
                    }
                    else{//最高2横线的实际距离设为positionStepY的(1 + maxMultipleMoreThanPositionStepY)倍
                        shouldShowMaxYLabel = NO;
                        positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + maxMultipleMoreThanPositionStepY);//totestwith @[@500, @300, @200, @-80, @-100]
                    }
                    valueOfYTop = maxY;
                }
                
                //除最高横线外的横线位置、y轴刻度值，包括x轴
                for (int i = 0; i < segmentsOfYAxis; ++i) {
                    [yAxisValues addObject:@(yFloor + valueStepY * i)];
                    [positionYOfYAxisValues addObject:@(positionYBottom - positionStepY * i)];
                }
                //最高横线的位置、y轴刻度值
                [yAxisValues addObject:@(valueOfYTop)];
                [positionYOfYAxisValues addObject:@(positionYTop)];
            }
            else if(yCeil == maxY){//最高横线y刻度值为maxY
                CGFloat valueStepY = (yCeil - yFloor) / (segmentsOfYAxis - 1);
                CGFloat valueOfYBottom;//最低横线（x轴）的y刻度值
                /*
                 原则：最低2横线的距离比通常距离大 0至maxMultipleMoreThanPositionStepY倍。(yFloor - minY) / valueStepY <= 1.5倍时，x轴的y刻度值和高度（1至1.5倍通常高度）成正比；大于等于1.5倍时，x轴的y刻度值(为超小数)和高度（仍限定为1.5倍通常高度）不按比例，具体逻辑：
                 原则：最低2横线的高度是其他横线高度的1-1.5倍，小于1.5倍时y刻度值和高度成正比，大于等于1.5倍时y刻度值(超小数)和高度不按比例，具体逻辑：
                 1. 如果yFloor - minY <= valueStepY，则x轴的y刻度值 设为 次低横线刻度值yFloor-valueStepY，最低2横线间距离同positionStepY，也即x轴为positionYBottom
                 2. 否则
                 2.1 如果yFloor - minY > valueStepY 且 (yFloor - minY - valueStepY) / valueStepY < maxMultipleMoreThanPositionStepY，则x轴横线的刻度值设为minY，最低2横线间的距离设为 positionStepY * (1 + 实际多的倍数)，根据positionStepY的计算方法可知x轴位置恰好为positionYBottom
                 2.2 否则，x轴的刻度值设为minY，最低横线间的距离设为 positionStepY * (1 + maxMultipleMoreThanPositionStepY)，也即x轴位置为positionYBottom
                 */
                if (yFloor - minY <= valueStepY) {//x轴同上面横线的实际距离同positionStepY
                    positionStepY = (positionYBottom - positionYTop) / segmentsOfYAxis;//totestwith @[@200, @200, @-50, @-200, @-220]
                    valueOfYBottom = yFloor-valueStepY;
                }
                else{
                    if ((yFloor - minY - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {//x轴同上面横线的实际距离按比例计算
                        positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + (yFloor - minY - valueStepY) / valueStepY);//totestwith @[@200, @200, @-50, @-200, @-330]
                    }
                    else{//x轴同上面横线的实际距离设为positionStepY的(1 + maxMultipleMoreThanPositionStepY)倍
                        shouldShowMinYLabel = NO;
                        positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + maxMultipleMoreThanPositionStepY);//totestwith @[@300, @200, @-50, @-100, @-1000]
                    }
                    valueOfYBottom = minY;
                }
                
                //x轴的位置、y轴刻度值
                [yAxisValues addObject:@(valueOfYBottom)];
                [positionYOfYAxisValues addObject:@(positionYBottom)];
                //除x轴外横线的位置、y轴刻度值
                for (int i = 1; i <= segmentsOfYAxis; ++i) {
                    [yAxisValues addObject:@(yCeil - valueStepY * (segmentsOfYAxis - i))];
                    [positionYOfYAxisValues addObject:@(positionYTop + positionStepY * (segmentsOfYAxis - i))];
                }
            }
            else{//x轴和最高横线y刻度值重新计算
                CGFloat valueStepY = (yCeil - yFloor) / (segmentsOfYAxis - 2);
                CGFloat valueOfYTop;
                CGFloat valueOfYBottom;
                
                CGFloat actualMultipleMoreThan_top;
                CGFloat actualMultipleMoreThan_bottom;
                if (maxY - yCeil <= valueStepY) {
                    actualMultipleMoreThan_top = 0;
                    valueOfYTop = yCeil + valueStepY;//totestwith @[@450, @300, @250, @210, @200, @150, @100, @-250, @-300, @-1000]
                }
                else{
                    if ((maxY - yCeil - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {
                        actualMultipleMoreThan_top = (maxY - yCeil - valueStepY) / valueStepY;//totestwith @[@520, @300, @250, @210, @200, @150, @100, @-250, @-300, @-1000]
                    }
                    else{
                        shouldShowMaxYLabel = NO;
                        actualMultipleMoreThan_top = maxMultipleMoreThanPositionStepY;//totestwith @[@700, @300, @250, @210, @200, @150, @100, @-250, @-300, @-1000]
                    }
                    valueOfYTop = maxY;
                }
                
                if (yFloor - minY <= valueStepY) {
                    actualMultipleMoreThan_bottom = 0;//totestwith @[@1000, @300, @250, @210, @200, @150, @100, @-250, @-300, @-380]
                    valueOfYBottom = yFloor - valueStepY;
                }
                else{
                    if ((yFloor - minY - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {
                        actualMultipleMoreThan_bottom = (yFloor - minY - valueStepY) / valueStepY;//totestwith @[@1000, @300, @250, @210, @200, @150, @100, @-250, @-300, @-520]
                    }
                    else{
                        shouldShowMinYLabel = NO;
                        actualMultipleMoreThan_bottom = maxMultipleMoreThanPositionStepY;//totestwith @[@1000, @300, @250, @210, @200, @150, @100, @-250, @-300, @-700]
                    }
                    valueOfYBottom = minY;
                }
                positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + actualMultipleMoreThan_top + actualMultipleMoreThan_bottom);
                
                //x轴的位置、y轴刻度值
                [yAxisValues addObject:@(valueOfYBottom)];
                [positionYOfYAxisValues addObject:@(positionYBottom)];
                
                CGFloat positionYFloor = positionYBottom - positionStepY * (1 + actualMultipleMoreThan_bottom);//x轴上方横线的位置
                //除x轴外横线的位置、y轴刻度值
                for (int i = 0; i < segmentsOfYAxis - 1; ++i) {
                    [yAxisValues addObject:@(yFloor + valueStepY * i)];
                    [positionYOfYAxisValues addObject:@(positionYFloor - positionStepY * i)];
                }
                
                //最高横线的位置、y轴刻度值
                [yAxisValues addObject:@(valueOfYTop)];
                [positionYOfYAxisValues addObject:@(positionYTop)];
            }
        }
    }
//    NSLog(@"所有点的y轴坐标：%@", allPointsYOfLines);
//    NSLog(@"y轴minY %f, yFloor %f, maxY %f, yCeil %f", minY, yFloor, maxY, yCeil);
//    NSLog(@"y轴坐标刻度值%zi个，%@", yAxisValues.count, yAxisValues);
//    NSLog(@"y轴坐标:%@", positionYOfYAxisValues);
    
    const CGFloat lineStartX = k_graphHorizontalMargin;//等于yAxisView的右边缘位置
    const CGFloat lineEndX = self.graphView.frame.size.width - k_graphHorizontalMargin;
    
    //显示x轴、原点的y轴刻度值
    [self.graphView.layer addSublayer:[self gridLineLayerStart:CGPointMake(lineStartX, positionYBottom) end:CGPointMake(lineEndX, positionYBottom)]];
    if (shouldShowMinYLabel) {
        createYAxisLabel([self yStringByPresion:((NSNumber *)yAxisValues[0]).floatValue], lineStartX, positionYBottom);
    }
    
    //显示除x轴外的横线、y轴刻度值
    for (int i =1; i < positionYOfYAxisValues.count; ++i) {
        CGFloat positionY = ((NSNumber *)positionYOfYAxisValues[i]).floatValue;
        if (self.drawGridY) {
            [self.graphView.layer addSublayer:[self gridLineLayerStart:CGPointMake(lineStartX, positionY) end:CGPointMake(lineEndX, positionY)]];
        }
        if (i < positionYOfYAxisValues.count - 1 || shouldShowMaxYLabel) {//非最高横线 或者 should显示最高横线刻度值
            createYAxisLabel([self yStringByPresion:((NSNumber *)yAxisValues[i]).floatValue], lineStartX, positionY);
        }
    }
}

- (void)createGraph{
    for (LineChartDataRenderer *lineData in self.lineDataArray) {
        int x = 0;
        int y = 0;
        
        y = [[lineData.yAxisArray objectAtIndex:0] floatValue] * positionStepY;
        
        CGPoint startPoint = CGPointMake(OFFSET_X, HEIGHT(self.graphView) - (OFFSET_Y + y));
        CGPoint firstPoint = startPoint;
        if (lineData.drawPoints) {
            [self drawPointsOnLine:startPoint withColor:lineData.lineColor];
        }
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        UIBezierPath *fillPath = [UIBezierPath bezierPath];
        [fillPath moveToPoint:startPoint];
        
        CGPoint endPoint;
        for (int i = 1; i < lineData.yAxisArray.count; i++){
            x = i * positionStepX;
            y = [[lineData.yAxisArray objectAtIndex:i] floatValue] * positionStepY;
            
            endPoint = CGPointMake(x + OFFSET_X, HEIGHT(self.graphView) - ( y + OFFSET_Y));
            
            [path appendPath:[self drawPathWithStartPoint:startPoint endPoint:endPoint]];
            
            [fillPath addLineToPoint:endPoint];
            
            startPoint = endPoint;
            if (lineData.drawPoints) {
                [self drawPointsOnLine:startPoint withColor:lineData.lineColor];
            }
        }
        
        [path closePath];
        [path stroke];
        
        CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
        [shapeLayer setPath:[path CGPath]];
        [shapeLayer setStrokeColor:lineData.lineColor.CGColor];
        [shapeLayer setLineWidth:lineData.lineWidth];
        [shapeLayer setShouldRasterize:YES];
        [shapeLayer setRasterizationScale:[[UIScreen mainScreen] scale]];
        [shapeLayer setContentsScale:[[UIScreen mainScreen] scale]];
        
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        [pathAnimation setDuration:ANIMATION_DURATION];
        [pathAnimation setFromValue:[NSNumber numberWithFloat:0.0f]];
        [pathAnimation setToValue:[NSNumber numberWithFloat:1.0f]];
        [shapeLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
        
        [self.graphView.layer addSublayer:shapeLayer];
        
        if (lineData.fillGraph) {
            [fillPath addLineToPoint:CGPointMake(startPoint.x, HEIGHT(self.graphView) - OFFSET_Y)];
            [fillPath addLineToPoint:CGPointMake(firstPoint.x, HEIGHT(self.graphView) - OFFSET_Y)];
            [fillPath addLineToPoint:firstPoint];
            [fillPath closePath];
            [fillPath stroke];
            
            [self fillGraphBackgroundWithPath:fillPath color:lineData.lineColor];
        }
    }
}

#pragma mark Create marker, legend
- (void)createMarker{
    self.marker = [[LineGraphMarker alloc] init];
    [self.marker setHidden:YES];
    [self.marker setFrame:CGRectZero];
    [self.marker setBgColor:self.markerColor];
    [self.marker setTextColor:self.markerTextColor];
    [self.marker setTextFont:self.textFont];
    [self.graphScrollView addSubview:self.marker];
    
    self.xMarker = [[CAShapeLayer alloc] init];
    [self.xMarker setStrokeColor:self.markerColor.CGColor];
    [self.xMarker setLineWidth:self.markerWidth];
    [self.xMarker setName:@"x_marker_layer"];
    [self.xMarker setHidden:YES];
    [self.graphScrollView.layer addSublayer:self.xMarker];
    
    self.yMarker = [[CAShapeLayer alloc] init];
    [self.yMarker setStrokeColor:self.markerColor.CGColor];
    [self.yMarker setLineWidth:self.markerWidth];
    [self.yMarker setName:@"y_marker_layer"];
    [self.yMarker setHidden:YES];
    [self.graphScrollView.layer addSublayer:self.yMarker];
}

- (void) createLegend{
    self.legendView = [[LegendView alloc] initWithFrame:CGRectMake(SIDE_PADDING, BOTTOM(self.graphView), WIDTH(self) - 2*SIDE_PADDING, 0)];
    [self.legendView setLegendArray:self.legendArray];
    [self.legendView setFont:self.textFont];
    [self.legendView setTextColor:self.textColor];
    [self.legendView setLegendViewType:self.legendViewType];
    [self.legendView createLegend];
    [self addSubview:self.legendView];
}

#pragma mark UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView == graphScrollView) {
        CGFloat comparedX = graphScrollView.contentOffset.x + k_graphHorizontalMargin;//坐标系原点距离左边缘 k_graphHorizontalMargin
        for (UILabel *l in xAxisLabels) {
            if (CGRectGetMaxX(l.frame) <= comparedX) {
                l.alpha = 0;
            }
            else{
                CGFloat halfWidth = l.frame.size.width / 2;
                CGFloat labelCenterRightYAxis = CGRectGetMaxX(l.frame) - comparedX;//label中点在y轴右侧的长度
                if (labelCenterRightYAxis >= halfWidth){//label中点在y轴右侧的长度>=半个长度
                    l.alpha = 1;
                }
                else{
                    //alpha = label中点在y轴右侧长度 / 半个长度
                    l.alpha = labelCenterRightYAxis / halfWidth;
                }
            }
        }
    }
}

#pragma mark handle gestures
-(void)handleTap:(UITapGestureRecognizer *)gesture{
    if (self.showMarker || self.showCustomMarkerView) {
        CGPoint pointTapped = [gesture locationInView:self.graphView];
        if (CGRectContainsPoint(self.graphView.frame, pointTapped)) {
            [self findValueForTouch:pointTapped];
        }
    }
}

- (void)handleGraphZoom:(UIPinchGestureRecognizer *)gesture{
    [self hideMarker];
    
    CGFloat pinchscale = [gesture scale];

    if (gesture.state == UIGestureRecognizerStateEnded)  {
        CGFloat pastScale = lastScale;
        
        width = pinchscale * width;
        scaleFactor = height;
        
        lastScale = pinchscale;
        
        if (width <= WIDTH(self)) {
            width = WIDTH(self);
            scaleFactor = height;
            lastScale = 1;
        }
        
        if (pastScale != lastScale) {
            [self zoomGraph];
        }
    }
}

- (void)zoomGraph{
    [self.graphView removeFromSuperview];
    
    self.graphView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, scaleFactor)];
    [self.graphView setUserInteractionEnabled:YES];
    
    [self createYAxisLine];
    [self createXAxisLine];
    [self createGraph];
    
    [self.graphView setNeedsDisplay];
    
    [self.graphScrollView addSubview:self.graphView];
    
    [self.graphScrollView setNeedsDisplay];
    
    [self addSubview:self.graphScrollView];
    [self.graphScrollView setContentSize:CGSizeMake(width, scaleFactor)];
    
    [self setNeedsDisplay];
}

-(CGPoint)pointForLine:(LineChartDataRenderer *)lineData at:(NSUInteger)pointIndex{
    CGFloat yValue = [[lineData.yAxisArray objectAtIndex:pointIndex] floatValue];
    CGFloat positionY = k_graphVerticalMargin + yValue * positionStepY;//todo yValue * positionStepY需要按比例计算
    return CGPointMake(k_graphHorizontalMargin + positionStepX * pointIndex, positionY);
}

#pragma mark Touch Action on a touch in a graph
- (void)findValueForTouch:(CGPoint)pointTouched{
    NSString *xString;
    NSNumber *yNumber;
    NSString *yString;//string presentation of yNumber
    CGFloat minDistance = MAXFLOAT;
    NSUInteger closestPointIndex = MAXFLOAT;
    CGPoint closestPoint;
    for (LineChartDataRenderer *lineData in self.lineDataArray) {
        for (int i = 0; i < lineData.yAxisArray.count; i++){
            CGPoint point = [self pointForLine:lineData at:i];
            CGFloat distance = fabs([self distanceBetweenPoint:pointTouched andPoint:point]);
            if (distance < minDistance) {
                minDistance = distance;
                closestPointIndex = i;
                closestPoint = point;
                xString = [self.xAxisArray objectAtIndex:i];
                yNumber = [lineData.yAxisArray objectAtIndex:i];
                yString = [self yStringByPresion:((NSNumber *)yNumber).floatValue];
            }
        }
    }
    
    [self hideMarker];
    
    if (minDistance > positionStepX / 2 || closestPointIndex == MAXFLOAT) {
        //距离过远的点不处理
        return;
    }
    
    if (((UILabel *)self.xAxisLabels[closestPointIndex]).alpha < 1) {
        //最近的点已经滑动到y轴左侧，不处理
        return;
    }
    
    [self.xMarker setPath:[[self drawPathWithStartPoint:CGPointMake(closestPoint.x, HEIGHT(self.graphView) - OFFSET_Y) endPoint:CGPointMake(closestPoint.x, OFFSET_Y)] CGPath]];
    [self.xMarker setHidden:NO];
    
    [self.yMarker setPath:[[self drawPathWithStartPoint:CGPointMake(OFFSET_X, closestPoint.y) endPoint:CGPointMake(WIDTH(self.graphView) - OFFSET_X, closestPoint.y)] CGPath]];
    [self.yMarker setHidden:NO];
    
    if (self.showCustomMarkerView){
        [self.marker setHidden:YES];
        [self.marker removeFromSuperview];
        
        self.customMarkerView = [self.dataSource customViewForLineChartTouchWithXValue:xString andYValue:yString];
        
        if (self.customMarkerView != nil) {
            CGFloat viewWidth = WIDTH(self.customMarkerView);
            CGFloat viewHeight = HEIGHT(self.customMarkerView);
            CGRect graphFrame = CGRectInset(self.graphView.frame, OFFSET_X, OFFSET_Y);
            
            //makerView优先显示在selectedPoint的左下角，如果显示不开则显示在右方或上方
            CGPoint makerViewOrigin = CGPointZero;
            if (graphFrame.size.height + graphFrame.origin.y - closestPoint.y >= viewHeight) {
                makerViewOrigin.y = closestPoint.y;
            }
            else{
                makerViewOrigin.y = closestPoint.y - viewHeight;
            }
            if (closestPoint.x - graphFrame.origin.x >= viewWidth) {
                makerViewOrigin.x = closestPoint.x - viewWidth;
            }
            else{
                makerViewOrigin.x = closestPoint.x;
            }
            
            [self.customMarkerView setFrame:CGRectMake(makerViewOrigin.x, makerViewOrigin.y, viewWidth, viewHeight)];
            [self.graphView addSubview:self.customMarkerView];
        }
        [self.graphScrollView addSubview:self.customMarkerView];
    }
    else if (self.showMarker) {
        [self.marker setXString:xString];
        [self.marker setYString:yString];
        [self.marker drawAtPoint:CGPointMake(closestPoint.x, OFFSET_Y)];
        [self.marker setHidden:NO];
    }
    
    [self setNeedsDisplay];
    
    if ([self.delegate respondsToSelector:@selector(didTapWithValuesAtX:valuesAtY:)]) {
        [self.delegate didTapWithValuesAtX:xString valuesAtY:yString];
    }
}

- (CGFloat)distanceBetweenPoint:(CGPoint)a andPoint:(CGPoint)b{
    CGFloat a2 = powf(a.x-b.x, 2.f);
    CGFloat b2 = powf(a.y-b.y, 2.f);
    return sqrtf(a2 + b2);
}

- (void)hideMarker{
    if (self.showCustomMarkerView){
        [self.customMarkerView removeFromSuperview];
    }
    else if (self.showMarker) {
        [self.marker setHidden:YES];
        [self.marker setFrame:CGRectZero];
    }
    
    [self.xMarker setHidden:YES];
    [self.yMarker setHidden:YES];
    
    [self setNeedsDisplay];
}

#pragma mark Graph line drawing operation
- (void)fillGraphBackgroundWithPath:(UIBezierPath *)path color:(UIColor *)color{
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    [shapeLayer setPath:path.CGPath];
    [shapeLayer setFillColor:color.CGColor];
    [shapeLayer setOpacity:0.1];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"fill"];
    [pathAnimation setDuration:ANIMATION_DURATION];
    [pathAnimation setFillMode:kCAFillModeForwards];
    [pathAnimation setFromValue:(id)[[UIColor clearColor] CGColor]];
    [pathAnimation setToValue:(id)[color CGColor]];
    [pathAnimation setBeginTime:CACurrentMediaTime()];
    [pathAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

    [shapeLayer addAnimation:pathAnimation forKey:@"fill"];
    
    [self.graphView.layer addSublayer:shapeLayer];
}

- (CAShapeLayer *)gridLineLayerStart:(CGPoint)startPoint end:(CGPoint)endPoint{
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    [shapeLayer setPath:[[self drawPathWithStartPoint:startPoint endPoint:endPoint] CGPath]];
    [shapeLayer setStrokeColor:self.gridLineColor.CGColor];
    [shapeLayer setLineWidth:self.gridLineWidth];
    return shapeLayer;
}

- (UIBezierPath *)drawPathWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];
    [path addLineToPoint:endPoint];
    
    [path closePath];
    
    return path;
}

- (void)drawPointsOnLine:(CGPoint)point withColor:(UIColor *)color{
    UIBezierPath *pointPath = [UIBezierPath bezierPath];
    [pointPath addArcWithCenter:point radius:3 startAngle:0 endAngle:2 * M_PI clockwise:YES];
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    [shapeLayer setPath:pointPath.CGPath];
    [shapeLayer setStrokeColor:[UIColor whiteColor].CGColor];
    [shapeLayer setFillColor:color.CGColor];
    [shapeLayer setLineWidth:1.0];
    [shapeLayer setShouldRasterize:YES];
    [shapeLayer setRasterizationScale:[[UIScreen mainScreen] scale]];
    [shapeLayer setContentsScale:[[UIScreen mainScreen] scale]];
    [self.graphView.layer addSublayer:shapeLayer];
}
@end
