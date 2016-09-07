//
//  SingleLineGraphBase.m
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "SingleLineGraphBase.h"
#import "LineGraphMarker.h"
#import "LineChartDataRenderer.h"

@interface SingleLineGraphBase()
//是否应该显示最高横线、x轴的y刻度值，通常显示。当最大y值或者最低y值不在范围内时，此时最高的或最低的2根横线之间的刻度值距离比同其他横线间的距离大，不显示其在y轴上的刻度值。
@property (assign, nonatomic) BOOL shouldShowMaxYLabel;
@property (assign, nonatomic) BOOL shouldShowMinYLabel;

//self(backgroundScrollView(x-axis, y-axis, graphBackgroundView 曲线图), defaultMarker or customMarkerView, legendView)
@property (nonatomic, strong) LineChartDataRenderer *lineDataRenderer;//曲线的数据结构
@property (nonatomic, strong) UIView *yAxisView;//固定的y轴和y刻度值

@property (strong, nonatomic) NSMutableArray *yAxisValues;//array of NSNumber，y轴从下到上的刻度值，firstObject和lastObject分别是数据点的y最小值和最大值，但是最小值和最大值如果差距太大则不会显示在y轴刻度上，其它元素之间的差值等于positionStepY。
@end

@implementation SingleLineGraphBase
@synthesize delegate;
@synthesize dataSource;
@synthesize textFont;
@synthesize textColor;
@synthesize lineColor;
@synthesize lineWidth;
@synthesize lineName;
@synthesize shouldFill;
@synthesize drawGridX;
@synthesize drawGridY;
@synthesize spaceBetweenVisibleXLabels;
@synthesize segmentsOfYAxis;
@synthesize customMaxValidY;
@synthesize customMinValidY;
@synthesize filterYOutOfRange;
@synthesize filteredIndexArray;

@synthesize shouldShowMaxYLabel;
@synthesize shouldShowMinYLabel;
@synthesize lineDataRenderer;
@synthesize yAxisView;
@synthesize yAxisValues;

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.textColor = [UIColor blackColor];
        self.textFont = [UIFont systemFontOfSize:12];
        
        lineColor = [UIColor blackColor];
        lineWidth = 0.5;
        lineName = @"";
        shouldFill = YES;
        
        self.drawGridY = YES;
        self.drawGridX = YES;
        
        self.showMarker = YES;
        self.markerColor = [UIColor orangeColor];
        self.markerTextColor = [UIColor whiteColor];
        self.markerWidth = 0.4;
        
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
    [self setupDataWithDataSource];
    [self drawGraph];
}

#pragma mark Setup all data with dataSource
- (void)setupDataWithDataSource{
    self.xAxisLabels = [[NSMutableArray alloc] init];
    yAxisValues = [[NSMutableArray alloc] init];
    self.positionYOfYAxisValues = [[NSMutableArray alloc] init];
    self.legendArray = [[NSMutableArray alloc] init];
    
    filteredIndexArray = nil;
    lineDataRenderer = [[LineChartDataRenderer alloc] init];
    lineDataRenderer.lineColor = self.lineColor;
    lineDataRenderer.lineWidth = self.lineWidth;
    lineDataRenderer.graphName = self.lineName;
    lineDataRenderer.fillGraph = self.shouldFill;
    lineDataRenderer.drawPoints = self.shouldDrawPoints;
    if (filterYOutOfRange) {
        NSArray *unfilteredYAxisArray = [self.dataSource yAxisDataForline:self];
        NSMutableArray *filteredYAxisArray = [NSMutableArray new];
        NSMutableArray *tempFilteredIndexArray = [NSMutableArray new];//筛选后的在原始array里的index
        for (int i = 0; i < unfilteredYAxisArray.count; ++i) {
            NSNumber *n = unfilteredYAxisArray[i];
            if (n.doubleValue - customMinValidY > 0.000001 && customMaxValidY - n.doubleValue > 0.000001) {
                [filteredYAxisArray addObject:n];
                [tempFilteredIndexArray addObject:@(i)];
            }
        }
        filteredIndexArray = tempFilteredIndexArray;
        lineDataRenderer.yAxisArray = filteredYAxisArray;
    }
    else{
        lineDataRenderer.yAxisArray = [self.dataSource yAxisDataForline:self];
    }
    
    LegendDataRenderer *data = [[LegendDataRenderer alloc] init];
    [data setLegendText:lineDataRenderer.graphName];
    [data setLegendColor:lineDataRenderer.lineColor];
    [self.legendArray addObject:data];
    
    self.xAxisArray = [self.dataSource xAxisDataForLine:self filtered:filteredIndexArray];
}

