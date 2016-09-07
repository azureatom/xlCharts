//
//  ViewController.m
//  xlchart
//
//  Created by lei xue on 16/8/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "ViewController.h"
#import "SingleLineGraphScrollable.h"
#import "SingleLineGraphNonScrollable.h"

@interface ViewController ()<SingleLineGraphBaseDataSource, SingleLineGraphBaseDelegate>
@property(strong, nonatomic) UIButton *button;
@property(strong, nonatomic) SingleLineGraphScrollable *lineGraphScrollable;
@property(strong, nonatomic) SingleLineGraphNonScrollable *lineGraphNonScrollable;
@end

@implementation ViewController
@synthesize button;
@synthesize lineGraphScrollable;
@synthesize lineGraphNonScrollable;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 50, 100, 20);
    [button setTitle:@"切换曲线数据" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:10];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.tag = 30;
    [button addTarget:self action:@selector(onButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    [self createLineGraph];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)onButtonTapped:(UIButton *)b{
    NSLog(@"button.tag %zi", b.tag);
    [lineGraphScrollable reloadGraph];
    [lineGraphNonScrollable reloadGraph];
    b.tag++;
}

- (void)createLineGraph{
//    self.automaticallyAdjustsScrollViewInsets = NO;
    lineGraphScrollable = [[SingleLineGraphScrollable alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 200)];
    lineGraphScrollable.minPositionStepX = 30;
    
    lineGraphNonScrollable = [[SingleLineGraphNonScrollable alloc] initWithFrame:CGRectMake(0, 300, self.view.frame.size.width, 200)];
    lineGraphNonScrollable.enablePanAndLongPress = YES;
    
    for (SingleLineGraphBase *lg in @[lineGraphScrollable, lineGraphNonScrollable]) {
        lg.lineColor = [UIColor blueColor];
        lg.lineWidth = 1;
        lg.lineName = @"A折价率";
        lg.shouldFill = YES;
        lg.shouldDrawPoints = YES;
        lg.maxPointRadius = 1.5;
        
        lg.delegate = self;
        lg.dataSource = self;
        lg.fractionDigits = 2;
        
        [lg setTextColor:[UIColor blackColor]];
        lg.axisFont = [UIFont systemFontOfSize:12];
        
        lg.drawGridX = NO;
        lg.drawGridY = YES;
        lg.gridLineColor = [UIColor lightGrayColor];
        lg.gridLineWidth = 0.3;
        
        lg.showMarker = YES;
        lg.markerColor = [UIColor orangeColor];
        lg.markerWidth = 0.4;
        
        lg.showLegend = YES;
        lg.legendViewType = LegendTypeHorizontal;
        
        lg.spaceBetweenVisibleXLabels = 60;
        lg.segmentsOfYAxis = 5;
        lg.customMinValidY = -100;//只有估值仓位设定范围，其它都用默认的最大最小值
        lg.customMaxValidY = 200;
        lg.filterYOutOfRange = YES;
        
        [lg reloadGraph];
        [self.view addSubview:lg];
    }
}

#pragma mark SingleLineGraphBaseDataSource
- (NSArray *)xAxisDataForLine:(SingleLineGraphBase *)graph filtered:(NSArray *)filteredIndexArray{
    NSMutableArray *dateStringArray = [NSMutableArray new];
    for (int i = 0; i < ((NSNumber *)filteredIndexArray.lastObject).intValue + 1; ++i) {
        [dateStringArray addObject:[NSString stringWithFormat:@"%d", i]];
    }
    if (filteredIndexArray != nil) {
        NSMutableArray *filteredDateStringArray = [NSMutableArray new];
        for (NSNumber *index in filteredIndexArray) {
            [filteredDateStringArray addObject:dateStringArray[index.intValue]];
        }
//        return filteredDateStringArray;
    }
    
    switch (button.tag) {
        case 0:
            return @[];
        case 1:
            return @[@"只有一个点时显示无刻度的x轴"];
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
        
        case 28:
            return @[@"原点x", @"1", @"2", @"3", @"4", @"5", @"", @"", @"", @"9"];
        case 29:
            return @[@"原点x", @"1", @"2", @"3", @"4", @"5", @"", @"", @"", @"9", @"10", @"1", @"2", @"3", @"4", @"5", @"", @"", @"", @"9", @"20"];
        case 30:
            return @[@"原点x", @"1", @"2", @"3", @"4", @"5", @"", @"", @"", @"9"];
        case 31:
            return @[@"原点x", @"1", @"2", @"3", @"4", @"5", @"", @"", @"", @"9", @"10", @"1", @"2", @"3", @"4", @"5", @"", @"", @"", @"9", @"20"];
        default:
            button.tag = 0;
            return [self xAxisDataForLine:graph filtered:filteredIndexArray];
    }
}

- (NSArray *)yAxisDataForline:(SingleLineGraphBase *)graph{
    switch (button.tag) {
        case 0:
            return @[];
        case 1:
            return @[@12];
        case 2:
            return @[@-1212, @131130];
        case 3:
            return @[@(1000), @(2000), @(3000)];//@[@(lineGraphScrollable.customMinValidY), @(lineGraphScrollable.customMinValidY + 1), @(lineGraphScrollable.customMaxValidY)];
        case 4:
            return @[@(lineGraphScrollable.customMinValidY), @(lineGraphScrollable.customMinValidY + 1), @(lineGraphScrollable.customMaxValidY - 2), @(lineGraphScrollable.customMaxValidY - 1)];
        case 5:
            return @[@(lineGraphScrollable.customMinValidY), @(lineGraphScrollable.customMinValidY + 1), @(lineGraphScrollable.customMaxValidY), @(lineGraphScrollable.customMaxValidY + 1)];
        case 6:
            return @[@(lineGraphScrollable.customMinValidY - 1), @(lineGraphScrollable.customMinValidY + 1), @(lineGraphScrollable.customMaxValidY - 1), @(lineGraphScrollable.customMaxValidY), @(lineGraphScrollable.customMaxValidY)];
        case 7:
            return @[@(lineGraphScrollable.customMinValidY + 1), @(lineGraphScrollable.customMinValidY + 1), @(lineGraphScrollable.customMaxValidY - 1), @(lineGraphScrollable.customMaxValidY), @(lineGraphScrollable.customMaxValidY)];
        case 8:
            return @[@(lineGraphScrollable.customMinValidY+ 2), @(lineGraphScrollable.customMinValidY + 3), @(lineGraphScrollable.customMaxValidY - 4), @(lineGraphScrollable.customMaxValidY), @(lineGraphScrollable.customMaxValidY - 3), @(lineGraphScrollable.customMaxValidY - 2), @(lineGraphScrollable.customMaxValidY - 1)];
        case 9:
            return @[@(lineGraphScrollable.customMinValidY - 2), @(lineGraphScrollable.customMinValidY-1), @(lineGraphScrollable.customMinValidY), @(lineGraphScrollable.customMinValidY), @(lineGraphScrollable.customMaxValidY - 1), @(lineGraphScrollable.customMaxValidY), @(lineGraphScrollable.customMaxValidY + 1), @(lineGraphScrollable.customMaxValidY + 2), @(lineGraphScrollable.customMaxValidY + 2)];
        case 10:
            return @[@(lineGraphScrollable.customMinValidY - 4), @(lineGraphScrollable.customMinValidY-3), @(lineGraphScrollable.customMinValidY-10)];
        case 11:
            return @[@(lineGraphScrollable.customMaxValidY + 1), @(lineGraphScrollable.customMaxValidY + 2), @(lineGraphScrollable.customMaxValidY + 3)];
        case 12:
            return @[@(lineGraphScrollable.customMinValidY - 4), @(lineGraphScrollable.customMinValidY-300), @(lineGraphScrollable.customMinValidY-1000)];
        case 13:
            return @[@(lineGraphScrollable.customMaxValidY + 1), @(lineGraphScrollable.customMaxValidY + 200), @(lineGraphScrollable.customMaxValidY + 3000)];
        case 14:
            return @[@(lineGraphScrollable.customMaxValidY + 1), @(lineGraphScrollable.customMaxValidY + 100), @(lineGraphScrollable.customMaxValidY + 120), @(lineGraphScrollable.customMaxValidY + 200), @(lineGraphScrollable.customMaxValidY + 3000)];
            
            
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
            
        case 28:
            return @[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9];
        case 29:
            return @[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15, @16, @17, @18, @19, @20];
        case 30:
            return @[@9, @8, @2, @3, @4, @5, @6, @3, @2, @1];
        case 31:
            return @[@22, @21, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15, @16, @17, @3, @2, @1];
        default:
            button.tag = 0;
            return [self yAxisDataForline:graph];
    }
}

- (UIView *)markerViewForline:(SingleLineGraphBase *)graph pointIndex:(NSUInteger)pointIndex andYValue:(NSNumber *)yValue{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor orangeColor];
    [view.layer setCornerRadius:4.0F];
    [view.layer setBorderWidth:1.0F];
    [view.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
//    [view.layer setShadowColor:[[UIColor blackColor] CGColor]];
//    [view.layer setShadowRadius:2.0F];
//    [view.layer setShadowOpacity:0.3F];
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    [label setFont:[UIFont systemFontOfSize:12]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setText:[NSString stringWithFormat:@"日期 %zi日\nLine Data: %@", pointIndex, yValue]];
    label.numberOfLines = 2;
    [label setFrame:CGRectMake(0, 0, 100, 50)];
    [view addSubview:label];
    
    [view setFrame:label.frame];
    return view;
}

#pragma mark SingleLineGraphBaseDelegate
- (void)didTapLine:(SingleLineGraphBase *)graph atPoint:(NSUInteger)pointIndex valuesAtY:(NSNumber *)yValue{
//    NSLog(@"Tap point at %zi, y %@", pointIndex, yValue);
}
@end
