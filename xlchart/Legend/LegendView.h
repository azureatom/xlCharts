//
//  LegendView.h
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LegendDataRenderer;

typedef enum{
    LegendTypeVertical = 0,
    LegendTypeHorizontal
}LegendType;

@interface LegendView : UIView

@property (nonatomic, strong) NSMutableArray *legendArray;

@property (nonatomic) LegendType legendViewType;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIFont *font;

- (void)createLegend;

+ (CGFloat)getLegendHeightWithLegendArray:(NSMutableArray *)legendArray legendType:(LegendType)type withFont:(UIFont *)font width:(CGFloat)viewWidth;

+ (NSMutableAttributedString *)getAttributedString:(NSString *)tinyText withFont:(UIFont *)font;

@end

@interface LegendDataRenderer : NSObject

@property (nonatomic, strong) UIColor *legendColor;
@property (nonatomic, strong) NSString *legendText;

@end