- (void)drawGraph{
    /*
     ******界面布局******
     y轴和y轴刻度值在yAxisView上，覆盖在backgroundScrollView上面，这样在backgroundScrollView左右滑动时y轴刻度值仍会显示
     x轴和x轴刻度值、曲线在backgroundScrollView上，随backgroundScrollView左右滑动。
     x轴和y轴的刻度值都是label中点对准刻度线。
     原点的
     x刻度值xAxisLabel显示在y轴的正下方，也即xAxisLabel中心和y轴对齐。当x轴刻度值label左滑超过y轴，且超过label一半长度后，继续左滑逐渐变透明，也即xAxisLabel.alpha = xAxisLabel在y轴右边的长度/xAxisLabel半长。
     y刻度值显示在x轴的正左方，也即文字中点和x轴对齐，因此x轴下方余出graphMarginV再显示x刻度值。
     由于x轴刻度值左滑过y轴才会逐渐透明，因此self、graphBackgroundView、backgroundScrollView宽度一样，但在self左部覆盖一个柱形yAxisView遮住backgroundScrollView左小半部。
     
     ******view排列关系******
     self水平方向：
     self(yAxisView(宽度graphMarginL，显示y轴和y轴刻度值),
     backgroundScrollView(左小半部graphMarginL范围被yAxisView覆盖)
     )
     self竖直方向：
     backgroundScrollView
     LegendView
     
     如果y比y轴最大的刻度值还大，则y轴往上延伸一段表示无穷大，超大的数据点用空心而不是实心
     
     graphBackgroundView占满backgroundScrollView，曲线点少则x相邻刻度值长度拉长，以保证graphBackgroundView长度==backgroundScrollView长度；曲线点多则超过backgroundScrollView长度，需要左右滑动。backgroundScrollView.contentSize = graphBackgroundView.frame.size
     水平方向：
     左边空白 graphMarginL
     曲线和各刻度线表格
     右边空白 graphMarginR
     竖直方向：
     空白 graphMarginV
     曲线和各刻度线表格
     x轴
     空白 graphMarginV（之所以x轴和刻度值之间留出空白，因为原点的x刻度值显示在正下方，y刻度值显示在正左方，y刻度值下面才显示x刻度值）
     x轴刻度值 heightXAxisLabel
     */
    
    //注意，如果self是navigationcontroller的第一个view，backgroundScrollView.contentInset.top自动设为64，需要设置viewController.automaticallyAdjustsScrollViewInsets = NO;
    
    [self calculatePositionStepX];
    [self calculatePointRadius];
    [self calculateYAxis];
    self.originalPoint = CGPointMake([self xPositionOfAxis:0], ((NSNumber *)self.positionYOfYAxisValues.firstObject).floatValue);
    
    [self createGraphBackground];
    [self drawXAxis];
    [self drawYAxis];//设置y坐标和grid横线。在yAxisView上显示y轴刻度值
    [self drawLines];
    
//    NSString *xString = @"X: ";
//    for (NSString *a in self.xAxisArray) {
//        xString = [NSString stringWithFormat:@"%@%@, ", xString, a];
//    }
//    NSLog(xString);
//    NSString *yString = @"Y: ";
//    for (NSString *a in self.lineDataRenderer.yAxisArray) {
//        yString = [NSString stringWithFormat:@"%@%@, ", yString, a];
//    }
//    NSLog(yString);
    
    [self createMarker];
    [self createLegend];
}

#pragma mark - 计算各种x轴和y轴的各种长度

