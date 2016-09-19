//
//  FundKLineModel.h
//  GuPiaoTaoLi
//
//  Created by lei xue on 16/9/13.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <Foundation/Foundation.h>

//{"record":[["2016-09-13","0.895","0.900","0.890","0.883","2237514.00","0.004","0.45","0.921","0.928","0.935","2,934,615.35","2,949,930.63","3,190,901.71"],...]}
//格式，除换手率外共14项：date日期, open：开盘价, high：最高价, close：收盘价, low：最低价, volume：成交量 手, price_change：价格变动, p_change：涨跌幅, ma5：5日均价, ma10：10日均价, ma2020日均价, v_ma55日均量 手, v_ma1010日均量, v_ma2020日均量, turnover换手率(股票有换手率，指数、基金无)


@interface OneKLineModel : NSObject
@property(strong, nonatomic) NSString *dateString;
@property(assign, nonatomic) double openPrice;
@property(assign, nonatomic) double highPrice;
@property(assign, nonatomic) double closePrice;
@property(assign, nonatomic) double lowPrice;
@property(assign, nonatomic) double volume;//手
@property(assign, nonatomic) double priceChange;
@property(assign, nonatomic) double changeRate;
@property(assign, nonatomic) double ma5;//5日均价
@property(assign, nonatomic) double ma10;
@property(assign, nonatomic) double ma20;
@property(assign, nonatomic) double ma5Volume;//5日均量，手
@property(assign, nonatomic) double ma10Volume;
@property(assign, nonatomic) double ma20Volume;
@property(assign, nonatomic) double turnover;//换手率 只适用于股票，指数、基金无
@end

@interface FundKLineModel : NSObject
/**
 *  array of NSArray ["2016-09-13","0.895","0.900","0.890","0.883","2237514.00","0.004","0.45","0.921","0.928","0.935","2,934,615.35","2,949,930.63","3,190,901.71"]
 *  除换手率外共14项：[date日期, open：开盘价, high：最高价, close：收盘价, low：最低价, volume：成交量, price_change：价格变动, p_change：涨跌幅, ma5：5日均价, ma10：10日均价, ma2020日均价, v_ma55日均量, v_ma1010日均量, v_ma2020日均量, turnover换手率(股票有换手率，指数、基金无)]
 */
@property(strong, nonatomic) NSArray *record;
@property(strong, nonatomic) NSMutableArray *lineModels;//array of OneKLineModel
-(void)update;//根据record生成lineModels
@end
