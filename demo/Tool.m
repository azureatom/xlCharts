//
//  Tool.m
//  xlchart
//
//  Created by lei xue on 16/9/8.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "Tool.h"

@implementation Tool
+ (CAShapeLayer *)layerLineFrom:(CGPoint)from to:(CGPoint)to width:(CGFloat)lineWidth color:(UIColor *)color{
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.strokeColor = color.CGColor;
    shapeLayer.lineWidth = lineWidth;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, from.x, from.y);
    CGPathAddLineToPoint(path, NULL, to.x, to.y);
    shapeLayer.path = path;
    CGPathRelease(path);
    return shapeLayer;
}

+ (CAShapeLayer *)layerDashedFrom:(CGPoint)from to:(CGPoint)to dashHeight:(CGFloat)dashHeight dashLength:(int)dashLength spaceLength:(int)spaceLength dashColor:(UIColor *)color{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    //设置虚线颜色为blackColor
    shapeLayer.strokeColor = color.CGColor;
    //设置虚线宽度
    shapeLayer.lineWidth = dashHeight;
    shapeLayer.lineJoin = kCALineJoinRound;
    //设置线宽，线间距
    shapeLayer.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInt:dashLength], [NSNumber numberWithInt:spaceLength], nil];
    //设置路径
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, from.x, from.y);
    CGPathAddLineToPoint(path, NULL, to.x, to.y);
    shapeLayer.path = path;
    CGPathRelease(path);
    return shapeLayer;
}
@end