-(void)calculatePointRadius{
    //如果 self.pointRadius > lineWidth，则当 positionStepX 在(widthThreshold=10倍lineWidth, 20倍lineWidth)之间时，self.pointRadius的大小按照 positionStepX与widthThreshold的距离 成比例缩小，但最小不能小于lineWidth
    self.pointRadius = self.maxPointRadius;
    if (self.pointRadius > lineWidth) {
        CGFloat widthThreshold = 10 * lineWidth;
        if (widthThreshold < self.positionStepX && self.positionStepX < widthThreshold * 2) {
            self.pointRadius = (self.pointRadius - lineWidth) * (self.positionStepX - widthThreshold) / widthThreshold + lineWidth;
        }
        else if(self.positionStepX <= widthThreshold){
            self.pointRadius = lineWidth;
        }
    }
}

/**
 *  计算yAxisValues、positionStepY、positionYOfYAxisValues
 */
- (void)calculateYAxis{
    //画横线的区域，最高点和最低点的y
    const CGFloat positionYTop = self.graphMarginV;
    const CGFloat positionYBottom = self.graphMarginV + [self heightYAxis];
    
    //通常显示最高点和最低点的y刻度值
    shouldShowMaxYLabel = YES;
    shouldShowMinYLabel = YES;
    
    NSSet *allPointsSet = [[NSSet alloc] initWithArray:lineDataRenderer.yAxisArray];//所有曲线中不同的y值。注意[NSNumber numberWithFloat:]和[NSNumber numberWithDouble:]不同
    if (allPointsSet.count == 0) {
        //没有点，positionStepY等于y轴高度，y轴刻度值为0和1
        [yAxisValues addObject:@0];//原点的y轴刻度值
        [yAxisValues addObject:@1];//最高横线的y轴刻度值
        
        self.positionStepY = (positionYBottom - positionYTop);
        [self.positionYOfYAxisValues addObject:@(positionYBottom)];//x轴的位置
        [self.positionYOfYAxisValues addObject:@(positionYTop)];//最高横线位置
        return;
    }
    
    NSMutableArray *allPointsYOfLines = [[NSMutableArray alloc] initWithArray:lineDataRenderer.yAxisArray];//所有曲线的所有点的y值，包括y相同的值
    [allPointsYOfLines sortWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj1 compare:obj2];//所有点y值升序排列
    }];
    double minY = ((NSNumber *)allPointsYOfLines.firstObject).doubleValue;
    double maxY = allPointsYOfLines.count > 1 ? ((NSNumber *)allPointsYOfLines.lastObject).doubleValue : minY;
    
    if (allPointsSet.count <= 2) {
        /*1个点或2个点（含minY == maxY的情况）
         则除x轴外再画2个横线，最大的点在中间的横线上，另一个点在x轴上（若y值相同则也在中间横线上），最高的横线上没有点
         如果只有一种y值，则valueStepY设为该y值绝对值的一半，否则设为最大值和最小值的差
         如果valueStepY为0，则改为1
         注意：考虑到minY和maxY对应的yFloor和yCeil都会取整，取整后曲线上的点不一定恰好在x轴或中间横线上
         */
        double yFloor = [self fractionFloorOrCeiling:minY ceiling:NO];
        double yCeil = [self fractionFloorOrCeiling:maxY ceiling:YES];
        double valueStepY = [self fractionFloorOrCeiling:(yFloor == yCeil ? fabs(yCeil / 2) : yCeil - yFloor) ceiling:YES];//需要用绝对值，防止minY和maxY都为负数
        if (valueStepY == 0) {
            valueStepY = 1;
        }
        
        [yAxisValues addObject:@(yCeil - valueStepY)];//原点的y轴刻度值
        [yAxisValues addObject:@(yCeil)];//中间横线的y轴刻度值
        [yAxisValues addObject:@(yCeil + valueStepY)];//最高横线的y轴刻度值
        
        self.positionStepY = (positionYBottom - positionYTop) / 2;
        [self.positionYOfYAxisValues addObject:@(positionYBottom)];//x轴的位置
        [self.positionYOfYAxisValues addObject:@(positionYBottom - self.positionStepY)];
        [self.positionYOfYAxisValues addObject:@(positionYTop)];//最高横线位置
    }
    else{
        const double validYRange = customMaxValidY - customMinValidY + 0.000001;//比较两个double值是否相等，需要将差值和一个很小数比较
        
        /*
         如果有曲线>=3个点，可能某个点距其它2个点特别远，导致曲线不好看，需要检查最大最小值的差距是否 > validYRange
         先将yCeil和yFloor分别设为范围内的最大值maxY和最小值minY
         如果超过范围，选取满足 yCeil-yFloor>=validYRange && 范围内包含80%以上的点、差值最小的yCeil和yFloor，其中yCeil和yFloor必然是2个不同点的y值（因为包含了80%以上的点）
         
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
            const int requiredNumber = ceil(allPointsYOfLines.count * 0.8);//最少要包含80%的点
            double currentMetRange = MAXFLOAT;//当前满足条件的yCeil-yFloor的范围差
            for (int i = 0; i <= allPointsYOfLines.count - requiredNumber; ++i) {
                double yAtIndexI = ((NSNumber *)allPointsYOfLines[i]).doubleValue;
                int j = i + requiredNumber - 1;
                for (; j < allPointsYOfLines.count; ++j) {
                    double yAtIndexJ = ((NSNumber *)allPointsYOfLines[j]).doubleValue;
                    double rangeBetweenIJ = yAtIndexJ - yAtIndexI;
                    if (rangeBetweenIJ >= validYRange) {
                        if (rangeBetweenIJ < currentMetRange) {
                            currentMetRange = rangeBetweenIJ;
                            yFloor = yAtIndexI;
                            yCeil = yAtIndexJ;
                        }
                        break;
                    }
                }
            }
        }
        
        /*根据 yCeil跟maxY、yFloor跟minY 是否相等来计算positionStepY、y轴刻度值yAxisValues、刻度值在view中的y坐标self.positionYOfYAxisValues。
         其中yFloor需要向下取整到精度为fractionDigits的小数，valueStepY向上取整，yCeil根据新的yFloor和valueStep计算并向上取整。
         */
        
        if (yCeil == maxY && yFloor == minY) {
            yFloor = [self fractionFloorOrCeiling:yFloor ceiling:NO];
            yCeil = [self fractionFloorOrCeiling:yCeil ceiling:YES];
            double valueStepY = [self fractionFloorOrCeiling:(yCeil - yFloor) / segmentsOfYAxis ceiling:YES];
            
            //x轴及全部横线的 位置、y轴刻度值
            self.positionStepY = (positionYBottom - positionYTop) / segmentsOfYAxis;
            for (int i = 0; i <= segmentsOfYAxis; ++i) {
                [yAxisValues addObject:@(yFloor + valueStepY * i)];
                [self.positionYOfYAxisValues addObject:@(positionYBottom - self.positionStepY * i)];
            }
        }
        else{//计算[yFloor, yCeil]两端的y刻度值和相邻刻度线长度
            //yFloor跟minY、yCeil跟maxY 不全相等，因此最低或最高两根横线的距离 <> 其他相邻横线通常距离positionStepY，受view高度限制规定最多为positionStepY的1.5倍，为了好看又限制>=positionStepY。
            const double maxMultipleMoreThanPositionStepY = 0.5;//最低或最高两根横线的距离比positionStepY多的最大倍数，多0.5倍也就是等于1.5倍
            if (yFloor == minY) {//x轴y刻度值为minY
                yFloor = [self fractionFloorOrCeiling:yFloor ceiling:NO];
                yCeil = [self fractionFloorOrCeiling:yCeil ceiling:YES];
                double valueStepY = [self fractionFloorOrCeiling:(yCeil - yFloor) / (segmentsOfYAxis - 1) ceiling:YES];
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
                    self.positionStepY = (positionYBottom - positionYTop) / segmentsOfYAxis;
                    valueOfYTop = yCeil + valueStepY;//>= maxY
                }
                else{
                    if ((maxY - yCeil - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {//yCeil对应横线跟上方横线的距离按比例计算
                        self.positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + (maxY - yCeil - valueStepY) / valueStepY);
                    }
                    else{//最高2横线的实际距离设为positionStepY的(1 + maxMultipleMoreThanPositionStepY)倍
                        shouldShowMaxYLabel = NO;
                        self.positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + maxMultipleMoreThanPositionStepY);
                    }
                    valueOfYTop = maxY;
                }
                
                //除最高横线外的横线位置、y轴刻度值，包括x轴
                for (int i = 0; i < segmentsOfYAxis; ++i) {
                    [yAxisValues addObject:@(yFloor + valueStepY * i)];
                    [self.positionYOfYAxisValues addObject:@(positionYBottom - self.positionStepY * i)];
                }
                //最高横线的位置、y轴刻度值
                [yAxisValues addObject:@(valueOfYTop)];
                [self.positionYOfYAxisValues addObject:@(positionYTop)];
            }
            else if(yCeil == maxY){//最高横线y刻度值为maxY
                yFloor = [self fractionFloorOrCeiling:yFloor ceiling:NO];
                yCeil = [self fractionFloorOrCeiling:yCeil ceiling:YES];
                double valueStepY = [self fractionFloorOrCeiling:(yCeil - yFloor) / (segmentsOfYAxis - 1) ceiling:YES];
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
                    self.positionStepY = (positionYBottom - positionYTop) / segmentsOfYAxis;
                    valueOfYBottom = yFloor-valueStepY;
                }
                else{
                    if ((yFloor - minY - valueStepY) / valueStepY <= maxMultipleMoreThanPositionStepY) {//yFloor对应横线跟x轴的距离按比例计算
                        self.positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + (yFloor - minY - valueStepY) / valueStepY);
                    }
                    else{//x轴同上面横线的实际距离设为positionStepY的(1 + maxMultipleMoreThanPositionStepY)倍
                        shouldShowMinYLabel = NO;
                        self.positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + maxMultipleMoreThanPositionStepY);
                    }
                    valueOfYBottom = minY;
                }
                
                //x轴的位置、y轴刻度值
                [yAxisValues addObject:@(valueOfYBottom)];
                [self.positionYOfYAxisValues addObject:@(positionYBottom)];
                //除x轴外横线的位置、y轴刻度值
                for (int i = 1; i <= segmentsOfYAxis; ++i) {
                    [yAxisValues addObject:@(yCeil - valueStepY * (segmentsOfYAxis - i))];
                    [self.positionYOfYAxisValues addObject:@(positionYTop + self.positionStepY * (segmentsOfYAxis - i))];
                }
            }
            else{//x轴和最高横线y刻度值重新计算
                yFloor = [self fractionFloorOrCeiling:yFloor ceiling:NO];
                yCeil = [self fractionFloorOrCeiling:yCeil ceiling:YES];
                double valueStepY = [self fractionFloorOrCeiling:(yCeil - yFloor) / (segmentsOfYAxis - 2) ceiling:YES];
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
                self.positionStepY = (positionYBottom - positionYTop) / (segmentsOfYAxis + actualMultipleMoreThan_top + actualMultipleMoreThan_bottom);
                
                //x轴的位置、y轴刻度值
                [yAxisValues addObject:@(valueOfYBottom)];
                [self.positionYOfYAxisValues addObject:@(positionYBottom)];
                
                CGFloat positionYFloor = positionYBottom - self.positionStepY * (1 + actualMultipleMoreThan_bottom);//x轴上方横线的位置
                //除x轴外横线的位置、y轴刻度值
                for (int i = 0; i < segmentsOfYAxis - 1; ++i) {
                    [yAxisValues addObject:@(yFloor + valueStepY * i)];
                    [self.positionYOfYAxisValues addObject:@(positionYFloor - self.positionStepY * i)];
                }
                
                //最高横线的位置、y轴刻度值
                [yAxisValues addObject:@(valueOfYTop)];
                [self.positionYOfYAxisValues addObject:@(positionYTop)];
            }
        }
    }
