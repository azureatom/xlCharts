//
//  MultiLineGraph.m
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "MultiLineGraph.h"
#import "LineGraphMarker.h"
#import "LineChartDataRenderer.h"

//保留fractionDigits位小数的上值、下值
#define CeilWithDigits(x) ceil(x * pow(10, self.fractionDigits)) / pow(10, self.fractionDigits)
#define FloorWithDigits(x) floor(x * pow(10, self.fractionDigits)) / pow(10, self.fractionDigits)

@interface MultiLineGraph()<UIScrollViewDelegate>
@property (assign, nonatomic) CGFloat positionStepX;//相邻点的x方向距离，默认采用用户设置minPositionStepX。如果值过小，会修改以保证填满横向宽度
@property (assign, nonatomic) CGFloat positionStepY;

@property (nonatomic, strong) CAShapeLayer *xMarker;//点击显示十字线的竖线
@property (nonatomic, strong) CAShapeLayer *yMarker;//点击显示十字线的横线
@property (nonatomic, strong) LineGraphMarker *marker;//点击显示的提示信息view
@property (nonatomic, strong) UIView *customMarkerView;//点击显示的自定义提示信息view

//self(graphScrollView(x-axis, y-axis, graphView 曲线图(), maker, customMarkerView), legendView)
@property (nonatomic, strong) LegendView *legendView;
@property (nonatomic, strong) UIScrollView *graphScrollView;
@property (nonatomic, strong) UIView *yAxisView;//固定的y轴和y刻度值
@property (nonatomic, strong) UIView *graphView;

@property (assign, nonatomic) CGFloat pointRadius; //曲线上画的点的半径，默认1.5
@property (nonatomic, strong) NSArray *xAxisArray;//array of NSString, x轴的刻度，@""表示不显示该刻度值和竖直刻度线
@property (strong, nonatomic) NSMutableArray *xAxisLabels;//array of UILabel, 显示x轴的刻度值的label
@property (strong, nonatomic) NSMutableArray *yAxisValues;//array of NSNumber，y轴从下到上的刻度值，第一个yAxisValues[0]和最后一个yAxisValues[last]分别是数据点的y最小值和最大值，但是最小值和最大值如果差距太大则不会显示在y轴刻度上，其它元素之间的差值等于positionStepY。
@property (strong, nonatomic) NSMutableArray *positionYOfYAxisValues;//arrray of NSNumber，yAxisValues对应的y轴刻度值的view的y位置，从原点到最高点。

@property (nonatomic, strong) NSMutableArray *legendArray;//array of LegendDataRenderer
@property (nonatomic, strong) NSMutableArray *lineDataArray;//array of LineChartDataRenderer
@end

@implementation MultiLineGraph
@synthesize delegate;
@synthesize dataSource;
@synthesize textFont;
@synthesize textColor;
@synthesize fractionDigits;
@synthesize drawGridX;
@synthesize drawGridY;
@synthesize gridLineColor;
@synthesize gridLineWidth;
@synthesize enablePanAndLongPress;
@synthesize showMarker;
@synthesize showCustomMarkerView;
@synthesize markerColor;
@synthesize markerTextColor;
@synthesize markerWidth;
@synthesize showLegend;
@synthesize legendViewType;
@synthesize minPositionStepX;
@synthesize spaceBetweenVisibleXLabels;
@synthesize segmentsOfYAxis;
@synthesize customMaxValidY;
@synthesize customMinValidY;
@synthesize filterYOutOfRange;
@synthesize filteredIndexArray;

@synthesize positionStepX;
@synthesize positionStepY;
@synthesize xMarker;
@synthesize yMarker;
@synthesize marker;
@synthesize customMarkerView;
@synthesize legendView;
@synthesize graphScrollView;
@synthesize yAxisView;
@synthesize graphView;
@synthesize pointRadius;
@synthesize xAxisArray;
@synthesize xAxisLabels;
@synthesize yAxisValues;
@synthesize positionYOfYAxisValues;
@synthesize legendArray;
@synthesize lineDataArray;

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.drawGridY = TRUE;
        self.drawGridX = TRUE;
        
        self.gridLineColor = [UIColor lightGrayColor];
        self.gridLineWidth = 0.3;
        
        self.textColor = [UIColor blackColor];
        self.textFont = [UIFont systemFontOfSize:12];
        self.fractionDigits = 0;
        
        self.markerColor = [UIColor orangeColor];
        self.markerTextColor = [UIColor whiteColor];
        self.markerWidth = 0.4;
        
        self.showLegend = TRUE;
        self.legendViewType = LegendTypeVertical;
        
        self.enablePanAndLongPress = YES;
        self.showMarker = YES;
        self.showCustomMarkerView = NO;
        
        minPositionStepX = (320 - graphMarginL - graphMarginR) / 10;//25
        spaceBetweenVisibleXLabels = 60;
        segmentsOfYAxis = 5;
        customMaxValidY = MAXFLOAT / 4;
        customMinValidY = -MAXFLOAT / 4;
        filterYOutOfRange = NO;
        filteredIndexArray = nil;
    }
    return self;
}

- (void)reloadGraph{
    [self.yAxisView removeFromSuperview];
    [self.graphScrollView removeFromSuperview];
    [self.legendView removeFromSuperview];
    
    [self drawGraph];
}

- (CGFloat)visibleWidthExcludeMargin{
    return graphScrollView.frame.size.width - graphMarginL - graphMarginR;
}

- (NSString *)formattedStringForNumber:(NSNumber *)n{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = YES;
    formatter.groupingSeparator = @",";
    formatter.groupingSize = 3;//每千位逗号分隔
    formatter.roundingMode = NSNumberFormatterRoundHalfUp;//四舍五入
    formatter.minimumFractionDigits = fractionDigits;
    formatter.maximumFractionDigits = fractionDigits;
    formatter.alwaysShowsDecimalSeparator = NO;//是否总显示小数点号，如1.0显示为1.而12显示为12.
    return [formatter stringFromNumber:n];
}

