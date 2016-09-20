//
//  SingleLineGraphNonScrollable.m
//  xlchart
//
//  Created by lei xue on 16/9/7.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "SingleLineGraphNonScrollable.h"

@implementation SingleLineGraphNonScrollable

-(BOOL)calculatePositionStepX{
    if (![super calculatePositionStepX]) {
        self.positionStepX = [self widthGraph] / (self.xAxisArray.count - 1);
    }
    return YES;
}

-(CGPoint)calculateMarker:(CGSize)viewSize originWith:(CGPoint)closestPoint{
    CGPoint markerViewOrigin;
    CGRect lineFrame = [self axisFrame];
    if (CGRectGetMaxY(lineFrame) - closestPoint.y >= viewSize.height) {
        markerViewOrigin.y = closestPoint.y;
    }
    else{
        markerViewOrigin.y = closestPoint.y - viewSize.height;
    }
    if (closestPoint.x - lineFrame.origin.x >= viewSize.width) {
        //如果lineFrame中closestPoint左边空间足够
        markerViewOrigin.x = closestPoint.x - viewSize.width;
    }
    else{
        markerViewOrigin.x = closestPoint.x;
    }
    return markerViewOrigin;
}
@end
