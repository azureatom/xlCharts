//
//  SingleLineGraphBase.h
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LineGraphBase.h"
#import "LegendView.h"

@class SingleLineGraphBase;

@protocol SingleLineGraphBaseDelegate  <NSObject>
/**
 *  点击点的index和y值
 *
 *  @param graph
 *  @param pointIndex 是第几个点，也即x轴的第几个刻度值
 *  @param yValue 点击点对应的y值
 */
- (void)didTapLine:(SingleLineGraphBase *)graph atPoint:(NSUInteger)pointIndex valuesAtY:(NSNumber *)yValue;
@end

@protocol SingleLineGraphBaseDataSource  <NSObject>
/**
 *  x-Axis data for line graph
 *  如果filteredIndexArray非nil，则只选择原始数据中指定index的值
 *
 *  @return array of NSString, only draw x-axis if string is not empty, that is exclude @""
 */
- (NSArray *)xAxisDataForLine:(SingleLineGraphBase *)graph filtered:(NSArray *)filteredIndexArray;

- (NSArray *)yAxisDataForline:(SingleLineGraphBase *)graph;//y-Axis data for line graph.

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
- (UIView *)markerViewForline:(SingleLineGraphBase *)graph pointIndex:(NSUInteger)pointIndex andYValue:(NSNumber *)yValue;
@end

/*
 SingleLineGraphBase 一条曲线
 segmentsOfYAxis设置y轴的刻度段数，y轴的刻度值显示在y轴左方。
 自动处理超范围的y值：
    1. 曲线上的点的y值，如果filterYOutOfRange为YES则排除超过范围的值；
    2. 如果y值的 最大值-最小值差额过大，超过 validYRange = customMaxValidY - customMinValidY，则计算取差额<validYRange的最多的点计算y轴的平均刻度值，范围外的点显示在y轴刻度值的最大/最小值的上方/下方。
 点击曲线上的点，显示十字线，并且在十字线处弹出提示框。
 x轴的刻度值显示在刻度线的正下方。如果启用曲线的左右滑动功能，当曲线左移动，越过x轴的部分会被挡住，x轴刻度值也会逐渐消失。
 */
@interface SingleLineGraphBase : LineGraphBase
@property (weak, nonatomic) id<SingleLineGraphBaseDelegate> delegate;
@property (weak, nonatomic) id<SingleLineGraphBaseDataSource> dataSource;

//line and points
@property (strong, nonatomic) UIColor *lineColor;//曲线颜色，默认黑色
@property (assign, nonatomic) CGFloat lineWidth;//曲线线宽，默认0.5
@property (strong, nonatomic) NSString *lineName;//曲线名字，显示在legendView上
@property (assign, nonatomic) BOOL shouldFill;//是否将曲线的区域填充颜色，默认YES

//grid lines
@property (nonatomic) BOOL drawGridX; //x轴竖直刻度线，Default is YES
@property (nonatomic) BOOL drawGridY; //y轴水平刻度线，Default is YES

//legend
@property (nonatomic) BOOL showLegend; //Default is NO
@property (nonatomic) LegendType legendViewType; //Default is LegendTypeVertical
@property (nonatomic, strong) NSMutableArray *legendArray;//array of LegendDataRenderer
@property (nonatomic, strong) LegendView *legendView;
@property (strong, nonatomic) UIFont *legendFont;//legendView的字体，默认12号系统字体

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
@end
