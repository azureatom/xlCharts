//
//  MultiLineGraph.h
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LineGraphBase.h"
#import "LegendView.h"

const static CGFloat heightXAxisLabel = 15;//x轴刻度值的高度
const static CGFloat graphMarginV = 8;//x轴和x轴刻度值之间的空白、表格上方的空白(用于显示最上面的y刻度值的上半部分)
const static CGFloat graphMarginL = 50;//y轴刻度值的宽度，图表左侧的空白
const static CGFloat graphMarginR = 20;//图表右侧的空白

@class MultiLineGraph;

@protocol MultiLineGraphDelegate  <NSObject>
/**
 *  点击点的index和y值
 *
 *  @param graph
 *  @lineNumber 第几根线
 *  @param pointIndex 是第几个点，也即x轴的第几个刻度值
 *  @param yValue 点击点对应的y值
 */
- (void)lineGraph:(MultiLineGraph *)graph didTapLine:(NSInteger)lineNumber atPoint:(NSUInteger)pointIndex valuesAtY:(NSNumber *)yValue;
@end

@protocol MultiLineGraphDataSource  <NSObject>
/**
 *  Set data for x-Axis for the Line Graph
 *  如果filteredIndexArray非nil，则只选择原始数据中指定index的值
 *
 *  @return array of NSString, only draw x-axis if string is not empty, that is exclude @""
 */
- (NSArray *)lineGraphXAxisData:(MultiLineGraph *)graph filtered:(NSArray *)filteredIndexArray;

- (NSInteger)lineGraphNumberOfLines:(MultiLineGraph *)graph;
//Set number of lines to be plotted on the Line Graph

- (UIColor *)lineGraph:(MultiLineGraph *)graph lineColor:(NSInteger)lineNumber;
//Set Line Color for each for Line on the Line Graph
//Default is Black Color

- (CGFloat)lineGraph:(MultiLineGraph *)graph lineWidth:(NSInteger)lineNumber;
//Set Line Width for each for Line on the Line Graph
//Default is 1.0F

//返回曲线上点的半径，画线时最终采用的点半径可能随点数增多而减少至线宽
- (CGFloat)lineGraph:(MultiLineGraph *)graph pointRadius:(NSInteger)lineNumber;

- (NSString *)lineGraph:(MultiLineGraph *)graph lineName:(NSInteger)lineNumber;
//Set Line Name for each for Line on the Line Graph
//Default is Empty String

- (BOOL)lineGraph:(MultiLineGraph *)graph shouldFill:(NSInteger)lineNumber;
//Set Fill Property for each for Line on the Line Graph
//Default is False

- (BOOL)lineGraph:(MultiLineGraph *)graph shouldDrawPoints:(NSInteger)lineNumber;
//Set Draw Points Property for each for Line on the Line Graph
//Default is False

- (NSArray *)lineGraph:(MultiLineGraph *)graph yAxisData:(NSInteger)lineNumber;
//Set yData for Line on Line Graph

//跳过前N个点，一般返回0，但是 ma5线 从第5天开始有数据，前4天跳过
- (int)lineGraph:(MultiLineGraph *)graph ignoreFirstNPoints:(NSInteger)lineNumber;

@optional
/**
 *  返回的自定义view.frame.size的 width和height 必须是整数，如果是小数可能由于屏幕分辨率和像素匹配问题导致显示模糊
 *
 *  @param graph
 *  @param lineNumber
 *  @param pointIndex
 *  @param yValue
 *
 *  @return 自定义view
 */
- (UIView *)lineGraph:(MultiLineGraph *)graph customViewForLine:(NSInteger)lineNumber pointIndex:(NSUInteger)pointIndex andYValue:(NSNumber *)yValue;
@end

typedef enum{
    LineTypeFixedTimeLine,//固定x轴刻度值，分时线
    LineTypeFixed5DaysTimeLine,//固定x轴刻度值，5日分时线，暂时不实现
    LineTypeAuto,//x轴刻度值自动计算，比如日K线、周K线、月K线
} LineType;

