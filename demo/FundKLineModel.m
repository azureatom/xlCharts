//
//  FundKLineModel.m
//  GuPiaoTaoLi
//
//  Created by lei xue on 16/9/13.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "FundKLineModel.h"

@implementation OneKLineModel
@synthesize dateString;
@synthesize openPrice;
@synthesize highPrice;
@synthesize closePrice;
@synthesize lowPrice;
@synthesize volume;
@synthesize priceChange;
@synthesize changeRate;
@synthesize ma5;
@synthesize ma10;
@synthesize ma20;
@synthesize ma5Volume;
@synthesize ma10Volume;
@synthesize ma20Volume;
@synthesize turnover;
@end

@implementation FundKLineModel
@synthesize record;
@synthesize lineModels;//array of KLineOne

-(void)update{
    static NSNumberFormatter *s_formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_formatter = [[NSNumberFormatter alloc] init];
        s_formatter.numberStyle = NSNumberFormatterDecimalStyle;
        s_formatter.usesGroupingSeparator = YES;
        s_formatter.groupingSeparator = @",";
        s_formatter.groupingSize = 3;//每千位逗号分隔
        s_formatter.roundingMode = NSNumberFormatterRoundHalfUp;//四舍五入
        s_formatter.minimumFractionDigits = 2;
        s_formatter.maximumFractionDigits = 2;
        s_formatter.alwaysShowsDecimalSeparator = NO;//是否总显示小数点号，如1.0显示为1.而12显示为12.
    });
    
    lineModels = [[NSMutableArray alloc] initWithCapacity:record.count];
    for (NSArray *array in record) {
        OneKLineModel *oneModel = [[OneKLineModel alloc] init];
        oneModel.dateString = array[0];
        oneModel.openPrice = ((NSString *)array[1]).doubleValue;
        oneModel.highPrice = ((NSString *)array[2]).doubleValue;
        oneModel.closePrice = ((NSString *)array[3]).doubleValue;
        oneModel.lowPrice = ((NSString *)array[4]).doubleValue;
        oneModel.volume = ((NSString *)array[5]).doubleValue;
        oneModel.priceChange = ((NSString *)array[6]).doubleValue;
        oneModel.changeRate = ((NSString *)array[7]).doubleValue;
        oneModel.ma5 = ((NSString *)array[8]).doubleValue;
        oneModel.ma10 = ((NSString *)array[9]).doubleValue;
        oneModel.ma20 = ((NSString *)array[10]).doubleValue;
        oneModel.ma5Volume = [s_formatter numberFromString:array[11]].doubleValue;
        oneModel.ma10Volume = [s_formatter numberFromString:array[12]].doubleValue;
        oneModel.ma20Volume = [s_formatter numberFromString:array[13]].doubleValue;
//        oneModel.turnover = ((NSString *)array[14]).doubleValue;
        [lineModels addObject:oneModel];
    }
}
@end
