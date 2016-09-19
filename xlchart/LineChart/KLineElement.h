//
//  KLineElement.h
//  xlchart
//
//  Created by lei xue on 16/9/19.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KLineElement : NSObject
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
