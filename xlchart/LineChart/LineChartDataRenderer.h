//
//  LineChartDataRenderer.h
//  xlchart
//
//  Created by lei xue on 16/8/8.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LineChartDataRenderer : NSObject

@property (nonatomic, strong) NSArray *yAxisArray;//点的y坐标
@property (nonatomic, strong) NSArray *xAxisArray;//点的x坐标
@property (strong, nonatomic) UIColor *lineColor;
@property (nonatomic, strong) NSString *graphName;
@property (assign, nonatomic) CGFloat lineWidth;
@property (nonatomic) BOOL drawPoints;
@property (nonatomic) BOOL fillGraph;

@end
