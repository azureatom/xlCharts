//
//  LineGraphBase.h
//  xlchart
//
//  Created by lei xue on 16/9/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>
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
@property (nonatomic, strong) UIView *graphBackgroundView;
@property (assign, nonatomic) CGPoint originalPoint;//原点的位置

@property (nonatomic, strong) NSArray *xAxisArray;//array of NSString, x轴的刻度，@""表示不显示该刻度值和竖直刻度线
@property (strong, nonatomic) NSMutableArray *xAxisLabels;//array of UILabel, 显示x轴的刻度值的label
@property (assign, nonatomic) CGFloat positionStepX;//相邻点的x方向距离。SingleLineGraphScrollable至少为minPositionStepX；SingleLineGraphNonScrollable自动计算使x轴刚好占满区域长度。
@property (assign, nonatomic) CGFloat positionStepY;

@property (nonatomic, strong) UIColor *gridLineColor; //Default is [UIColor lightGrayColor]
@property (assign, nonatomic) CGFloat gridLineWidth; //Default is 0.3

@property (assign, nonatomic) BOOL shouldDrawPoints;//是否画出曲线上的点，默认YES
@property (assign, nonatomic) CGFloat maxPointRadius;//曲线上点的最大半径，默认1.5
@property (assign, nonatomic) CGFloat pointRadius;//根据maxPointRadius计算的点的半径，画线时最终采用的点半径可能随点数增多而减少至线宽

@property (strong, nonatomic) NSMutableArray *positionYOfYAxisValues;//arrray of NSNumber，yAxisValues对应的y轴刻度值的view的y位置，从原点到最高点。

//marker和十字线
@property (nonatomic) BOOL showMarker; //是否显示十字线和提示框，默认YES。如果[dataSource respondsToSelector:@selector(markerViewForline:pointIndex:andYValue:)]则优先显示用户自定义提示框，否则直接显示默认提示框（显示在坐标系的上方）
@property (nonatomic, strong) UIColor *markerTextColor; //默认提示框的文字颜色，默认[UIColor whiteColor]
@property (nonatomic, strong) UIColor *markerColor; //十字线的颜色，默认[UIColor orangeColor]
@property (nonatomic) CGFloat markerWidth; //十字线的线宽，默认0.4
@property (nonatomic, strong) CAShapeLayer *xMarker;//点击显示十字线的竖线
@property (nonatomic, strong) CAShapeLayer *yMarker;//点击显示十字线的横线
@property (nonatomic, strong) LineGraphMarker *defaultMarker;//点击显示的提示信息view
@property (nonatomic, strong) UIView *customMarkerView;//自定义 点击显示的提示信息view

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
- (void)drawOneLine:(LineChartDataRenderer *)lineData;
- (void)fillGraphBackgroundWithPath:(UIBezierPath *)path color:(UIColor *)color;
- (CAShapeLayer *)gridLineLayerStart:(CGPoint)startPoint end:(CGPoint)endPoint;
- (UIBezierPath *)pathFrom:(CGPoint)startPoint to:(CGPoint)endPoint;
- (void)drawPointsOnLine:(CGPoint)point withColor:(UIColor *)color;
-(void)handleTapPanLongPress:(UITapGestureRecognizer *)gesture;

-(CGFloat)widthGraph;
-(CGFloat)widthXAxis;
-(CGFloat)heightGraph;//subclass可以override，比如有LegendView时
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
-(void)drawLines;
- (void)createMarker;
//操作坐标系上的点
- (CGFloat)xPositionOfAxis:(NSUInteger)pointIndex;
-(CGPoint)pointAtIndex:(NSUInteger)pointIndex inLine:(LineChartDataRenderer *)lineData;
/**
 *  在距离 点击或拖拽的点 最近的曲线点显示十字线和弹出框
 *
 *  @param pointTouched       点击或拖拽到的点
 *  @param checkXDistanceOnly YES 则选取曲线上跟 pointTouched x轴方向距离最近的点即可；NO 则比较 曲线上点跟 pointTouched 的最短距离是否足够小
 */
- (void)showMakerNearPoint:(CGPoint)pointTouched checkXDistanceOnly:(BOOL)checkXDistanceOnly;
-(CGPoint)calculateMarker:(CGSize)viewSize originWith:(CGPoint)closestPoint;
@end
