//
//  LineGraphBase.h
//  xlchart
//
//  Created by lei xue on 16/9/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LineChartDataRenderer.h"
#import "LegendView.h"
#import "LineGraphMarker.h"

#define ANIMATION_DURATION 1.2f

@interface LineGraphBase : UIView
/**
 *  是否支持Pan和LongPress手势。
 *  默认YES，忽略minPositionStepX而将positionStepX设为使 graphBackgroundView 刚好占满 backgroundScrollView 的值，不可左右滚动，识别多种手势
 *  NO 只支持TapGesture显示Marker，不识别LongPressGesture和PanGesture手势，也即 graphBackgroundView 可以超过 backgroundScrollView 的长度 从而左右滚动
 */
@property (assign, nonatomic) BOOL enablePanAndLongPress;
@property (assign, nonatomic) NSUInteger fractionDigits;//显示的y轴刻度值取小数点后几位小数，默认是0也即整数
@property (nonatomic, strong) UIView *graphBackgroundView;
@property (assign, nonatomic) CGPoint originalPoint;//原点的位置

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

//legend
@property (nonatomic) BOOL showLegend; //Default is NO
//Set LEGEND TYPE Horizontal or Vertical
@property (nonatomic) LegendType legendViewType; //Default is LegendTypeVertical i.e. VERTICAL

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
- (UIBezierPath *)drawPathWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;
- (void)drawPointsOnLine:(CGPoint)point withColor:(UIColor *)color;

#pragma mark - Method must be override by subclass
-(CGPoint)pointAtIndex:(NSUInteger)pointIndex inLine:(LineChartDataRenderer *)lineData;
- (void)createGraphBackground;
- (void)createXAxisLine;
- (void)createYAxisLine;
- (CGFloat)xPositionOfAxis:(NSUInteger)pointIndex;
- (void)calculatePointRadius;
- (void)drawLines;
- (void)createMarker;
- (void) createLegend;
@end
