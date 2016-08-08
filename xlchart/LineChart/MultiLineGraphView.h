//
//  MultiLineGraphView.h
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LegendView.h"

typedef enum {
    LineParallelXAxis,
    LineParallelYAxis,
    LineDefault
}LineDrawingType;

@protocol MultiLineGraphViewDelegate  <NSObject>
- (void)didTapWithValuesAtX:(NSString *)xValue valuesAtY:(NSString *)yValue;
//Returns, the touched point values
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

- (LineDrawingType)typeOfLineToBeDrawnWithLineNumber:(NSInteger)lineNumber;
//Set Line Type for each for Line on the Line Graph
//Default is LineDefault

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
//Set yData for Line on Line Graph When Line Type is LineDefault & LineParallelXAxis
//If LineType is LineParallelYAxis, Set xData for the Line on Line Graph

@optional
- (UIView *)customViewForLineChartTouchWithXValue:(NSString *)xValue andYValue:(NSString *)yValue;
//Set Custom View for touch on each item in a Line Chart
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
@property (nonatomic) BOOL showMarker; //Default is TRUE
//show CUSTOM MARKER when interacting with graph.
//If Both MARKER and CUSTOM MARKER view are True then CUSTOM MARKER View Priorties over MARKER View.
@property (nonatomic) BOOL showCustomMarkerView; //Default is FALSE
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
