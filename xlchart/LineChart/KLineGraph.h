//
//  KLineGraph.h
//  xlchart
//
//  Created by lei xue on 16/9/12.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "LineGraphBase.h"
#import "KLineGraph.h"

typedef enum{
    KLinePeriodInvalid = -1,
    KLinePeriodDaily = 0,
    KLinePeriodWeekly,
    KLinePeriodMonthly
} KLinePeriod;

@class KLineGraph;

@protocol KLineGraphDelegate <NSObject>
@optional
- (void)kLine:(KLineGraph *)graph didTapLine:(NSUInteger)lineIndex atPoint:(NSUInteger)pointIndex;
- (void)markerDidDismissInKLine:(KLineGraph *)graph;//marker消失
@end

@protocol KLineGraphDataSource <NSObject>
- (NSUInteger)numberOfLinesInkLine:(KLineGraph *)graph;//曲线数目
- (CGFloat)kLine:(KLineGraph *)graph lineWidth:(NSUInteger)lineIndex;//线宽
- (UIColor *)kLine:(KLineGraph *)graph lineColor:(NSUInteger)lineIndex;//线颜色
- (NSArray *)xAxisDataInKLine:(KLineGraph *)graph;
- (NSArray *)kLine:(KLineGraph *)graph yAxisDataForline:(NSUInteger)lineIndex;//线上点的y数据，array of NSNumber *
- (NSArray *)kLineDataInkLine:(KLineGraph *)graph;//用于初始化kLineData
//暂时不实现跳过点的功能
//- (NSUInteger)kLine:(KLineGraph *)graph skipedNumber:(NSUInteger)lineIndex;//该曲线跳过的点数
@optional
- (NSArray *)volumeDataInkLine:(KLineGraph *)graph;//成交量数据，array of NSNumber *
@end

/*股票分时图
 y轴显示三根横线，以 正负 max(fabs(最高价), fabs(最低价)) 作为y轴的最高、最低刻度值，以昨日收盘价作为y轴中间刻度值。如果 fabs(max值/昨日收盘价 - 1) < 0.01（也即涨跌幅<1%），则将max值设为昨日收盘价*1.01。价格取整3位小数，百分比取整百分数的2位小数。
 y轴右边显示价格。坐标系右边线的左侧显示涨跌幅百分百，只显示最高和最低横线的涨跌幅，不显示中间线的0%。
 x轴刻度分4段，分别为9:30， 10:30， 11:30/13:00, 14:00, 15:00。首尾刻度值显示竖直实线，刻度值显示在图内线旁边；中间3个刻度值显示竖直虚线，刻度值和线中点对齐。
 */
@interface KLineGraph : LineGraphBase
@property(assign, nonatomic) KLinePeriod kLinePeriod;
@property(weak, nonatomic) id<KLineGraphDelegate> delegate;
@property(weak, nonatomic) id<KLineGraphDataSource> dataSource;

@property(strong, nonatomic) UIColor *textUpColor; //y轴上半部上涨的颜色，默认[UIColor redColor]
@property(strong, nonatomic) UIColor *textDownColor;//y轴下半部下跌的颜色，默认[UIColor greenColor]
@property(assign, nonatomic) CGFloat maxBarWidth;//柱状图的最大宽度，默认6
@property(assign, nonatomic) double volumeHeightRatio;//成交量柱状图占整个frame的高度比例，默认0.25
@end