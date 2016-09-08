//
//  TimeLineGraphViewController.m
//  xlchart
//
//  Created by lei xue on 16/9/8.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "TimeLineGraphViewController.h"
#import "TimeLineGraph.h"

@interface TimeLineGraphViewController ()<TimeLineGraphDataSource, TimeLineGraphDelegate>
@property(strong, nonatomic) UIButton *tagButton;
@property(strong, nonatomic) UIButton *backButton;
@property(strong, nonatomic) TimeLineGraph *tLineGraph;
@end

@implementation TimeLineGraphViewController
@synthesize tagButton;
@synthesize backButton;
@synthesize tLineGraph;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tagButton.frame = CGRectMake(0, 50, 100, 20);
    [tagButton setTitle:@"切换曲线数据" forState:UIControlStateNormal];
    tagButton.titleLabel.font = [UIFont systemFontOfSize:10];
    [tagButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    tagButton.tag = 0;
    [tagButton addTarget:self action:@selector(onButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:tagButton];
    
    backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(150, 50, 100, 20);
    [backButton setTitle:@"返回" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(onButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    
    
    tLineGraph = [[TimeLineGraph alloc] initWithFrame:CGRectMake(0, 100, 320, 200)];
    tLineGraph.delegate = self;
    tLineGraph.dataSource = self;
    tLineGraph.graphMarginL = 5;
    tLineGraph.graphMarginR = 5;
    tLineGraph.graphMarginV = 0;
//    tLineGraph.heightXAxisLabel = kYLabelHeight;
    tLineGraph.fractionDigits = 3;
    tLineGraph.shouldDrawPoints = NO;
    
    tLineGraph.yesterdayClosePrice = 2.000;
    tLineGraph.minPriceChangePercent = 0.02;
    tLineGraph.axisFont = [UIFont systemFontOfSize:12];
    tLineGraph.textColor = [UIColor darkGrayColor];
    tLineGraph.textUpColor = [UIColor redColor];
    tLineGraph.textDownColor = [UIColor greenColor];
    
    tLineGraph.markerColor = [UIColor orangeColor];
    tLineGraph.markerTextColor = [UIColor whiteColor];
    [self.view addSubview:tLineGraph];
    
    [tLineGraph reloadGraph];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)onButtonTapped:(UIButton *)b{
    if (b == backButton) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if (b == tagButton) {
        tagButton.tag++;
        NSLog(@"button.tag %zi", tagButton.tag);
        [tLineGraph reloadGraph];
    }
}

#pragma mark - TimeLineGraphDataSource
- (NSUInteger)numberOfLinesInTimeLine:(TimeLineGraph *)timeLineGraph{
    return 1;
}

- (CGFloat)timeLine:(TimeLineGraph *)timeLineGraph lineWidth:(NSUInteger)lineIndex{
    return 0.5;
}

- (UIColor *)timeLine:(TimeLineGraph *)timeLineGraph lineColor:(NSUInteger)lineIndex{
    return [UIColor blueColor];
}

- (NSArray *)timeLine:(TimeLineGraph *)timeLineGraph yAxisDataForline:(NSUInteger)lineIndex{
    NSMutableArray *priceArray = [[NSMutableArray alloc] initWithCapacity:243];
    for (int i = 0; i < 243 + 10; ++i) {
        double priceChange = (double)(rand() % 5) / 100;
        if ((i / 50) % 2 == 0) {
            priceChange = -priceChange;
        }
        [priceArray addObject:@(2 + priceChange)];
    }
    switch (tagButton.tag) {
        case 0:
            return nil;
        case 1:
            return @[@(2)];
        case 2:
            return @[@(2.01), @(2.08)];
        case 3:
            return @[@(2.01), @(2.08), @(1.95)];
        case 4:
            return priceArray;
        default:
            tagButton.tag = 0;
            return nil;
    }
    return @[];
}

#pragma mark - TimeLineGraphDelegate
- (void)timeLine:(TimeLineGraph *)timeLineGraph didTapLine:(NSUInteger)lineIndex atPoint:(NSUInteger)pointIndex{}
@end
