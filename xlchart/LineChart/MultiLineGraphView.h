//
//  MultiLineGraphView.h
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LegendView.h"

@protocol MultiLineGraphViewDelegate  <NSObject>
/**
 *  点击点的index和y值
 *
 *  @param pointIndex 是第几个点，也即x轴的第几个刻度值
 *  @param yValue 点击点对应的y值
 */
- (void)didTapPoint:(NSUInteger)pointIndex valuesAtY:(NSNumber *)yValue;
@end

@protocol MultiLineGraphViewDataSource  <NSObject>
/**
 *  Set data for x-Axis for the Line Graph
 *
 *  @return array of NSString, only draw x-axis if string is not empty, that is exclude @""
 */
- (NSArray *)xDataForLineToBePlotted;

- (NSInteger)numberOfLinesToBePlotted;
//Set number of lines to be plotted on the Line Graph

- (UIColor *)colorForTheLineWithLineNumber:(NSInteger)lineNumber;
//Set Line Color for each for Line on the Line Graph
//Default is Black Color

- (CGFloat)widthForTheLineWithLineNumber:(NSInteger)lineNumber;
//Set Line Width for each for Line on the Line Graph
//Default is 1.0F

- (NSString *)nameForTheLineWithLineNumber:(NSInteger)lineNumber;
//Set Line Name for each for Line on the Line Graph
//Default is Empty String

- (BOOL)shouldFillGraphWithLineNumber:(NSInteger)lineNumber;
//Set Fill Property for each for Line on the Line Graph
//Default is False

- (BOOL)shouldDrawPointsWithLineNumber:(NSInteger)lineNumber;
//Set Draw Points Property for each for Line on the Line Graph
//Default is False

- (NSArray *)dataForLineWithLineNumber:(NSInteger)lineNumber;
//Set yData for Line on Line Graph

@optional
- (UIView *)customViewForPoint:(NSUInteger)pointIndex andYValue:(NSNumber *)yValue;
@end

@interface MultiLineGraphView : UIView
@property (weak, nonatomic) id<MultiLineGraphViewDelegate> delegate;
@property (weak, nonatomic) id<MultiLineGraphViewDataSource> dataSource;
//set FONT property for the graph
@property (nonatomic, strong) UIFont *textFont; //Default is [UIFont systemFontOfSize:12];
@property (nonatomic, strong) UIColor *textColor; //Default is [UIColor blackColor]

//show Grid with the graph
@property (nonatomic) BOOL drawGridX; //x轴竖直刻度线，Default is TRUE
@property (nonatomic) BOOL drawGridY; //y轴水平刻度线，Default is TRUE
//set property for the grid
@property (nonatomic, strong) UIColor *gridLineColor; //Default is [UIColor lightGrayColor]
@property (nonatomic) CGFloat gridLineWidth; //Default is 0.3F

@property (assign, nonatomic) BOOL enablePinch;//是否支持pinch手势放大缩小

//show MARKER when interacting with graph
@property (nonatomic) BOOL showMarker; //是否显示十字线和默认的提示框，提示框默认显示在坐标系的上方，Default is YES
//show CUSTOM MARKER when interacting with graph.
//If Both MARKER and CUSTOM MARKER view are True then CUSTOM MARKER View Priorties over MARKER View.
@property (nonatomic) BOOL showCustomMarkerView; //是否显示自定义提示框，Default is NO
//to set marker property
@property (nonatomic, strong) UIColor *markerColor; //Default is [UIColor orangeColor]
@property (nonatomic, strong) UIColor *markerTextColor; //Default is [UIColor whiteColor]
@property (nonatomic) CGFloat markerWidth; //Default is 0.4F

//show LEGEND with the graph
@property (nonatomic) BOOL showLegend; //Default is TRUE
//Set LEGEND TYPE Horizontal or Vertical
@property (nonatomic) LegendType legendViewType; //Default is LegendTypeVertical i.e. VERTICAL

@property (assign, nonatomic) CGFloat minPositionStepX;//默认30.用户自定义相邻点的x方向距离，用于设置positionStepX。如果所有点的x方向距离之和不能占满横向区域，则实际距离positionStepX会采用恰好占满的值
@property (assign, nonatomic) NSUInteger segmentsOfYAxis;//即y轴分段数，也等于除x轴外的横线数目，默认为5，必须>=2
/**
 *  用户定义的y轴坐标的最大值和最小值。
 *  如果所有的y值的范围可以包含在customMaxValidY-customMinValidY范围内，则所有的y都显示；
 *  否则，找到差值为customMaxValidY - customMinValidY内的最多的点，精确显示这些点的位置，其他点在曲线上粗略显示
 */
@property (assign, nonatomic) CGFloat customMaxValidY;//default is MAXFLOAT / 4，这样 customMaxValidY - customMinValidY的值就不会超过MAXFLOAT
@property (assign, nonatomic) CGFloat customMinValidY;//default is -MAXFLOAT / 4
@property (assign, nonatomic) NSUInteger presion;//小数点后几位小数

//To reload data on the graph
- (void)reloadGraph;
@end