/*
 MultiLineGraph 多条曲线
 曲线点的所有y值都在一个较小的范围内，因此所有的点都会显示。
 y方向同时显示价格和百分比。y轴有侧显示价格。最右边竖线的左侧显示涨跌幅百分百，只显示最高和最低横线的涨跌幅，不显示中间线的0%。
 价格取整fractionDigits（基金价格取3位小数），百分比取整百分数的2位小数。
 
 根据LineType的类型设置x轴刻度值的逻辑：
    x轴的首尾刻度线为竖直实线，刻度值显示在线下方内侧；中间的刻度线为竖直虚线，刻度值显示在线正下方。
    LineTypeFixedTimeLine，分时线：x轴刻度分4段，分别为9:30， 10:30， 11:30/13:00, 14:00, 15:00。
    LineTypeFixed5DaysTimeLine，5日分时线：x轴刻度值分为5段，日期显示在刻度段下方，而不是显示在刻度线正下方。
    LineTypeAuto，日K/周K/月K线：x轴相邻刻度值超过一定长度就显示，其中第一个和最后一个刻度值总是显示，同SingleLineGraphBase的逻辑。在TimeLineGraph中额外显示蜡烛图。
    注意：LineTypeAuto的部分曲线可以跳过前N个点，比如 5日均线ma5 跳过前4个点。
 根据LineType的类型设置y轴刻度值的逻辑：
    以 所有曲线的正负 max(fabs(最高价), fabs(最低价)) 作为y轴的最高、最低刻度值（刻度线为实线）。
    LineTypeFixedTimeLine 为三根横线，，以昨日收盘价作为y轴中间刻度值（刻度线为虚线）。如果 fabs(max值/昨日收盘价 - 1) < 0.02（也即涨跌幅<2%），则将max值设为昨日收盘价*1.02。
    LineTypeAuto为5跟横线，按照最大值最小值评分，主要最大值==最小值，为0的特殊情况。
 
 点击曲线上的点，显示十字线，并且在十字线左右端点内侧显示价格、涨幅百分比，在x轴下方显示时间。外界在曲线上方显示“价格、涨跌幅、成交量、均价、日期时间”，曲线上的点未点击时显示的是最新值。
 
 */
@interface MultiLineGraph : LineGraphBase
@property (weak, nonatomic) id<MultiLineGraphDelegate> delegate;
@property (weak, nonatomic) id<MultiLineGraphDataSource> dataSource;
//set FONT property for the graph
@property (nonatomic, strong) UIFont *textFont; //Default is [UIFont systemFontOfSize:12];
@property (nonatomic, strong) UIColor *textColor; //Default is [UIColor blackColor]
@property (assign, nonatomic) NSUInteger fractionDigits;//显示的y轴刻度值取小数点后几位小数，默认是0也即整数

//show Grid with the graph
@property (nonatomic) BOOL drawGridX; //x轴竖直刻度线，Default is TRUE
@property (nonatomic) BOOL drawGridY; //y轴水平刻度线，Default is TRUE
//set property for the grid
@property (nonatomic, strong) UIColor *gridLineColor; //Default is [UIColor lightGrayColor]
@property (assign, nonatomic) CGFloat gridLineWidth; //Default is 0.4

//show MARKER when interacting with graph
@property (nonatomic) BOOL showMarker; //是否显示十字线和默认的提示框，提示框默认显示在坐标系的上方，Default is YES
//show CUSTOM MARKER when interacting with graph.
//If Both MARKER and CUSTOM MARKER view are True then CUSTOM MARKER View Priorties over MARKER View.
@property (nonatomic) BOOL showCustomMarkerView; //是否显示自定义提示框，Default is NO
//to set marker property
@property (nonatomic, strong) UIColor *markerColor; //Default is [UIColor orangeColor]
@property (nonatomic, strong) UIColor *markerTextColor; //Default is [UIColor whiteColor]
@property (nonatomic) CGFloat markerWidth; //Default is 0.4F

//show LEGEND with the graph
@property (nonatomic) BOOL showLegend; //Default is TRUE
//Set LEGEND TYPE Horizontal or Vertical
@property (nonatomic) LegendType legendViewType; //Default is LegendTypeVertical i.e. VERTICAL

@property (assign, nonatomic) CGFloat minPositionStepX;//默认25.用户自定义相邻点的x方向距离，用于设置positionStepX。如果所有点的x方向距离之和不能占满横向区域，则实际距离positionStepX会采用恰好占满的值
@property (assign, nonatomic) CGFloat spaceBetweenVisibleXLabels;//默认60.相邻的可见的x轴刻度值的距离，之间可能包含多个不可见的x轴刻度值（因为都显示则空间不够）
@property (assign, nonatomic) NSUInteger segmentsOfYAxis;//即y轴分段数，也等于除x轴外的横线数目，默认为5，必须>=2
/**
 *  用户定义的y轴坐标的最大值和最小值。
 *  如果所有的y值的范围可以包含在customMaxValidY-customMinValidY范围内，则所有的y都显示；
 *  否则，找到差值为customMaxValidY - customMinValidY内的最多的点，精确显示这些点的位置，其他点在曲线上粗略显示
 *  如果 filterYOutOfRange，则过滤超出范围的曲线的y值，并且将过滤后的元素在原始array的index存入filteredIndexArray，然后根据filteredIndexArray从dataSource获取过滤后的x轴刻度字符串。
 */
@property (assign, nonatomic) CGFloat customMaxValidY;//default is MAXFLOAT / 4，这样 customMaxValidY - customMinValidY的值就不会超过MAXFLOAT
@property (assign, nonatomic) CGFloat customMinValidY;//default is -MAXFLOAT / 4
@property (assign, nonatomic) BOOL filterYOutOfRange;//过滤掉超出 [customMinValidY, customMaxValidY]的y值，默认NO
@property (strong, nonatomic) NSArray *filteredIndexArray;//过滤之后的元素在原始array里的index，比如@[@0, @3, @10]，默认为nil

//To reload data on the graph
- (void)reloadGraph;
- (CGFloat)visibleWidthExcludeMargin;//可显示曲线的区域宽度，排除两边的margin
@end
