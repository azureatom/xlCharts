//
//  TimeLineGraph.h
//  xlchart
//
//  Created by lei xue on 16/9/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LineGraphBase.h"

static const int kMaxMinutesInTimeLine = 242;//最多显示242个分钟线，但是分时图的最后一个刻度值对应的是15:01，也即会有243个刻度值，尽管15:01没有分钟线数据
static const double kVolumeHeightRatio = 0.25;//如果显示成交量柱状图，则占整个frame的高度比例

@class TimeLineGraph;

@protocol TimeLineGraphDelegate <NSObject>
@optional
- (void)timeLine:(TimeLineGraph *)timeLineGraph didTapLine:(NSUInteger)lineIndex atPoint:(NSUInteger)pointIndex;
- (void)markerDidDismissInTimeLine:(TimeLineGraph *)timeLineGraph;//marker消失
@end

@protocol TimeLineGraphDataSource <NSObject>
- (NSUInteger)numberOfLinesInTimeLine:(TimeLineGraph *)timeLineGraph;//曲线数目
- (CGFloat)timeLine:(TimeLineGraph *)timeLineGraph lineWidth:(NSUInteger)lineIndex;//线宽
- (UIColor *)timeLine:(TimeLineGraph *)timeLineGraph lineColor:(NSUInteger)lineIndex;//线颜色
- (NSArray *)timeLine:(TimeLineGraph *)timeLineGraph yAxisDataForline:(NSUInteger)lineIndex;//线上点的y数据，array of NSNumber *
@optional
- (NSArray *)volumeDataInTimeLine:(TimeLineGraph *)timeLineGraph;//成交量数据，array of NSNumber *
@end

/*股票分时图
 y轴显示三根横线，以 正负 max(fabs(最高价), fabs(最低价)) 作为y轴的最高、最低刻度值，以昨日收盘价作为y轴中间刻度值。如果 fabs(max值/昨日收盘价 - 1) < 0.02（也即涨跌幅<2%），则将max值设为昨日收盘价*1.02。价格取整3位小数，百分比取整百分数的2位小数。
 y轴右边显示价格。坐标系右边线的左侧显示涨跌幅百分百，只显示最高和最低横线的涨跌幅，不显示中间线的0%。
 x轴刻度分4段，分别为9:30， 10:30， 11:30/13:00, 14:00, 15:00。首尾刻度值显示竖直实线，刻度值显示在图内线旁边；中间3个刻度值显示竖直虚线，刻度值和线中点对齐。
 */
@interface TimeLineGraph : LineGraphBase
@property(weak, nonatomic) id<TimeLineGraphDelegate> delegate;
@property(weak, nonatomic) id<TimeLineGraphDataSource> dataSource;

@property(assign, nonatomic) double yesterdayClosePrice;//昨日收盘价，默认0，此时涨跌幅显示为"0.00%"
@property(assign, nonatomic) double minPriceChangePercent;//价格偏离昨日收盘价的最小百分比，默认0.01，也即[-1.00%, 1.00%]

@property(strong, nonatomic) UIColor *textUpColor; //y轴上半部上涨的颜色，默认[UIColor redColor]
@property(strong, nonatomic) UIColor *textDownColor;//y轴下半部下跌的颜色，默认[UIColor greenColor]
@property(strong, nonatomic) UIColor *volumeColor;//柱状图颜色
@end
