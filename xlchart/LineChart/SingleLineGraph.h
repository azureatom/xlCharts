//
//  SingleLineGraph.h
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LegendView.h"

const static CGFloat k_xAxisLabelHeight = 15;//x轴刻度值的高度
const static CGFloat k_graphVerticalMargin = 8;//x轴和x轴刻度值之间的空白、表格上方的空白(用于显示最上面的y刻度值的上半部分)
const static CGFloat k_graphLeftMargin = 50;//y轴刻度值的宽度，图表左侧的空白
const static CGFloat k_graphRightMargin = 20;//图表右侧的空白

@class SingleLineGraph;

@protocol SingleLineGraphDelegate  <NSObject>
/**
 *  点击点的index和y值
 *
 *  @param graph
 *  @param pointIndex 是第几个点，也即x轴的第几个刻度值
 *  @param yValue 点击点对应的y值
 */
- (void)didTapLine:(SingleLineGraph *)graph atPoint:(NSUInteger)pointIndex valuesAtY:(NSNumber *)yValue;
@end

@protocol SingleLineGraphDataSource  <NSObject>
/**
 *  Set data for x-Axis for the Line Graph
 *  如果filteredIndexArray非nil，则只选择原始数据中指定index的值
 *
 *  @return array of NSString, only draw x-axis if string is not empty, that is exclude @""
 */
- (NSArray *)xAxisDataForLine:(SingleLineGraph *)graph filtered:(NSArray *)filteredIndexArray;

- (NSArray *)yAxisDataForline:(SingleLineGraph *)graph;
//Set yData for Line on Line Graph

@optional
/**
 *  返回的自定义view.frame.size的 width和height 必须是整数，如果是小数可能由于屏幕分辨率和像素匹配问题导致显示模糊
 *
 *  @param graph
 *  @param pointIndex
 *  @param yValue
 *
 *  @return 自定义view
 */
- (UIView *)markerViewForline:(SingleLineGraph *)graph pointIndex:(NSUInteger)pointIndex andYValue:(NSNumber *)yValue;
@end

@interface SingleLineGraph : UIView
@property (weak, nonatomic) id<SingleLineGraphDelegate> delegate;
@property (weak, nonatomic) id<SingleLineGraphDataSource> dataSource;
//set FONT property for the graph
@property (nonatomic, strong) UIFont *textFont; //Default is [UIFont systemFontOfSize:12];
@property (nonatomic, strong) UIColor *textColor; //Default is [UIColor blackColor]
@property (assign, nonatomic) NSUInteger fractionDigits;//显示的y轴刻度值取小数点后几位小数，默认是0也即整数

//line and points
@property (strong, nonatomic) UIColor *lineColor;//曲线颜色，默认黑色
@property (assign, nonatomic) CGFloat lineWidth;//曲线线宽，默认0.5
@property (strong, nonatomic) NSString *lineName;//曲线名字，显示在legendView上
@property (assign, nonatomic) BOOL shouldFill;//是否将曲线的区域填充颜色，默认YES
@property (assign, nonatomic) BOOL shouldDrawPoints;//是否画出曲线上的点，默认YES
@property (assign, nonatomic) CGFloat maxPointRadius;//曲线上点的最大半径，默认1.5
@property (assign, nonatomic) CGFloat pointRadius;//根据maxPointRadius计算的点的半径，画线时最终采用的点半径可能随点数增多而减少至线宽

//show Grid with the graph
@property (nonatomic) BOOL drawGridX; //x轴竖直刻度线，Default is YES
@property (nonatomic) BOOL drawGridY; //y轴水平刻度线，Default is YES
@property (nonatomic, strong) UIColor *gridLineColor; //Default is [UIColor lightGrayColor]
@property (assign, nonatomic) CGFloat gridLineWidth; //Default is 0.3

/**
 *  是否支持Pan和LongPress手势。
 *  默认YES，忽略minPositionStepX而将positionStepX设为使 graphView 刚好占满 graphScrollView 的值，不可左右滚动，识别多种手势
 *  NO 只支持TapGesture显示Marker，不识别LongPressGesture和PanGesture手势，也即 graphView 可以超过 graphScrollView 的长度 从而左右滚动
 */
@property (assign, nonatomic) BOOL enablePanAndLongPress;
//show marker or customMarker when interacting with graph.
//If Both MARKER and CUSTOM MARKER view are True then CUSTOM MARKER View Priorties over MARKER View.
@property (nonatomic) BOOL showMarker; //是否显示十字线和默认的提示框，提示框默认显示在坐标系的上方，Default is YES
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
