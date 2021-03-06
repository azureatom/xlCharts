//
//  LineGraphMaker.m
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "LineGraphMarker.h"

@interface LineGraphMarker()
@property (nonatomic, strong) UILabel *markerLabel;
@end

@implementation LineGraphMarker

- (instancetype)init{
    self = [super init];
    if (self) {
        self.markerLabel = [[UILabel alloc] init];
        [self addSubview:self.markerLabel];
    }
    return self;
}

- (void)drawAtPoint:(CGPoint)point{
    [self setBackgroundColor:self.bgColor];

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    NSString *string = [NSString stringWithFormat:@"%@, %@ ", self.yString, self.xString];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:string];
    
    [attrString addAttributes:@{NSFontAttributeName:self.textFont , NSKernAttributeName : @(0.5), NSParagraphStyleAttributeName:paragraphStyle}
                        range:NSMakeRange(0, string.length)];
    
    [self.markerLabel setAttributedText:attrString];
    [self.markerLabel setTextColor:self.textColor];
    
    CGFloat height = MAXFLOAT;
    CGFloat width = MAXFLOAT;
    
    CGSize size = [attrString boundingRectWithSize:CGSizeMake(width, height) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    
    [self.markerLabel setFrame:CGRectMake(5, 5, size.width, size.height)];
    
    CGFloat x = point.x - (self.markerLabel.frame.size.width + 10)/2;
//    if (x < 0) {
//        x = point.x;
//    }
//    else if(x + (self.markerLabel.frame.size.width + 10) > [UIScreen mainScreen].bounds.size.width){
//        x = point.x - (self.markerLabel.frame.size.width + 10);
//    }
    
    [self setFrame:CGRectMake(x, point.y - (self.markerLabel.frame.size.height + 10), self.markerLabel.frame.size.width + 10, self.markerLabel.frame.size.height + 10)];
}

@end