- (CGPoint)optimizedPoint:(CGPoint)point{
    //当view的位置不是整数或者0.5的倍数时，由于屏幕分辨率和像素匹配问题，view显示会略微模糊
    return CGPointMake(floor(point.x), floor(point.y));
}

#pragma mark Setup all data with dataSource
- (void)setupDataWithDataSource{
    if ([self.dataSource respondsToSelector:@selector(lineGraph:pointRadius:)]) {
        pointRadius = [self.dataSource lineGraph:self pointRadius:0];
    }
    else{
        pointRadius = 1.5;
    }
    xAxisLabels = [[NSMutableArray alloc] init];
    yAxisValues = [[NSMutableArray alloc] init];
    positionYOfYAxisValues = [[NSMutableArray alloc] init];
    self.lineDataArray = [[NSMutableArray alloc] init];
    self.legendArray = [[NSMutableArray alloc] init];
    
    filteredIndexArray = nil;
    for (int i = 0 ; i < [self.dataSource lineGraphNumberOfLines:self]; i++) {
        LineChartDataRenderer *lineData = [[LineChartDataRenderer alloc] init];
        lineData.lineColor = [self.dataSource lineGraph:self lineColor:i];
        lineData.lineWidth = [self.dataSource lineGraph:self lineWidth:i];
        lineData.graphName = [self.dataSource lineGraph:self lineName:i];
        lineData.fillGraph = [self.dataSource lineGraph:self shouldFill:i];
        lineData.drawPoints = [self.dataSource lineGraph:self shouldDrawPoints:i];
        if (filterYOutOfRange) {
            NSArray *unfilteredYAxisArray = [self.dataSource lineGraph:self yAxisData:i];
            NSMutableArray *filteredYAxisArray = [NSMutableArray new];
            NSMutableArray *tempFilteredIndexArray = [NSMutableArray new];//筛选后的在原始array里的index
            for (int i = 0; i < unfilteredYAxisArray.count; ++i) {
                NSNumber *n = unfilteredYAxisArray[i];
                if (n.doubleValue - customMinValidY > 0.000001 && customMaxValidY - n.doubleValue > 0.000001) {
                    [filteredYAxisArray addObject:n];
                    [tempFilteredIndexArray addObject:@(i)];//警告⚠️：最后赋值给filteredIndexArray时没有考虑多条曲线的情况
                }
            }
            filteredIndexArray = tempFilteredIndexArray;
            lineData.yAxisArray = filteredYAxisArray;
        }
        else{
            lineData.yAxisArray = [self.dataSource lineGraph:self yAxisData:i];
        }
        [self.lineDataArray addObject:lineData];
        
        LegendDataRenderer *data = [[LegendDataRenderer alloc] init];
        [data setLegendText:lineData.graphName];
        [data setLegendColor:lineData.lineColor];
        [self.legendArray addObject:data];
    }
    
    self.xAxisArray = [self.dataSource lineGraphXAxisData:self filtered:filteredIndexArray];
}

