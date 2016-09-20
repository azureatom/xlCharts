//
//  LineGraphBase.h
//  xlchart
//
//  Created by lei xue on 16/9/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphContainerView.h"
#import "LineChartDataRenderer.h"
#import "LineGraphMarker.h"

@interface LineGraphBase : UIView
//一些可以修改的UI属性
@property(assign, nonatomic) CGFloat animationDuration;//动画时长，默认1.2s
@property(assign, nonatomic) CGFloat heightXAxisLabel;//x轴刻度值的高度，默认15
@property(assign, nonatomic) CGFloat graphMarginV;//x轴和x轴刻度值之间的空白、表格上方的空白(用于显示最上面的y刻度值的上半部分)，默认8
@property(assign, nonatomic) CGFloat graphMarginL;//y轴刻度值的宽度，图表左侧的空白，默认50
@property(assign, nonatomic) CGFloat graphMarginR;//图表右侧的空白，默认20

@property (assign, nonatomic) NSUInteger fractionDigits;//显示的y轴刻度值取小数点后几位小数，默认是0也即整数
@property (nonatomic, strong) GraphContainerView *graphBackgroundView;
@property (assign, nonatomic) CGPoint originalPoint;//原点的位置

@property (nonatomic, strong) NSArray *xAxisArray;//array of NSString, x轴的刻度，@""表示不显示该刻度值和竖直刻度线
@property (strong, nonatomic) NSMutableArray *xAxisLabels;//array of UILabel, 显示x轴的刻度值的label
@property (assign, nonatomic) CGFloat positionStepX;//相邻点的x方向距离。SingleLineGraphScrollable至少为minPositionStepX；SingleLineGraphNonScrollable自动计算使x轴刚好占满区域长度。

@property (strong, nonatomic) NSMutableArray *yAxisValues;//array of NSNumber，y轴从下到上的刻度值。
@property (strong, nonatomic) NSMutableArray *positionYOfYAxisValues;//arrray of NSNumber，yAxisValues对应的y轴刻度值的view的y位置，从原点到最高点。刻度值之间的距离等于positionStepY，但SingleLineGraphBase中超范围的y值例外。
@property (assign, nonatomic) CGFloat positionStepY;

//text font and color
@property (nonatomic, strong) UIFont *axisFont;//坐标轴刻度值label的字体，也用于默认的defaultMarker的字体，默认[UIFont systemFontOfSize:12]
@property (nonatomic, strong) UIColor *textColor;//通常的字体颜色，如：坐标轴刻度值、defaultMarker、LegendView，默认[UIColor blackColor]

@property (nonatomic, strong) UIColor *gridLineColor; //Default is [UIColor lightGrayColor]
@property (assign, nonatomic) CGFloat gridLineWidth; //Default is 0.3

//marker和十字线
@property (assign, nonatomic) BOOL showMarker; //是否显示十字线和提示框，默认YES
@property (nonatomic, strong) UIColor *markerColor; //十字线的颜色，默认[UIColor orangeColor]
@property (nonatomic) CGFloat markerWidth; //十字线的线宽，默认0.4
@property (nonatomic, strong) CAShapeLayer *xMarker;//点击显示十字线的竖线
@property (nonatomic, strong) CAShapeLayer *yMarker;//点击显示十字线的横线
@property (nonatomic, strong) LineGraphMarker *defaultMarker;//点击默认显示提示信息的view
@property(strong, nonatomic) UIColor *markerBgColor;//提示框的背景颜色，默认[UIColor grayColor]
@property (nonatomic, strong) UIColor *markerTextColor; //默认提示框的文字颜色，默认[UIColor whiteColor]

@property (assign, nonatomic) BOOL shouldDrawPoints;//是否画出曲线上的点，默认YES
@property (assign, nonatomic) CGFloat maxPointRadius;//曲线上点的最大半径，默认1.5
@property (assign, nonatomic) CGFloat pointRadius;//根据maxPointRadius计算的点的半径，画线时最终采用的点半径可能随点数增多而减少至线宽

#pragma mark - 公用方法
- (NSString *)formattedStringForNumber:(NSNumber *)n;
/**
 *  将小数按照self.fractionDigits位小数向上或向下取整
 *
 *  @param d         传入的小数
 *  @param isCeiling 是否向上/向下
 *
 *  @return 取整精度后的小数
 */
