//
//  KLineGraphViewController.m
//  xlchart
//
//  Created by lei xue on 16/9/8.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "KLineGraphViewController.h"
#import "KLineGraph.h"

@interface KLineGraphViewController ()<KLineGraphDataSource, KLineGraphDelegate>
@property(strong, nonatomic) UIButton *tagButton;
@property(strong, nonatomic) UIButton *backButton;
@property(strong, nonatomic) KLineGraph *kLineGraph;
@end

@implementation KLineGraphViewController
@synthesize tagButton;
@synthesize backButton;
@synthesize kLineGraph;

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
    
    kLineGraph = [[KLineGraph alloc] initWithFrame:CGRectMake(0, 100, 320, 200)];
    kLineGraph.kLinePeriod = KLinePeriodDaily;
    kLineGraph.delegate = self;
    kLineGraph.dataSource = self;
    kLineGraph.graphMarginL = 5;
    kLineGraph.graphMarginR = 5;
    kLineGraph.graphMarginV = 0;
//    kLineGraph.heightXAxisLabel = kYLabelHeight;
    kLineGraph.fractionDigits = 3;
    kLineGraph.shouldDrawPoints = NO;
    
    kLineGraph.axisFont = [UIFont systemFontOfSize:12];
    kLineGraph.textColor = [UIColor darkGrayColor];
    kLineGraph.textUpColor = [UIColor redColor];
    kLineGraph.textDownColor = [UIColor greenColor];
    
    kLineGraph.markerColor = [UIColor orangeColor];
    kLineGraph.markerTextColor = [UIColor whiteColor];
    kLineGraph.markerBgColor = [UIColor grayColor];
    
    kLineGraph.maxBarWidth = 5;
    kLineGraph.volumeHeightRatio = 0.25;
    [self.view addSubview:kLineGraph];
    
    [kLineGraph reloadGraph];
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
        [kLineGraph reloadGraph];
    }
}

#pragma mark - KLineGraphDataSource
- (NSUInteger)numberOfLinesInkLine:(KLineGraph *)graph{
    return 1;
}

- (CGFloat)kLine:(KLineGraph *)graph lineWidth:(NSUInteger)lineIndex{
    return 0.5;
}

- (UIColor *)kLine:(KLineGraph *)graph lineColor:(NSUInteger)lineIndex{
    return [UIColor blueColor];
}

- (NSArray *)xAxisDataInKLine:(KLineGraph *)graph{
    return @[];
}

- (NSArray *)kLine:(KLineGraph *)graph yAxisDataForline:(NSUInteger)lineIndex{
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

- (NSArray *)kLineDataInkLine:(KLineGraph *)graph{
    return @[];//array of KLineElement
}

#pragma mark - KLineGraphDelegate
- (void)kLine:(KLineGraph *)graph didTapLine:(NSUInteger)lineIndex atPoint:(NSUInteger)pointIndex{
    //显示该日/周/月的价格、成交量、ma5等
}
- (void)markerDidDismissInKLine:(KLineGraph *)graph{
}
@end
