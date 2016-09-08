//
//  Tool.h
//  xlchart
//
//  Created by lei xue on 16/9/8.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Tool : NSObject
+ (CAShapeLayer *)layerDashedFrom:(CGPoint)from to:(CGPoint)to dashHeight:(CGFloat)dashHeight dashLength:(int)dashLength spaceLength:(int)spaceLength dashColor:(UIColor *)color;
@end