#pragma mark Draw Graph: createXAxisLine, createYAxisLine, createGraph
- (void)drawGraph{
    /*
     ****** TODO ******
     目前只支持一条曲线，self.lineDataArray中多曲线(LineChartDataRenderer *)的支持未完善。
     */
    
    [self setupDataWithDataSource];
    
    CGFloat graphScrollHeight = self.frame.size.height;
    if (self.showLegend) {
        graphScrollHeight -= [LegendView getLegendHeightWithLegendArray:self.legendArray legendType:self.legendViewType withFont:self.textFont width:self.frame.size.width - 2 * LegendViewMarginH];
    }
    /*
     ******界面布局******
     y轴和y轴刻度值在self上，覆盖在graphScrollView上面，这样在graphScrollView左右滑动时y轴刻度值仍会显示
     x轴和x轴刻度值、曲线在graphScrollView上，随graphScrollView左右滑动。
     x轴和y轴的刻度值都是label中点对准刻度线。
     原点的
     x刻度值xAxisLabel显示在y轴的正下方，也即xAxisLabel中心和y轴对齐。当x轴刻度值label左滑超过y轴，且超过label一半长度后，继续左滑逐渐变透明，也即xAxisLabel.alpha = xAxisLabel在y轴右边的长度/xAxisLabel半长。
     y刻度值显示在x轴的正左方，也即文字中点和x轴对齐，因此x轴下方余出graphMarginV再显示x刻度值。
     由于x轴刻度值左滑过y轴才会逐渐透明，因此self、graphView、graphScrollView宽度一样，但在self左部覆盖一个柱形yAxisView遮住graphScrollView左小半部。
     
     ******view排列关系******
     self水平方向：
     self(yAxisView(宽度graphMarginL，显示y轴和y轴刻度值),
     graphScrollView(左小半部graphMarginL范围被yAxisView覆盖)
     )
     self竖直方向：
     graphScrollView
     LegendView
     
     如果y比y轴最大的刻度值还大，则y轴往上延伸一段表示无穷大，超大的数据点用空心而不是实心
     
     graphView占满graphScrollView，曲线点少则x相邻刻度值长度拉长，以保证graphView长度==graphScrollView长度；曲线点多则超过graphScrollView长度，需要左右滑动。graphScrollView.contentSize = graphView.frame.size
     水平方向：
     左边空白 graphMarginL
     曲线和各刻度线表格
     右边空白 graphMarginR
     竖直方向：
     空白 graphMarginV
     曲线和各刻度线表格
     x轴
     空白 graphMarginV
     x轴刻度值 heightXAxisLabel
     */
    self.graphScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, graphScrollHeight)];
    self.graphScrollView.showsVerticalScrollIndicator = NO;
    self.graphScrollView.showsHorizontalScrollIndicator = NO;
    self.graphScrollView.bounces = NO;
    self.graphScrollView.delegate = self;
    [self addSubview:self.graphScrollView];
    
    //如果手势被TapGesture、LongPressGesture成功识别，或者增加了PanGesture（无论是否成功识别），不会触发scrollViewDidScroll，即使 shouldRecognizeSimultaneouslyWithGestureRecognizer:返回YES也不行
    [self.graphScrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapPanLongPress:)]];
    if (enablePanAndLongPress) {
        [self.graphScrollView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapPanLongPress:)]];
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapPanLongPress:)];
        //如果minimumPressDuration设置过小，则TapGesture也会被认为是LongPressGesture
        //    longPressGestureRecognizer.minimumPressDuration = 0.3;
        [self.graphScrollView addGestureRecognizer:longPressGestureRecognizer];
    }
    
    self.graphView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, graphScrollHeight)];
    self.graphView.userInteractionEnabled = YES;
    [self.graphScrollView addSubview:self.graphView];
    
    self.yAxisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, graphMarginL, graphScrollHeight - heightXAxisLabel)];
    self.yAxisView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.yAxisView];
    
    [self createXAxisLine];//设置x坐标和grid竖线，同时设置graphView的宽度。在yAxisView上显示y轴
    self.graphScrollView.contentSize = self.graphView.frame.size;
    //注意，如果self是navigationcontroller的第一个view，graphScrollView.contentInset.top自动设为64，需要设置viewController.automaticallyAdjustsScrollViewInsets = NO;
    [self createYAxisLine];//设置y坐标和grid横线。在yAxisView上显示y轴刻度值
    self.originalPoint = CGPointMake([self xPositionOfAxis:0], ((NSNumber *)positionYOfYAxisValues.firstObject).floatValue);
    
    //如果 pointRadius > lineWidth，则当 positionStepX 在(5, 10)之间时，pointRadius的大小按照 positionStepX与5的距离 成比例缩小，但最小不能小于lineWidth
    CGFloat lineWidth = [self.dataSource lineGraph:self lineWidth:0];
    if (pointRadius > lineWidth) {
        if (5 < positionStepX && positionStepX < 10) {
            pointRadius = (lineWidth - pointRadius) / 5 * (positionStepX - 5);
        }
        else if(positionStepX <= 5){
            pointRadius = lineWidth;
        }
    }
    
    [self createGraph];//必须在self.originalPoint之后再createGraph，因为需要用它来fill曲线下方的区域
    
    if (self.showMarker) {
        [self createMarker];
    }
    if (self.showLegend) {
        [self createLegend];
    }
}

- (void)createXAxisLine{
    if (self.xAxisArray.count == 0) {
        return;//无x数据
    }
    
    void(^createXAxisLabel)(NSString *, CGFloat, CGFloat) = ^(NSString *s, CGFloat centerX, CGFloat top){
        NSAttributedString *attrString = [LegendView getAttributedString:s withFont:self.textFont];
        CGSize textSize = [attrString boundingRectWithSize:CGSizeMake(MAXFLOAT, heightXAxisLabel) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(centerX - textSize.width/2, top, textSize.width, textSize.height)];
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.7;
        l.attributedText = attrString;
        l.textColor = self.textColor;
        [self.graphView addSubview:l];
        [self.xAxisLabels addObject:l];
    };
    
    //划线的最高点和最低点的y
    const CGFloat positionYTop = graphMarginV;
    const CGFloat positionYBottom = self.graphView.frame.size.height - graphMarginV - heightXAxisLabel;
    CGFloat x = graphMarginL;
    const CGFloat yOfXAxisLabel = positionYBottom + graphMarginV;
    
    //在yAxisView上显示y轴
    [self.yAxisView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];;
    
    //在graphView上显示原点的x轴刻度值
    createXAxisLabel(self.xAxisArray[0], x, yOfXAxisLabel);
    
    if (self.xAxisArray.count == 1) {
        //只有一个点也显示x轴
        positionStepX = [self visibleWidthExcludeMargin];
        x += positionStepX;
    }
    else{
        CGFloat everagePStepX = [self visibleWidthExcludeMargin] / (self.xAxisArray.count - 1);
        if (enablePanAndLongPress) {
            positionStepX = everagePStepX;
        }
        else{
            positionStepX = MAX(minPositionStepX, everagePStepX);//保持相邻点的x方向距离>=minPositionStepX，同时尽量占满显示区域
        }
        
        int numberOfLabelsBetweenVisibleX = ceil(spaceBetweenVisibleXLabels / positionStepX);//相邻可见的x轴刻度值之间的总共刻度值数目（包括可见和不可见的）
        //显示原点外的竖直刻度线和x轴刻度值。不显示@""的刻度，只显示非空的刻度，因此两个刻度之间可能包含多个曲线点
        for (int i = 1; i < self.xAxisArray.count; ++i) {
            x += positionStepX;
            //每numberOfLabelsBetweenVisibleX个刻度值显示一个，如果显示完i处的刻度值后，余下的点数<要求点数的0.7倍，则不显示i处的刻度值
            //最后一个刻度值总是显示
            if ((i % numberOfLabelsBetweenVisibleX == 0 && self.xAxisArray.count - i > numberOfLabelsBetweenVisibleX * 0.7)
                || i == self.xAxisArray.count - 1) {
                if (self.drawGridX) {
                    //在graphView上显示其它竖线
                    [self.graphView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];
                }
                //显示x轴刻度值
                createXAxisLabel(self.xAxisArray[i], x, yOfXAxisLabel);
            }
        }
    }
    
    //NSLog(@"x轴positionStepX[%f], 坐标：%@", positionStepX, self.xAxisArray);
    CGRect graphViewFrame = graphView.frame;
    graphViewFrame.size.width = x + graphMarginR;
    graphView.frame = graphViewFrame;
}

