//
//  LineChartDataRenderer.m
//  xlchart
//
//  Created by lei xue on 16/8/8.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "LineChartDataRenderer.h"

@implementation LineChartDataRenderer
- (instancetype)init{
    self = [super init];
    if (self) {
        self.lineWidth = 1.0f;
        self.lineColor = [UIColor blackColor];
        self.graphName = @"";
        self.drawPoints = FALSE;
        self.fillGraph = FALSE;
    }
    return self;
}
@end