- (double)fractionFloorOrCeiling:(double)d ceiling:(BOOL)isCeiling;
- (CGPoint)optimizedPoint:(CGPoint)point;
/**
 *  计算点的x方向位置。通常对应x轴刻度值的位置，但subclass可以override，如日K线等对应的是x轴刻度段的中点位置。
 *
 *  @param pointIndex 第几个点
 *
 *  @return 点的x位置
 */
- (CGFloat)xPositionAtIndex:(NSUInteger)pointIndex;//subclass可以override
/**
 *  计算某位置x方向最近的点的index
 *
 *  @param positionX 在x方向上的位置
 *
 *  @return x轴的positionX位置最近的刻度值的index，在坐标系左边或者没有点则返回-1
 */
- (int)indexOfXForPosition:(CGFloat)positionX;
/**
 *  根据值计算其在坐标系的y位置
 *
 *  @param yValue 需要计算的坐标系的y值
 *
 *  @return 坐标系y方向位置
 */
-(CGFloat)yPositionOfValue:(double)yValue;
/**
 *  计算曲线上的点的y方向位置
 *
 *  @param pointIndex 第几个点
 *  @param lineData   曲线数据
 *
 *  @return 点的y位置
 */
-(CGFloat)yPositionAtIndex:(NSUInteger)pointIndex inLine:(LineChartDataRenderer *)lineData;
-(CGPoint)pointAtIndex:(NSUInteger)pointIndex inLine:(LineChartDataRenderer *)lineData;

/**
 *  计算曲线上距离targetPoint最近的点
 *
 *  @param closestPoint       输出参数，找到的最近点的坐标
 *  @param targetPoint        已知点
 *  @param minDistance        输出参数，最近点的距离
 *  @param line               曲线
 *  @param checkXDistanceOnly 只比较x方向的距离还是比较实际距离
 *
 *  @return 最近的点的index，如果没有则返回-1
 */
-(int)calculateClosestPoint:(CGPoint *)closestPoint near:(CGPoint)targetPoint distance:(CGFloat *)minDistance inLine:(LineChartDataRenderer *)line checkXDistanceOnly:(BOOL)checkXDistanceOnly;
- (void)drawOneLine:(LineChartDataRenderer *)lineData;
- (void)fillGraphBackgroundWithPath:(UIBezierPath *)path color:(UIColor *)color;
- (CAShapeLayer *)gridLineLayerStart:(CGPoint)startPoint end:(CGPoint)endPoint;
- (UIBezierPath *)pathFrom:(CGPoint)startPoint to:(CGPoint)endPoint;
- (void)drawPointsOnLine:(CGPoint)point withColor:(UIColor *)color;

-(CGFloat)widthGraph;
-(CGFloat)widthXAxis;
-(CGFloat)heightGraph;//subclass可以override。如果只显示坐标系，则为self.frame.size.height；没有包括LegendView或分时成交量图等
-(CGFloat)heightYAxis;
/**
 *  前面设置计算完各种长度后，才能调用该方法
 *
 *  @return 返回坐标系的frame，不包括上下左右的空白
 */
-(CGRect)axisFrame;

#pragma mark - Method must be override by subclass
- (void)reloadGraph;//reload UI and data
- (void)setupDataWithDataSource;
//计算坐标系数据
-(BOOL)calculatePositionStepX;
- (void)calculatePointRadius;
- (void)calculateYAxis;
//画坐标系
- (void)createGraphBackground;
- (void)drawXAxis;
- (void)drawYAxis;
- (void)drawLines;
- (void)createMarker;

- (void)dismissMarker;//隐藏marker
/**
 *  在距离 点击或拖拽的点 最近的曲线点显示十字线和弹出框
 *
 *  @param pointTouched       点击或拖拽到的点
 *  @param checkXDistanceOnly YES 则选取曲线上跟 pointTouched x轴方向距离最近的点即可；NO 则还需要比较 曲线上点跟 pointTouched 的最短距离是否足够小
 *
 *  @return marker显示返回YES，没有点或没显示返回NO
 */
- (BOOL)showMakerNearPoint:(CGPoint)pointTouched checkXDistanceOnly:(BOOL)checkXDistanceOnly;
@end