- (void)createYAxisLine{
    double minY = MAXFLOAT;
    double maxY = -MAXFLOAT;
    NSMutableSet *allPointsSet = [[NSMutableSet alloc] init];//所有曲线中不同的y值。注意[NSNumber numberWithFloat:]和[NSNumber numberWithDouble:]不同
    NSMutableArray *allPointsYOfLines = [NSMutableArray new];//所有曲线的所有点的y值，包括y相同的值
    for (LineChartDataRenderer *lineData in self.lineDataArray) {
        [allPointsSet addObjectsFromArray:lineData.yAxisArray];
        for (NSNumber *n in lineData.yAxisArray) {
            [allPointsYOfLines addObject:n];
            if (n.doubleValue > maxY) {
                maxY = n.doubleValue;
            }
            if (n.doubleValue < minY) {
                minY = n.doubleValue;
            }
        }
    }
    if (allPointsSet.count == 0) {
        return;//所有的lineDataArray.yAxisArray都没有点
    }
    
    void(^createYAxisLabel)(NSString *, CGFloat, CGFloat) = ^(NSString *s, CGFloat right, CGFloat centerY){
        NSAttributedString *attrString = [LegendView getAttributedString:s withFont:self.textFont];
        CGSize textSize = [attrString boundingRectWithSize:CGSizeMake(graphMarginL, MAXFLOAT) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(right - textSize.width, centerY - textSize.height / 2, textSize.width, textSize.height)];
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.7;
        l.attributedText = attrString;
        l.textColor = self.textColor;
        [self.yAxisView addSubview:l];//在yAxisView上显示y刻度值
    };
    
    //画横线的区域，最高点和最低点的y
    const CGFloat positionYTop = graphMarginV;
    const CGFloat positionYBottom = self.graphView.frame.size.height - graphMarginV - heightXAxisLabel;
    
    //是否应该显示最高横线、x轴的y刻度值。如果最高/最低的2根横线之间的刻度值和距离同其他横线按比例计算，则显示刻度值，否则不显示
    BOOL shouldShowMaxYLabel = YES;
    BOOL shouldShowMinYLabel = YES;
    
    if (allPointsSet.count <= 2) {//包含了所有点的y值相等，也即minY == maxY的情况
        /*所有曲线的点y值相等或只有2种值，则除x轴外再画2个横线，最大的点在中间的横线上，另一个点在x轴上（若y值都相同则也在中间横线上），最高的横线上没有点
         如果只有一种y值，则valueStepY设为该y值绝对值的一半，否则设为最大值和最小值的差
         如果valueStepY为0，则改为1
         注意：考虑到minY和maxY对应的yFloor和yCeil都会取整，取整后曲线上的点不一定在x轴或中间横线上
         */
        double yFloor = FloorWithDigits(minY);
        double yCeil = CeilWithDigits(maxY);
        double valueStepY = CeilWithDigits(yFloor == yCeil ? fabs(yCeil / 2) : yCeil - yFloor);//需要用绝对值，防止minY和maxY都为负数
        if (valueStepY == 0) {
            valueStepY = 1;
        }
        
        [yAxisValues addObject:@(yCeil - valueStepY)];//原点的y轴刻度值
        [yAxisValues addObject:@(yCeil)];//中间横线的y轴刻度值
        [yAxisValues addObject:@(yCeil + valueStepY)];//最高横线的y轴刻度值
        
        positionStepY = (positionYBottom - positionYTop) / 2;
        [positionYOfYAxisValues addObject:@(positionYBottom)];//x轴的位置
        [positionYOfYAxisValues addObject:@(positionYBottom - positionStepY)];
        [positionYOfYAxisValues addObject:@(positionYTop)];//最高横线位置
    }
    else{
        const double validYRange = customMaxValidY - customMinValidY + 0.000001;//比较两个double值是否相等，需要将差值和一个很小数比较
        
        /*
         如果有曲线>=3个点，可能某个点距其它2个点特别远，导致曲线不好看，需要检查最大最小值的差距是否 > validYRange
         先将yCeil和yFloor分别设为范围内的最大值maxY和最小值minY
         如果超过范围，选取满足 yCeil-yFloor>=validRange && 范围内包含80%以上的点、差值最小的yCeil和yFloor，其中yCeil和yFloor必然是2个不同点的y值（因为包含了80%以上的点）
         
         [yFloor, yCeil]为最终计算决定的y轴合理刻度值范围（yFloor和yCeil已经分别按精度fractionDigits向下、向上取整）。如果范围外有更大值，则在yCeil对应的横线上面再显示一根横线；如果范围外有更小值，则x轴对应的y刻度为最小值，yFloor为x轴上方的横线刻度值。
         _________yCeil
         _________ or yCeil（范围外有更大值）
         _________
         _________yFloor
         _________ or yFloor（范围外有更小值）
         */
        double yCeil = maxY;
        double yFloor = minY;
        if (maxY - minY > validYRange){
            //注意，最后满足条件时可能出现yCeil == maxY && yFloor == minY，比如只有三个y值
            [allPointsYOfLines sortWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
                return [obj1 compare:obj2];//所有点y值升序排列
            }];
            const int requiredNumber = ceil(allPointsYOfLines.count * 0.8);//最少要包含80%的点
            double currentMetRange = MAXFLOAT;//当前满足条件的yCeil-yFloor的范围差
            for (int i = 0; i <= allPointsYOfLines.count - requiredNumber; ++i) {
                double yAtIndexI = ((NSNumber *)allPointsYOfLines[i]).doubleValue;
                int j = i + requiredNumber - 1;
                for (; j < allPointsYOfLines.count; ++j) {
                    double rangeBetweenIJ = ((NSNumber *)allPointsYOfLines[j]).doubleValue - yAtIndexI;
                    if (rangeBetweenIJ >= validYRange) {
                        if (rangeBetweenIJ < currentMetRange) {
                            currentMetRange = rangeBetweenIJ;
                            yFloor = yAtIndexI;
                            yCeil = ((NSNumber *)allPointsYOfLines[j]).doubleValue;
                        }
                        break;
                    }
                }
            }
        }
        
        /*根据 yCeil跟maxY、yFloor跟minY 是否相等来计算positionStepY、y轴刻度值yAxisValues、刻度值在view中的y坐标positionYOfYAxisValues。
         其中yFloor需要向下取整到精度为fractionDigits的小数，valueStepY向上取整，yCeil根据新的yFloor和valueStep计算并向上取整。
         */
        
        if (yCeil == maxY && yFloor == minY) {
            yFloor = FloorWithDigits(yFloor);
            double valueStepY = CeilWithDigits((CeilWithDigits(yCeil) - yFloor) / segmentsOfYAxis);
            
            //x轴及全部横线的 位置、y轴刻度值
            positionStepY = (positionYBottom - positionYTop) / segmentsOfYAxis;
            for (int i = 0; i <= segmentsOfYAxis; ++i) {
                [yAxisValues addObject:@(yFloor + valueStepY * i)];
                [positionYOfYAxisValues addObject:@(positionYBottom - positionStepY * i)];
            }
        }
        else{//计算[yFloor, yCeil]两端的y刻度值和相邻刻度线长度
            //yFloor跟minY、yCeil跟maxY 不全相等，因此最低或最高两根横线的距离 <> 其他相邻横线通常距离positionStepY，受view高度限制规定最多为positionStepY的1.5倍，为了好看又限制>=positionStepY。
            const double maxMultipleMoreThanPositionStepY = 0.5;//最低或最高两根横线的距离比positionStepY多的最大倍数，多0.5倍也就是等于1.5倍
            if (yFloor == minY) {//x轴y刻度值为minY
                yFloor = FloorWithDigits(yFloor);
                double valueStepY = CeilWithDigits((CeilWithDigits(yCeil) - yFloor) / (segmentsOfYAxis - 1));
                yCeil = yFloor + valueStepY * (segmentsOfYAxis - 1);
                
                /*
                 原则：最高2横线的距离比通常距离大 0至maxMultipleMoreThanPositionStepY倍。(maxY - yCeil) / valueStepY <= 1.5倍时，最高横线的y刻度值和高度（1至1.5倍通常高度）成正比；大于等于1.5倍时，最高横线的y刻度值(为超大数)和高度（仍限定为1.5倍通常高度）不按比例，具体逻辑：
                 1. 如果maxY - yCeil <= valueStepY，则最高横线的y刻度值 设为 次高横线刻度值yCeil+valueStepY，最高2横线间距离同positionStepY，也即最高横线位置为positionYTop
                 2. 否则
                 2.1 如果maxY - yCeil > valueStepY 且 (maxY - yCeil - valueStepY) / valueStepY < maxMultipleMoreThanPositionStepY，则最高横线的刻度值设为maxY，最高2横线间的距离设为 positionStepY * (1 + 实际多的倍数)，根据positionStepY的计算方法可知最高横线位置恰好为positionYTop
                 2.2 否则，最高横线的刻度值设为maxY，最高横线间的距离设为 positionStepY * (1 + maxMultipleMoreThanPositionStepY)，也即最高横线位置为positionYTop
                 */
                double valueOfYTop;//最高横线的y刻度值
                if (maxY - yCeil <= valueStepY) {//yCeil对应横线上方positionStepY处再加一横线
                    positionStepY = (positionYBottom - positionYTop) / segmentsOfYAxis;
                    valueOfYTop = yCeil + valueStepY;//>= maxY
                }
                else{
                    if ((maxY - yCeil - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {//yCeil对应横线跟上方横线的距离按比例计算
                        positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + (maxY - yCeil - valueStepY) / valueStepY);
                    }
                    else{//最高2横线的实际距离设为positionStepY的(1 + maxMultipleMoreThanPositionStepY)倍
                        shouldShowMaxYLabel = NO;
                        positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + maxMultipleMoreThanPositionStepY);
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
                yFloor = FloorWithDigits(yFloor);
                double valueStepY = CeilWithDigits((CeilWithDigits(yCeil) - yFloor) / (segmentsOfYAxis - 1));
                yCeil = yFloor + valueStepY * (segmentsOfYAxis - 1);
                
                /*
                 原则：最低2横线的距离比通常距离大 0至maxMultipleMoreThanPositionStepY倍。(yFloor - minY) / valueStepY <= 1.5倍时，x轴的y刻度值和高度（1至1.5倍通常高度）成正比；大于等于1.5倍时，x轴的y刻度值(为超小数)和高度（仍限定为1.5倍通常高度）不按比例，具体逻辑：
                 原则：最低2横线的高度是其他横线高度的1-1.5倍，小于1.5倍时y刻度值和高度成正比，大于等于1.5倍时y刻度值(超小数)和高度不按比例，具体逻辑：
                 1. 如果yFloor - minY <= valueStepY，则x轴的y刻度值 设为 次低横线刻度值yFloor-valueStepY，最低2横线间距离同positionStepY，也即x轴为positionYBottom
                 2. 否则
                 2.1 如果yFloor - minY > valueStepY 且 (yFloor - minY - valueStepY) / valueStepY < maxMultipleMoreThanPositionStepY，则x轴横线的刻度值设为minY，最低2横线间的距离设为 positionStepY * (1 + 实际多的倍数)，根据positionStepY的计算方法可知x轴位置恰好为positionYBottom
                 2.2 否则，x轴的刻度值设为minY，最低横线间的距离设为 positionStepY * (1 + maxMultipleMoreThanPositionStepY)，也即x轴位置为positionYBottom
                 */
                double valueOfYBottom;//最低横线（x轴）的y刻度值
                if (yFloor - minY <= valueStepY) {//yFloor对应横线在x轴上方positionStepY处
                    positionStepY = (positionYBottom - positionYTop) / segmentsOfYAxis;
                    valueOfYBottom = yFloor-valueStepY;
                }
                else{
                    if ((yFloor - minY - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {//yFloor对应横线跟x轴的距离按比例计算
                        positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + (yFloor - minY - valueStepY) / valueStepY);
                    }
                    else{//x轴同上面横线的实际距离设为positionStepY的(1 + maxMultipleMoreThanPositionStepY)倍
                        shouldShowMinYLabel = NO;
                        positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + maxMultipleMoreThanPositionStepY);
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
                yFloor = FloorWithDigits(yFloor);
                double valueStepY = CeilWithDigits((CeilWithDigits(yCeil) - yFloor) / (segmentsOfYAxis - 2));
                yCeil = yFloor + valueStepY * (segmentsOfYAxis - 2);
                
                double valueOfYTop;
                double valueOfYBottom;
                
                double actualMultipleMoreThan_top;
                double actualMultipleMoreThan_bottom;
                if (maxY - yCeil <= valueStepY) {
                    actualMultipleMoreThan_top = 0;
                    valueOfYTop = yCeil + valueStepY;
                }
                else{
                    if ((maxY - yCeil - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {
                        actualMultipleMoreThan_top = (maxY - yCeil - valueStepY) / valueStepY;
                    }
                    else{
                        shouldShowMaxYLabel = NO;
                        actualMultipleMoreThan_top = maxMultipleMoreThanPositionStepY;
                    }
                    valueOfYTop = maxY;
                }
                
                if (yFloor - minY <= valueStepY) {
                    actualMultipleMoreThan_bottom = 0;
                    valueOfYBottom = yFloor - valueStepY;
                }
                else{
                    if ((yFloor - minY - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {
                        actualMultipleMoreThan_bottom = (yFloor - minY - valueStepY) / valueStepY;
                    }
                    else{
                        shouldShowMinYLabel = NO;
                        actualMultipleMoreThan_bottom = maxMultipleMoreThanPositionStepY;
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
    //NSLog(@"所有点的y轴坐标：%@", allPointsYOfLines);
    //NSLog(@"y轴minY %f, yFloor %f, maxY %f, yCeil %f", minY, yFloor, maxY, yCeil);
    //NSLog(@"y轴坐标刻度值%zi个，%@", yAxisValues.count, yAxisValues);
    //NSLog(@"y轴坐标:%@", positionYOfYAxisValues);
    
    const CGFloat lineStartX = graphMarginL;//等于yAxisView的右边缘位置
    const CGFloat lineEndX = self.graphView.frame.size.width - graphMarginR;
    
    //显示x轴、原点的y轴刻度值
    [self.graphView.layer addSublayer:[self gridLineLayerStart:CGPointMake(lineStartX, positionYBottom) end:CGPointMake(lineEndX, positionYBottom)]];
    if (shouldShowMinYLabel) {
        createYAxisLabel([self formattedStringForNumber:yAxisValues[0]], lineStartX, positionYBottom);
    }
    
    //显示除x轴外的横线、y轴刻度值
    for (int i =1; i < positionYOfYAxisValues.count; ++i) {
        CGFloat positionY = ((NSNumber *)positionYOfYAxisValues[i]).floatValue;
        if (self.drawGridY) {
            [self.graphView.layer addSublayer:[self gridLineLayerStart:CGPointMake(lineStartX, positionY) end:CGPointMake(lineEndX, positionY)]];
        }
        if (i < positionYOfYAxisValues.count - 1 || shouldShowMaxYLabel) {//非最高横线 或者 should显示最高横线刻度值
            createYAxisLabel([self formattedStringForNumber:yAxisValues[i]], lineStartX, positionY);
        }
    }
}

-(CGPoint)pointForLine:(LineChartDataRenderer *)lineData at:(NSUInteger)pointIndex{
    double yValue = [[lineData.yAxisArray objectAtIndex:pointIndex] doubleValue];
    for (int i = 0; i < yAxisValues.count; ++i){
        if (yValue - ((NSNumber *)yAxisValues[i]).doubleValue < 0.000001) {//double的比较需要比较差值和一个小数，比如-0.5999999995和-0.6000000001
            //刻度值是上面的大，view里点的y坐标是下面的大
            double yValueAbove = ((NSNumber *)yAxisValues[i]).doubleValue;//点上方的y轴刻度值
            CGFloat positionYAbove = ((NSNumber *)positionYOfYAxisValues[i]).floatValue;//点上方的y轴刻度值的位置
            if (i == 0) {
                return CGPointMake([self xPositionOfAxis:pointIndex], positionYAbove);
            }
            else{
                double yValueBellow = ((NSNumber *)yAxisValues[i - 1]).doubleValue;//点下方的y轴刻度值
                CGFloat positionYBellow = ((NSNumber *)positionYOfYAxisValues[i - 1]).floatValue;//点下方的y轴刻度值的位置
                return CGPointMake([self xPositionOfAxis:pointIndex], positionYBellow - (yValue - yValueBellow) / (yValueAbove - yValueBellow) * (positionYBellow - positionYAbove));
            }
        }
    }
    NSAssert2(NO, @"Invalid point at index %zi of lineData.yAxisArray %@", pointIndex, lineData.yAxisArray);
    return CGPointZero;
}

- (void)createGraph{
    for (LineChartDataRenderer *lineData in self.lineDataArray) {
        if (lineData.yAxisArray.count == 0) {//没有点
            continue;
        }
        
        CGPoint startPoint = [self pointForLine:lineData at:0];
        if (lineData.drawPoints) {
            [self drawPointsOnLine:startPoint withColor:lineData.lineColor];
        }
        
        if (lineData.yAxisArray.count == 1) {
            //只有一个点，画完这个点就结束，因为画path需要至少2个点
            continue;
        }
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        UIBezierPath *fillPath = [UIBezierPath bezierPath];
        [fillPath moveToPoint:startPoint];
        
        for (int i = 1; i < lineData.yAxisArray.count; ++i) {
            CGPoint nextPoint = [self pointForLine:lineData at:i];
            
            [path appendPath:[self pathFrom:startPoint to:nextPoint]];
            [fillPath addLineToPoint:nextPoint];
            if (lineData.drawPoints) {
                [self drawPointsOnLine:nextPoint withColor:lineData.lineColor];
            }
            startPoint = nextPoint;
        }
        
        [path closePath];
        
        CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
        [shapeLayer setPath:[path CGPath]];
        [shapeLayer setStrokeColor:lineData.lineColor.CGColor];
        [shapeLayer setLineWidth:lineData.lineWidth];
        shapeLayer.shouldRasterize = YES;
        shapeLayer.rasterizationScale = [UIScreen mainScreen].scale;
        shapeLayer.contentsScale = [UIScreen mainScreen].scale;
        
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        [pathAnimation setDuration:self.animationDuration];
        [pathAnimation setFromValue:[NSNumber numberWithFloat:0.0f]];
        [pathAnimation setToValue:[NSNumber numberWithFloat:1.0f]];
        [shapeLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
        
        [self.graphView.layer addSublayer:shapeLayer];
        
        if (lineData.fillGraph) {
            [fillPath addLineToPoint:CGPointMake(startPoint.x, self.originalPoint.y)];
            [fillPath addLineToPoint:self.originalPoint];//坐标原点的位置
            [fillPath addLineToPoint:[self pointForLine:lineData at:0]];
            [fillPath closePath];
            
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
    self.legendView = [[LegendView alloc] initWithFrame:CGRectMake(LegendViewMarginH, CGRectGetMaxY(self.graphView.frame), self.frame.size.width - 2*LegendViewMarginH, 0)];
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
        CGFloat comparedX = graphScrollView.contentOffset.x + graphMarginL;//坐标系原点距离左边缘 graphMarginL
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
-(void)handleTapPanLongPress:(UITapGestureRecognizer *)gesture{
    if (self.showMarker || self.showCustomMarkerView) {
        CGPoint currentPoint = [gesture locationInView:self.graphView];
        if (CGRectContainsPoint(self.graphView.frame, currentPoint)) {
            //TapGesture 取曲线上直线距离最小的点，并检查距离是否过大，过大则不显示十字线信息；
            //而PanGesture和LongPressGesture 只取曲线x方向距离最近的点即可，不需检查距离是否过大。这样可以保证在拖拽时，曲线上的点依次显示十字线信息。
            [self showMakerNearPoint:currentPoint checkXDistanceOnly:![gesture isMemberOfClass:[UITapGestureRecognizer class]]];
        }
    }
}

- (void)dismissMarker{
    [super dismissMarker];
}

/**
 *  在距离 点击或拖拽的点 最近的曲线点显示十字线和弹出框
 *
 *  @param pointTouched       点击或拖拽到的点
 *  @param checkXDistanceOnly YES 则选取曲线上跟 pointTouched x轴方向距离最近的点即可；NO 则比较 曲线上点跟 pointTouched 的最短距离是否足够小
 */
- (BOOL)showMakerNearPoint:(CGPoint)pointTouched checkXDistanceOnly:(BOOL)checkXDistanceOnly{
    [super showMakerNearPoint:pointTouched checkXDistanceOnly:checkXDistanceOnly];
    
    NSInteger lineNumber = -1;//点击的是第几根线的点
    NSString *xString;
    NSNumber *yNumber;
    NSString *yString;//string presentation of yNumber
    CGFloat minDistance = MAXFLOAT;
    CGPoint closestPoint;//距离最近的点
    NSUInteger closestPointIndex = 0;
    
    for (int lIndex = 0; lIndex < self.lineDataArray.count; ++lIndex) {
        LineChartDataRenderer *lineData = self.lineDataArray[lIndex];
        for (int i = 0; i < lineData.yAxisArray.count; ++i){
            CGPoint point = [self pointForLine:lineData at:i];
            CGFloat distance = checkXDistanceOnly ? fabs(pointTouched.x - point.x) : sqrtf(powf(pointTouched.x - point.x, 2) + powf(pointTouched.y - point.y, 2));
            if (distance < minDistance) {
                minDistance = distance;
                closestPoint = point;
                closestPointIndex = i;
                xString = [self.xAxisArray objectAtIndex:i];
                yNumber = [lineData.yAxisArray objectAtIndex:i];
                yString = [self formattedStringForNumber:yNumber];
                lineNumber = lIndex;
            }
        }
    }
    
    [self hideMarker];
    
    //距离过远的点不处理
    if (!checkXDistanceOnly && minDistance > (positionStepX + positionStepY) * 0.8) {
        //不能简单比较 positionStepX / 2，如果x轴刻度很密集则该限制过紧，如果只有一个点则为0，所以需要综合positionStepX + positionStepY考虑
        return NO;
    }
    
    CGPoint contentOffset = graphScrollView.contentOffset;
    if (closestPoint.x - (closestPoint.x == self.originalPoint.x ? 0 : pointRadius) < self.originalPoint.x + contentOffset.x) {
        if (closestPoint.x == self.originalPoint.x){
        }
        //closestPoint左边缘在y轴左侧，需要将graphScrollView向右滑动使其完全显示出来，但是第一个点只显示一半
        CGFloat needScroll = (self.originalPoint.x + contentOffset.x) - (closestPoint.x - (closestPoint.x == self.originalPoint.x ? 0 : pointRadius));
        contentOffset.x -= needScroll;
        [UIView animateWithDuration:0.2 animations:^{
            self.graphScrollView.contentOffset = contentOffset;
        }];
    }
    else if(closestPoint.x + (closestPoint.x == self.originalPoint.x ? 0 : pointRadius) > contentOffset.x + graphScrollView.frame.size.width){
        //closestPoint在屏幕外右边，右边缘没有显示出来，需要将graphScrollView向左滑动使其完全显示出来
        CGFloat needScroll = (closestPoint.x + pointRadius) - (contentOffset.x + graphScrollView.frame.size.width);
        contentOffset.x += needScroll;
        [UIView animateWithDuration:0.2 animations:^{
            self.graphScrollView.contentOffset = contentOffset;
        }];
    }
    
    closestPoint = [self optimizedPoint:closestPoint];
    
    [self.xMarker setPath:[[self pathFrom:CGPointMake(closestPoint.x, ((NSNumber *)positionYOfYAxisValues.firstObject).floatValue) to:CGPointMake(closestPoint.x, ((NSNumber *)positionYOfYAxisValues.lastObject).floatValue)] CGPath]];
    [self.xMarker setHidden:NO];
    
    [self.yMarker setPath:[[self pathFrom:CGPointMake(self.originalPoint.x, closestPoint.y) to:CGPointMake([self xPositionOfAxis:xAxisArray.count <= 1 ? 1 : xAxisArray.count - 1], closestPoint.y)] CGPath]];
    [self.yMarker setHidden:NO];
    
    if (self.showCustomMarkerView){
        [self.marker setHidden:YES];
        [self.marker removeFromSuperview];
        self.customMarkerView = [self.dataSource lineGraph:self customViewForLine:lineNumber pointIndex:(filterYOutOfRange ? ((NSNumber *)filteredIndexArray[closestPointIndex]).intValue : closestPointIndex) andYValue:yNumber];
        
        if (self.customMarkerView != nil) {
            CGSize viewSize = self.customMarkerView.frame.size;
            CGRect pathFrame = self.graphView.frame;
            pathFrame.origin.x += graphMarginL;
            pathFrame.size.width -= graphMarginL + graphMarginR;
            pathFrame.origin.y += graphMarginV;
            pathFrame.size.height -= graphMarginV * 2;//graphView中曲线区域的rect，去掉四周的空白
            
            //makerView优先显示在selectedPoint的左下角，如果显示不开则显示在右方或上方
            CGPoint makerViewOrigin = CGPointZero;
            if (CGRectGetMaxY(pathFrame) - closestPoint.y >= viewSize.height) {
                makerViewOrigin.y = closestPoint.y;
            }
            else{
                makerViewOrigin.y = closestPoint.y - viewSize.height;
            }
            if (closestPoint.x - pathFrame.origin.x >= viewSize.width
                && closestPoint.x - viewSize.width >= self.originalPoint.x + graphScrollView.contentOffset.x) {
                //如果pathFrame中closestPoint左边空间足够 && graphScrollView当前滚动后的显示区域仍然足够
                makerViewOrigin.x = closestPoint.x - viewSize.width;
            }
            else{
                makerViewOrigin.x = closestPoint.x;
            }
            
            self.customMarkerView.frame = CGRectMake(makerViewOrigin.x, makerViewOrigin.y, viewSize.width, viewSize.height);
            [self.graphView addSubview:self.customMarkerView];
        }
        [self.graphScrollView addSubview:self.customMarkerView];
    }
    else if (self.showMarker) {
        [self.marker setXString:xString];
        [self.marker setYString:yString];
        [self.marker drawAtPoint:CGPointMake(closestPoint.x, graphMarginV)];
        [self.marker setHidden:NO];
    }
    
    [self setNeedsDisplay];
    
    if ([self.delegate respondsToSelector:@selector(lineGraph:didTapLine:atPoint:valuesAtY:)]) {
        [self.delegate lineGraph:self didTapLine:lineNumber atPoint:(filterYOutOfRange ? ((NSNumber *)filteredIndexArray[closestPointIndex]).intValue : closestPointIndex) valuesAtY:yNumber];
    }
    return YES;
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
    [pathAnimation setDuration:self.animationDuration];
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
    [shapeLayer setPath:[[self pathFrom:startPoint to:endPoint] CGPath]];
    [shapeLayer setStrokeColor:self.gridLineColor.CGColor];
    [shapeLayer setLineWidth:self.gridLineWidth];
    return shapeLayer;
}

- (UIBezierPath *)pathFrom:(CGPoint)startPoint to:(CGPoint)endPoint{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:[self optimizedPoint:startPoint]];
    [path addLineToPoint:[self optimizedPoint:endPoint]];
    
    [path closePath];
    
    return path;
}

- (void)drawPointsOnLine:(CGPoint)point withColor:(UIColor *)color{
    UIBezierPath *pointPath = [UIBezierPath bezierPath];
    [pointPath addArcWithCenter:[self optimizedPoint:point] radius:pointRadius startAngle:0 endAngle:2 * M_PI clockwise:YES];
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    [shapeLayer setPath:pointPath.CGPath];
    [shapeLayer setStrokeColor:color.CGColor];//如果StrokeColor和FillColor不同，则画出的是环
    [shapeLayer setFillColor:color.CGColor];
    [shapeLayer setLineWidth:0];
    shapeLayer.shouldRasterize = YES;
    shapeLayer.rasterizationScale = [UIScreen mainScreen].scale;
    shapeLayer.contentsScale = [UIScreen mainScreen].scale;
    [self.graphView.layer addSublayer:shapeLayer];
}
@end
