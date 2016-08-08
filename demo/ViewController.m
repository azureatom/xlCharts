//
//  ViewController.m
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "ViewController.h"
#import "MultiLineGraphView.h"

@interface ViewController ()<MultiLineGraphViewDataSource, MultiLineGraphViewDelegate>
@property(strong, nonatomic) UIButton *button;
@property(strong, nonatomic) MultiLineGraphView *lineGraphView;
@end

@implementation ViewController
@synthesize button;
@synthesize lineGraphView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 50, 100, 20);
    [button setTitle:@"切换曲线数据" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:10];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.tag = 15;
    [button addTarget:self action:@selector(onButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    [self createLineGraph];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)onButtonTapped:(UIButton *)b{
    b.tag++;
    [lineGraphView reloadGraph];
}

- (void)createLineGraph{
//    self.automaticallyAdjustsScrollViewInsets = NO;
    lineGraphView = [[MultiLineGraphView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 400)];
    lineGraphView.delegate = self;
    lineGraphView.dataSource = self;
    lineGraphView.showLegend = YES;
    lineGraphView.legendViewType = LegendTypeHorizontal;
    
    lineGraphView.drawGridX = NO;
    lineGraphView.drawGridY = YES;
    lineGraphView.gridLineColor = [UIColor lightGrayColor];
    lineGraphView.gridLineWidth = 0.3;
    
    [lineGraphView setTextColor:[UIColor blackColor]];
    [lineGraphView setTextFont:[UIFont systemFontOfSize:12]];
    
    lineGraphView.enablePinch = NO;
    lineGraphView.showMarker = NO;
    lineGraphView.showCustomMarkerView = YES;
    
    
    lineGraphView.minPositionStepX = 30;
    lineGraphView.segmentsOfYAxis = 5;
    lineGraphView.customMinValidY = -100;//只有估值仓位设定范围，其它都用默认的最大最小值
    lineGraphView.customMaxValidY = 200;
    lineGraphView.presion = 2;
    
    [lineGraphView reloadGraph];
    [self.view addSubview:lineGraphView];
}

#pragma mark MultiLineGraphViewDataSource
- (NSArray *)xDataForLineToBePlotted{
    switch (button.tag) {
        case 0:
            return @[];
        case 1:
            return @[@"只有一个点时不显示x轴"];
        case 2:
            return @[@"1", @"2"];
        case 3:
            return @[@"1", @"2", @"3"];
        case 4:
            return @[@"1", @"", @"", @"4"];
        case 5:
            return @[@"1", @"", @"", @"", @"5"];
        case 6:
            return @[@"1", @"2", @"3", @"4", @"5", @"6"];
        case 7:
            return @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10"];
        case 8:
            return @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22", @"23", @"24", @"25", @"26", @"27", @"28", @"29", @"30"];
        case 9:
            return @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22", @"23", @"24", @"25", @"26", @"27", @"28", @"29", @"30", @"31", @"32", @"33", @"34", @"35", @"36", @"37", @"38", @"39", @"40"];
        case 10:
            return @[@"10", @"11", @"12", @"13"];
        case 11:
            return @[@"10", @"11", @"12", @"13"];
        case 12:
            return @[@"10", @"11", @"12", @"13"];
        case 13:
            return @[@"10", @"11", @"12", @"13", @"14"];
        case 14:
            return @[@"10", @"11", @"12", @"13", @"14"];
            
        case 15:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4"];
        case 16:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4"];
        case 17:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4"];
        case 18:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4"];
        case 19:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4"];
        case 20:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4"];
        case 21:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4"];
        case 22:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4", @"x5", @"x6", @"x7", @"x8", @"x9"];
        case 23:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4", @"x5", @"x6", @"x7", @"x8", @"x9"];
        case 24:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4", @"x5", @"x6", @"x7", @"x8", @"x9"];
        case 25:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4", @"x5", @"x6", @"x7", @"x8", @"x9"];
        case 26:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4", @"x5", @"x6", @"x7", @"x8", @"x9"];
        case 27:
            return @[@"原点x", @"x1", @"x2", @"x3", @"x4", @"x5", @"x6", @"x7", @"x8", @"x9"];
        default:
            button.tag = 0;
            return [self xDataForLineToBePlotted];
    }
}

- (NSInteger)numberOfLinesToBePlotted{
    return 1;
}

- (UIColor *)colorForTheLineWithLineNumber:(NSInteger)lineNumber{
    return [UIColor blueColor];
}

- (CGFloat)widthForTheLineWithLineNumber:(NSInteger)lineNumber{
    return 1;
}

- (NSString *)nameForTheLineWithLineNumber:(NSInteger)lineNumber{
    return @"A折价率";
}

- (BOOL)shouldFillGraphWithLineNumber:(NSInteger)lineNumber{
    return NO;
}

- (BOOL)shouldDrawPointsWithLineNumber:(NSInteger)lineNumber{
    return YES;
}

- (NSArray *)dataForLineWithLineNumber:(NSInteger)lineNumber{
    switch (button.tag) {
        case 0:
            return @[];
        case 1:
            return @[@12];
        case 2:
            return @[@-1212, @131130];
        case 3:
            return @[@(1000), @(2000), @(3000)];//@[@(lineGraphView.customMinValidY), @(lineGraphView.customMinValidY + 1), @(lineGraphView.customMaxValidY)];
        case 4:
            return @[@(lineGraphView.customMinValidY), @(lineGraphView.customMinValidY + 1), @(lineGraphView.customMaxValidY - 2), @(lineGraphView.customMaxValidY - 1)];
        case 5:
            return @[@(lineGraphView.customMinValidY), @(lineGraphView.customMinValidY + 1), @(lineGraphView.customMaxValidY), @(lineGraphView.customMaxValidY + 1)];
        case 6:
            return @[@(lineGraphView.customMinValidY - 1), @(lineGraphView.customMinValidY + 1), @(lineGraphView.customMaxValidY - 1), @(lineGraphView.customMaxValidY), @(lineGraphView.customMaxValidY)];
        case 7:
            return @[@(lineGraphView.customMinValidY + 1), @(lineGraphView.customMinValidY + 1), @(lineGraphView.customMaxValidY - 1), @(lineGraphView.customMaxValidY), @(lineGraphView.customMaxValidY)];
        case 8:
            return @[@(lineGraphView.customMinValidY+ 2), @(lineGraphView.customMinValidY + 3), @(lineGraphView.customMaxValidY - 4), @(lineGraphView.customMaxValidY), @(lineGraphView.customMaxValidY - 3), @(lineGraphView.customMaxValidY - 2), @(lineGraphView.customMaxValidY - 1)];
        case 9:
            return @[@(lineGraphView.customMinValidY - 2), @(lineGraphView.customMinValidY-1), @(lineGraphView.customMinValidY), @(lineGraphView.customMinValidY), @(lineGraphView.customMaxValidY - 1), @(lineGraphView.customMaxValidY), @(lineGraphView.customMaxValidY + 1), @(lineGraphView.customMaxValidY + 2), @(lineGraphView.customMaxValidY + 2)];
        case 10:
            return @[@(lineGraphView.customMinValidY - 4), @(lineGraphView.customMinValidY-3), @(lineGraphView.customMinValidY-10)];
        case 11:
            return @[@(lineGraphView.customMaxValidY + 1), @(lineGraphView.customMaxValidY + 2), @(lineGraphView.customMaxValidY + 3)];
        case 12:
            return @[@(lineGraphView.customMinValidY - 4), @(lineGraphView.customMinValidY-300), @(lineGraphView.customMinValidY-1000)];
        case 13:
            return @[@(lineGraphView.customMaxValidY + 1), @(lineGraphView.customMaxValidY + 200), @(lineGraphView.customMaxValidY + 3000)];
        case 14:
            return @[@(lineGraphView.customMaxValidY + 1), @(lineGraphView.customMaxValidY + 100), @(lineGraphView.customMaxValidY + 120), @(lineGraphView.customMaxValidY + 200), @(lineGraphView.customMaxValidY + 3000)];
            
            
        case 15:
            return @[@300, @300, @200, @-100, @-100];
        case 16:
            return @[@300, @300, @200, @-100, @-100];
            return @[@330, @300, @200, @-80, @-100];
        case 17:
            return @[@420, @300, @200, @-80, @-100];
        case 18:
            return @[@500, @300, @200, @-80, @-100];
        case 19:
            return @[@200, @200, @-50, @-200, @-220];
        case 20:
            return @[@200, @200, @-50, @-200, @-330];
        case 21:
            return @[@300, @200, @-50, @-100, @-1000];
        case 22:
            return @[@450, @300, @250, @210, @200, @150, @100, @-250, @-300, @-1000];
        case 23:
            return @[@520, @300, @250, @210, @200, @150, @100, @-250, @-300, @-1000];
        case 24:
            return @[@700, @300, @250, @210, @200, @150, @100, @-250, @-300, @-1000];
        case 25:
            return @[@1000, @300, @250, @210, @200, @150, @100, @-250, @-300, @-380];
        case 26:
            return @[@1000, @300, @250, @210, @200, @150, @100, @-250, @-300, @-520];
        case 27:
            return @[@1000, @300, @250, @210, @200, @150, @100, @-250, @-300, @-700];
        default:
            button.tag = 0;
            return [self dataForLineWithLineNumber:lineNumber];
    }
}

- (UIView *)customViewForLineChartTouchWithXValue:(NSString *)xValue andYValue:(NSString *)yValue{
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor whiteColor]];
    [view.layer setCornerRadius:4.0F];
    [view.layer setBorderWidth:1.0F];
    [view.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [view.layer setShadowColor:[[UIColor blackColor] CGColor]];
    [view.layer setShadowRadius:2.0F];
    [view.layer setShadowOpacity:0.3F];
    
    UILabel *label = [[UILabel alloc] init];
    [label setFont:[UIFont systemFontOfSize:12]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setText:[NSString stringWithFormat:@"日期Line Data: %@", yValue]];
    [label setFrame:CGRectMake(0, 0, 100, 30)];
    [view addSubview:label];
    
    [view setFrame:label.frame];
    return view;
}

#pragma mark MultiLineGraphViewDelegate
- (void)didTapWithValuesAtX:(NSString *)xValue valuesAtY:(NSString *)yValue{
    NSLog(@"Line Chart: Value-X:%@, Value-Y:%@",xValue, yValue);
}
@end
