//
//  LegendView.m
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "LegendView.h"

static const CGFloat kLegendInnerPadding = 10;
static const CGFloat kLegendOffsetPadding = 5;
static const CGFloat kLegendWidth = 15;

@implementation LegendView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.legendArray = [[NSMutableArray alloc] init];
        self.font = [UIFont systemFontOfSize:12];
    }
    return self;
}

- (void)createLegend{
    CGFloat height = kLegendInnerPadding;
    if (self.legendViewType == LegendTypeVertical) {
        for (LegendDataRenderer *legendData in self.legendArray){
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, height, kLegendWidth, kLegendWidth)];
            [view setBackgroundColor:legendData.legendColor];
            [self addSubview:view];
            
            NSAttributedString *attrString = [LegendView getAttributedString:legendData.legendText withFont:self.font];
            CGSize size = [attrString boundingRectWithSize:CGSizeMake(self.frame.size.width - view.frame.size.width, MAXFLOAT) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
            
            UILabel *label = [[UILabel alloc] init];
            [label setNumberOfLines:0];
            [label setTextColor:self.textColor];
            [label setAttributedText:attrString];
            [label setFrame:CGRectMake(CGRectGetMaxX(view.frame) + kLegendOffsetPadding, height, self.frame.size.width - view.frame.size.width, size.height)];
            [self addSubview:label];
            
            if (size.height > kLegendWidth) {
                height = height + size.height + kLegendInnerPadding;
                
            }
            else{
                height = height + kLegendWidth + kLegendInnerPadding;
            }
        }
        
        CGRect frame = self.frame;
        frame.size.height = height;
        [self setFrame:frame];
    }
    else if (self.legendViewType == LegendTypeHorizontal){
        CGFloat width = 0;
        CGFloat x = 0;
        
        for (LegendDataRenderer *legendData in self.legendArray){
            NSAttributedString *attrString = [LegendView getAttributedString:legendData.legendText withFont:self.font];
            CGSize size = [attrString boundingRectWithSize:CGSizeMake(self.frame.size.width - kLegendWidth, MAXFLOAT) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;

            width += kLegendWidth + size.width + kLegendInnerPadding + kLegendOffsetPadding;
            
            if (width >= self.frame.size.width) {
                height += kLegendWidth + kLegendInnerPadding;
                width = kLegendWidth + size.width + kLegendInnerPadding + kLegendOffsetPadding;
                x = 0;
            }
            
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, height, kLegendWidth, kLegendWidth)];
            [view setBackgroundColor:legendData.legendColor];
            [self addSubview:view];
            
            UILabel *label = [[UILabel alloc] init];
            [label setNumberOfLines:0];
            [label setTextColor:self.textColor];
            [label setAttributedText:attrString];
            [label setFrame:CGRectMake(CGRectGetMaxX(view.frame) + kLegendOffsetPadding, height, size.width, size.height)];
            [self addSubview:label];
            
            x = width;
        }
        height += kLegendWidth + kLegendInnerPadding;

        CGRect frame = self.frame;
        frame.size.height = height;
        [self setFrame:frame];
    }
    
}

+ (NSMutableAttributedString *)getAttributedString:(NSString *)tinyText withFont:(UIFont *)font {
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:tinyText];
    
    [attrString addAttributes:@{NSFontAttributeName:font}
                        range:NSMakeRange(0, tinyText.length)];
    
    return  attrString;
}

+ (CGFloat)getLegendHeightWithLegendArray:(NSMutableArray *)legendArray legendType:(LegendType)type withFont:(UIFont *)font width:(CGFloat)viewWidth{
    CGFloat height = 0;
    height += kLegendInnerPadding;
    
    if (type == LegendTypeVertical) {
        for (LegendDataRenderer *legendData in legendArray){
            NSAttributedString *attrString = [LegendView getAttributedString:legendData.legendText withFont:font];
            CGSize size = [attrString boundingRectWithSize:CGSizeMake(viewWidth - kLegendWidth, MAXFLOAT) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;

            if (size.height > kLegendWidth) {
                height = height + size.height + kLegendInnerPadding;

            }
            else{
                height = height + kLegendWidth + kLegendInnerPadding;
            }
        }
    }
    else if (type == LegendTypeHorizontal){
        CGFloat width = 0;
        CGFloat x = 0;
        
        for (LegendDataRenderer *legendData in legendArray){
            NSAttributedString *attrString = [LegendView getAttributedString:legendData.legendText withFont:font];
            CGSize size = [attrString boundingRectWithSize:CGSizeMake(viewWidth - kLegendWidth, MAXFLOAT) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
            
            x = width;
            width += kLegendWidth + size.width + kLegendInnerPadding + kLegendOffsetPadding;
            
            if (width >= viewWidth) {
                height = height + kLegendWidth + kLegendInnerPadding;
                width = kLegendWidth + size.width + kLegendInnerPadding + kLegendOffsetPadding;
                x = 0;
            }
        }
        height += kLegendWidth + kLegendInnerPadding;
    }
    return height;
}

@end

@implementation LegendDataRenderer

@end