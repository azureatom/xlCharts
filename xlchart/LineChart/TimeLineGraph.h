//
//  TimeLineGraph.h
//  xlchart
//
//  Created by lei xue on 16/9/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>

/*股票分时图
 y轴显示三根横线，以 正负 max(fabs(最高价), fabs(最低价)) 作为y轴的最高、最低刻度值，以昨日收盘价作为y轴中间刻度值。如果 fabs(max值/昨日收盘价 - 1) < 0.02（也即涨跌幅<2%），则将max值设为昨日收盘价*1.02。价格取整3位小数，百分比取整百分数的2位小数。
 y轴右边显示价格。最右边竖线的左侧显示涨跌幅百分百，只显示最高和最低横线的涨跌幅，不显示中间线的0%。
 x轴刻度分4段，分别为9:30， 10:30， 11:30/13:00, 14:00, 15:00。首尾刻度值显示竖直实线，刻度值显示在图内线旁边；中间3个刻度值显示竖直虚线，刻度值和线中点对齐。
 */
@interface TimeLineGraph : UIView
@end