//    NSLog(@"所有点的y轴坐标：%@", allPointsYOfLines);
//    NSLog(@"y轴minY %f, yFloor %f, maxY %f, yCeil %f", minY, yFloor, maxY, yCeil);
//    NSLog(@"y轴坐标刻度值%zi个，%@", yAxisValues.count, yAxisValues);
//    NSLog(@"y轴坐标:%@", self.positionYOfYAxisValues);
}

#pragma mark - 创建曲线背景，画x轴、y轴、曲线
//设置x坐标和grid竖线，创建yAxisView并在其上显示y轴。根据x轴的宽度设置graphBackgroundView的宽度和backgroundScrollView.contentSize
- (void)drawXAxis{
    void(^createXAxisLabel)(NSString *, CGFloat, CGFloat, CGFloat) = ^(NSString *s, CGFloat centerX, CGFloat width, CGFloat top){
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(centerX - width / 2, top, width, self.heightXAxisLabel)];
        l.font = self.textFont;
        l.textColor = self.textColor;
        l.text = s;
        l.textAlignment = NSTextAlignmentCenter;
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.7;
        [self.graphBackgroundView addSubview:l];
        [self.xAxisLabels addObject:l];
    };
    
    //划线的最高点和最低点的y
    const CGFloat positionYTop = self.graphMarginV;
    const CGFloat positionYBottom = self.graphMarginV + [self heightYAxis];
    const CGFloat yOfXAxisLabel = positionYBottom + self.graphMarginV;//x轴刻度值label的y位置
    CGFloat x = self.graphMarginL;
    
    //创建yAxisView，在之上显示y轴
    if (yAxisView != nil) {
        [yAxisView removeFromSuperview];
    }
    yAxisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.graphMarginL, self.graphBackgroundView.frame.size.height - self.heightXAxisLabel)];
    yAxisView.backgroundColor = [UIColor whiteColor];
    [self addSubview:yAxisView];
    [yAxisView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];
    
    if (self.xAxisArray.count == 0) {
        return;//无x数据，不再显示x轴刻度值
    }
    
    //显示原点的x轴刻度值。label长度直接用spaceBetweenVisibleXLabels，因为文字居中显示，即使label长度超出范围只要文字不超出范围即可。
    createXAxisLabel(self.xAxisArray[0], x, spaceBetweenVisibleXLabels, yOfXAxisLabel);
    
    int numberOfLabelsBetweenVisibleX = ceil(spaceBetweenVisibleXLabels / self.positionStepX);//相邻可见的x轴刻度值之间的总共刻度值数目（包括可见和不可见的）
    //显示原点外的竖直刻度线和x轴刻度值
    for (int i = 1; i < self.xAxisArray.count; ++i) {
        x += self.positionStepX;
        //每numberOfLabelsBetweenVisibleX个刻度值显示一个，如果显示完i处的刻度值后，余下的点数<要求点数的0.7倍，则不显示i处的刻度值
        //最后一个刻度值总是显示
        if ((i % numberOfLabelsBetweenVisibleX == 0 && self.xAxisArray.count - 1 - i > numberOfLabelsBetweenVisibleX * 0.7)
            || i == self.xAxisArray.count - 1) {
            if (self.drawGridX) {
                //在graphBackgroundView上显示其它竖线
                [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(x, positionYTop) end:CGPointMake(x, positionYBottom)]];
            }
            //显示x轴刻度值
            createXAxisLabel(self.xAxisArray[i], x, spaceBetweenVisibleXLabels, yOfXAxisLabel);
        }
    }
}

