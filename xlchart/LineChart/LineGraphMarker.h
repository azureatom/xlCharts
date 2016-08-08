//
//  LineGraphMaker.h
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LineGraphMarker : UIView

@property (nonatomic, strong) NSString *xString;
@property (nonatomic, strong) NSString *yString;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIFont *textFont;

- (void)drawAtPoint:(CGPoint)point;

@end