- (void)drawYAxis{
    void(^createYAxisLabel)(NSString *, CGFloat, CGFloat, CGFloat) = ^(NSString *s, CGFloat right, CGFloat centerY, CGFloat height){
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(right - self.graphMarginL, centerY - height / 2, self.graphMarginL, height)];
        l.textColor = self.textColor;
        l.font = self.textFont;
        l.text = s;
        l.textAlignment = NSTextAlignmentRight;
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.7;
        [self.yAxisView addSubview:l];//在yAxisView上显示y刻度值
    };
    
    const CGFloat positionYBottom = self.graphMarginV + [self heightYAxis];
    const CGFloat lineStartX = self.graphMarginL;//等于yAxisView的右边缘位置
    const CGFloat lineEndX = self.graphMarginL + [self widthXAxis];
    
    //显示x轴
    [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(lineStartX, positionYBottom) end:CGPointMake(lineEndX, positionYBottom)]];
    //显示原点的y刻度值
    if (shouldShowMinYLabel) {
        createYAxisLabel([self formattedStringForNumber:yAxisValues.firstObject], lineStartX, positionYBottom, self.positionStepY);
    }
    
    //显示除x轴外的横线、y轴刻度值
    for (int i =1; i < self.positionYOfYAxisValues.count; ++i) {
        CGFloat positionY = ((NSNumber *)self.positionYOfYAxisValues[i]).floatValue;
        if (self.drawGridY) {
            [self.graphBackgroundView.layer addSublayer:[self gridLineLayerStart:CGPointMake(lineStartX, positionY) end:CGPointMake(lineEndX, positionY)]];
        }
        if (i < self.positionYOfYAxisValues.count - 1 || shouldShowMaxYLabel) {//非最高横线 或者 should显示最高横线刻度值
            createYAxisLabel([self formattedStringForNumber:yAxisValues[i]], lineStartX, positionY, self.positionStepY);
        }
    }
}

-(void)drawLines{
    [self drawOneLine:lineDataRenderer];//必须在originalPoint之后再createGraph，因为需要用它来fill曲线下方的区域
}

#pragma mark Create marker and legend
-(void)createMarker{
    if (self.defaultMarker != nil) {
        [self.defaultMarker removeFromSuperview];
        self.defaultMarker = nil;
    }
    if (self.xMarker != nil) {
        [self.xMarker removeFromSuperlayer];
        self.xMarker = nil;
    }
    if (self.yMarker != nil) {
        [self.yMarker removeFromSuperlayer];
        self.yMarker = nil;
    }
    if (!self.showMarker) {
        return;
    }
    if (![self.dataSource respondsToSelector:@selector(markerViewForline:pointIndex:andYValue:)]) {
        self.defaultMarker = [[LineGraphMarker alloc] init];
        self.defaultMarker.hidden = YES;
        self.defaultMarker.frame = CGRectZero;
        self.defaultMarker.bgColor = self.markerColor;
        self.defaultMarker.textColor = self.markerTextColor;
        self.defaultMarker.textFont = textFont;
        [self.graphBackgroundView addSubview:self.defaultMarker];
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
}

- (void)createLegend{
    if (self.legendView != nil) {
        [self.legendView removeFromSuperview];
        self.legendView = nil;
    }
    if (!self.showLegend) {
        return;
    }
    self.legendView = [[LegendView alloc] initWithFrame:CGRectMake(LegendViewMarginH, CGRectGetMaxY(self.graphBackgroundView.frame), self.frame.size.width - 2*LegendViewMarginH, 0)];
    [self.legendView setLegendArray:self.legendArray];
    [self.legendView setFont:self.textFont];
    [self.legendView setTextColor:self.textColor];
    [self.legendView setLegendViewType:self.legendViewType];
    [self.legendView createLegend];
    [self addSubview:self.legendView];
}

-(CGFloat)xPositionOfAxis:(NSUInteger)pointIndex{
    //第pointIndex个点在x轴的位置
    return self.graphMarginL + self.positionStepX * pointIndex;
}

-(CGPoint)pointAtIndex:(NSUInteger)pointIndex inLine:(LineChartDataRenderer *)lineData{
    double yValue = [[lineData.yAxisArray objectAtIndex:pointIndex] doubleValue];
    for (int i = 0; i < yAxisValues.count; ++i){
        if (yValue - ((NSNumber *)yAxisValues[i]).doubleValue < 0.000001) {//double的比较需要比较差值和一个小数，比如-0.5999999995和-0.6000000001
            //刻度值是上面的大，view里点的y坐标是下面的大
            double yValueAbove = ((NSNumber *)yAxisValues[i]).doubleValue;//点上方的y轴刻度值
            CGFloat positionYAbove = ((NSNumber *)self.positionYOfYAxisValues[i]).floatValue;//点上方的y轴刻度值的位置
            if (i == 0) {
                return CGPointMake([self xPositionOfAxis:pointIndex], positionYAbove);
            }
            else{
                double yValueBellow = ((NSNumber *)yAxisValues[i - 1]).doubleValue;//点下方的y轴刻度值
                CGFloat positionYBellow = ((NSNumber *)self.positionYOfYAxisValues[i - 1]).floatValue;//点下方的y轴刻度值的位置
                return CGPointMake([self xPositionOfAxis:pointIndex], positionYBellow - (yValue - yValueBellow) / (yValueAbove - yValueBellow) * (positionYBellow - positionYAbove));
            }
        }
    }
    NSAssert2(NO, @"Invalid point at index %zi of lineData.yAxisArray %@", pointIndex, lineData.yAxisArray);
    return CGPointZero;
}

- (void)showMakerNearPoint:(CGPoint)pointTouched checkXDistanceOnly:(BOOL)checkXDistanceOnly{
    NSString *xString;
    NSNumber *yNumber;
    NSString *yString;//string presentation of yNumber
    CGFloat minDistance = MAXFLOAT;
    CGPoint closestPoint;//距离最近的点
    NSUInteger closestPointIndex = 0;
    
    for (int i = 0; i < lineDataRenderer.yAxisArray.count; ++i){
        CGPoint point = [self pointAtIndex:i inLine:lineDataRenderer];
        CGFloat distance = checkXDistanceOnly ? fabs(pointTouched.x - point.x) : sqrtf(powf(pointTouched.x - point.x, 2) + powf(pointTouched.y - point.y, 2));
        if (distance < minDistance) {
            minDistance = distance;
            closestPoint = point;
            closestPointIndex = i;
            xString = [self.xAxisArray objectAtIndex:i];
            yNumber = [lineDataRenderer.yAxisArray objectAtIndex:i];
            yString = [self formattedStringForNumber:yNumber];
        }
    }
    
    //先隐藏十字线和提示框
    self.xMarker.hidden = YES;
    self.yMarker.hidden = YES;
    if (self.customMarkerView != nil) {
        [self.customMarkerView removeFromSuperview];
        self.customMarkerView = nil;
    }
    if (self.defaultMarker != nil) {
        self.defaultMarker.hidden = YES;
    }
    
    //距离过远的点不处理
    if (!checkXDistanceOnly && minDistance > (self.positionStepX + self.positionStepY) * 0.8) {
        //不能简单比较 positionStepX / 2，如果x轴刻度很密集则该限制过紧，如果只有一个点则为0，所以需要综合positionStepX + positionStepY考虑
        return;
    }
    
    closestPoint = [self optimizedPoint:closestPoint];
    
    self.xMarker.path = [self pathFrom:CGPointMake(closestPoint.x, ((NSNumber *)self.positionYOfYAxisValues.firstObject).floatValue) to:CGPointMake(closestPoint.x, ((NSNumber *)self.positionYOfYAxisValues.lastObject).floatValue)].CGPath;
    self.xMarker.hidden = NO;
    
    self.yMarker.path = [self pathFrom:CGPointMake(self.originalPoint.x, closestPoint.y) to:CGPointMake([self xPositionOfAxis:self.xAxisArray.count <= 1 ? 1 : self.xAxisArray.count - 1], closestPoint.y)].CGPath;
    self.yMarker.hidden = NO;
    
    if ([self.dataSource respondsToSelector:@selector(markerViewForline:pointIndex:andYValue:)]) {
        self.customMarkerView = [self.dataSource markerViewForline:self pointIndex:(filterYOutOfRange ? ((NSNumber *)filteredIndexArray[closestPointIndex]).intValue : closestPointIndex) andYValue:yNumber];
        
        if (self.customMarkerView != nil) {
            CGSize markerSize = self.customMarkerView.frame.size;
            CGPoint makerViewOrigin = [self calculateMarker:markerSize originWith:closestPoint];
            self.customMarkerView.frame = CGRectMake(makerViewOrigin.x, makerViewOrigin.y, markerSize.width, markerSize.height);
            [self.graphBackgroundView addSubview:self.customMarkerView];
        }
        [self.graphBackgroundView addSubview:self.customMarkerView];
    }
    else{
        [self.defaultMarker setXString:xString];
        [self.defaultMarker setYString:yString];
        [self.defaultMarker drawAtPoint:CGPointMake(closestPoint.x, self.graphMarginV)];
        self.defaultMarker.hidden = NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(didTapLine:atPoint:valuesAtY:)]) {
        [self.delegate didTapLine:self atPoint:(filterYOutOfRange ? ((NSNumber *)filteredIndexArray[closestPointIndex]).intValue : closestPointIndex) valuesAtY:yNumber];
    }
}

@end
