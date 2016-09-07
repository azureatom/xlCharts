//
//  LineGraphBase.m
//  xlchart
//
//  Created by lei xue on 16/9/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "LineGraphBase.h"

@implementation LineGraphBase
@synthesize animationDuration;
@synthesize heightXAxisLabel;
@synthesize graphMarginV;
@synthesize graphMarginL;
@synthesize graphMarginR;
@synthesize fractionDigits;
@synthesize graphBackgroundView;
@synthesize originalPoint;
@synthesize xAxisArray;
@synthesize xAxisLabels;
@synthesize positionStepX;
@synthesize positionStepY;
@synthesize gridLineColor;
@synthesize gridLineWidth;
@synthesize shouldDrawPoints;
@synthesize maxPointRadius;
@synthesize pointRadius;
@synthesize positionYOfYAxisValues;
@synthesize showMarker;
@synthesize markerColor;
@synthesize markerTextColor;
@synthesize markerWidth;
@synthesize xMarker;
@synthesize yMarker;
@synthesize defaultMarker;
@synthesize customMarkerView;

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        animationDuration = 1.2;
        heightXAxisLabel = 15;
        graphMarginV = 8;
        graphMarginL = 50;
        graphMarginR = 20;
        
        self.fractionDigits = 0;
        self.gridLineColor = [UIColor lightGrayColor];
        self.gridLineWidth = 0.3;
        shouldDrawPoints = YES;
        maxPointRadius = 1.5;
    }
    return self;
}

- (NSString *)formattedStringForNumber:(NSNumber *)n{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = YES;
    formatter.groupingSeparator = @",";
    formatter.groupingSize = 3;//每千位逗号分隔
    formatter.roundingMode = NSNumberFormatterRoundHalfUp;//四舍五入
    formatter.minimumFractionDigits = fractionDigits;
    formatter.maximumFractionDigits = fractionDigits;
    formatter.alwaysShowsDecimalSeparator = NO;//是否总显示小数点号，如1.0显示为1.而12显示为12.
    return [formatter stringFromNumber:n];
}

- (double)fractionFloorOrCeiling:(double)d ceiling:(BOOL)isCeiling{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = NO;
    formatter.roundingMode = isCeiling ? kCFNumberFormatterRoundCeiling : NSNumberFormatterRoundFloor;
    formatter.minimumFractionDigits = self.fractionDigits;
    formatter.maximumFractionDigits = self.fractionDigits;
    return [formatter stringFromNumber:[NSNumber numberWithDouble:d]].doubleValue;
}

- (CGPoint)optimizedPoint:(CGPoint)point{
    //当view的位置不是整数或者0.5的倍数时，由于屏幕分辨率和像素匹配问题，view显示会略微模糊
    //但这样会导致在同一直线上的点，之间的各线段略微有折角
    return CGPointMake(round(point.x), round(point.y));
}

- (void)drawOneLine:(LineChartDataRenderer *)lineData{
    if (lineData.yAxisArray.count == 0) {//没有点
        return;
    }
    
    CGPoint startPoint = [self pointAtIndex:0 inLine:lineData];
    if (lineData.drawPoints) {
        [self drawPointsOnLine:startPoint withColor:lineData.lineColor];
    }
    
    if (lineData.yAxisArray.count == 1) {
        //只有一个点，画完这个点就结束，因为画path需要至少2个点
        return;
    }
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    UIBezierPath *fillPath = [UIBezierPath bezierPath];
    [fillPath moveToPoint:startPoint];
    
    for (int i = 1; i < lineData.yAxisArray.count; ++i) {
        CGPoint nextPoint = [self pointAtIndex:i inLine:lineData];
        
        [path appendPath:[self pathFrom:startPoint to:nextPoint]];
        [fillPath addLineToPoint:nextPoint];
        if (lineData.drawPoints) {
            [self drawPointsOnLine:nextPoint withColor:lineData.lineColor];
        }
        startPoint = nextPoint;
    }
    
    [path closePath];
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    [shapeLayer setPath:[path CGPath]];
    [shapeLayer setStrokeColor:lineData.lineColor.CGColor];
    [shapeLayer setLineWidth:lineData.lineWidth];
    shapeLayer.shouldRasterize = YES;
    shapeLayer.rasterizationScale = [UIScreen mainScreen].scale;
    shapeLayer.contentsScale = [UIScreen mainScreen].scale;
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    [pathAnimation setDuration:animationDuration];
    [pathAnimation setFromValue:[NSNumber numberWithFloat:0.0f]];
    [pathAnimation setToValue:[NSNumber numberWithFloat:1.0f]];
    [shapeLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
    
    [self.graphBackgroundView.layer addSublayer:shapeLayer];
    
    if (lineData.fillGraph) {
        [fillPath addLineToPoint:CGPointMake(startPoint.x, originalPoint.y)];
        [fillPath addLineToPoint:originalPoint];//坐标原点的位置
        [fillPath addLineToPoint:[self pointAtIndex:0 inLine:lineData]];
        [fillPath closePath];
        
        [self fillGraphBackgroundWithPath:fillPath color:lineData.lineColor];
    }
}

#pragma mark Graph line drawing operation
- (void)fillGraphBackgroundWithPath:(UIBezierPath *)path color:(UIColor *)color{
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    [shapeLayer setPath:path.CGPath];
    [shapeLayer setFillColor:color.CGColor];
    [shapeLayer setOpacity:0.1];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"fill"];
    [pathAnimation setDuration:animationDuration];
    [pathAnimation setFillMode:kCAFillModeForwards];
    [pathAnimation setFromValue:(id)[[UIColor clearColor] CGColor]];
    [pathAnimation setToValue:(id)[color CGColor]];
    [pathAnimation setBeginTime:CACurrentMediaTime()];
    [pathAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    
    [shapeLayer addAnimation:pathAnimation forKey:@"fill"];
    
    [self.graphBackgroundView.layer addSublayer:shapeLayer];
}

- (CAShapeLayer *)gridLineLayerStart:(CGPoint)startPoint end:(CGPoint)endPoint{
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.path = [[self pathFrom:startPoint to:endPoint] CGPath];
    shapeLayer.strokeColor = self.gridLineColor.CGColor;
    shapeLayer.lineWidth = self.gridLineWidth;
    return shapeLayer;
}

- (UIBezierPath *)pathFrom:(CGPoint)startPoint to:(CGPoint)endPoint{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:[self optimizedPoint:startPoint]];
    [path addLineToPoint:[self optimizedPoint:endPoint]];
    
    [path closePath];
    
    return path;
}

- (void)drawPointsOnLine:(CGPoint)point withColor:(UIColor *)color{
    UIBezierPath *pointPath = [UIBezierPath bezierPath];
    [pointPath addArcWithCenter:[self optimizedPoint:point] radius:pointRadius startAngle:0 endAngle:2 * M_PI clockwise:YES];
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    [shapeLayer setPath:pointPath.CGPath];
    [shapeLayer setStrokeColor:color.CGColor];//如果StrokeColor和FillColor不同，则画出的是环
    [shapeLayer setFillColor:color.CGColor];
    [shapeLayer setLineWidth:0];
    shapeLayer.shouldRasterize = YES;
    shapeLayer.rasterizationScale = [UIScreen mainScreen].scale;
    shapeLayer.contentsScale = [UIScreen mainScreen].scale;
    [self.graphBackgroundView.layer addSublayer:shapeLayer];
}

#pragma mark handle gestures
-(void)handleTapPanLongPress:(UITapGestureRecognizer *)gesture{
    if (self.showMarker) {
        CGPoint currentPoint = [gesture locationInView:self.graphBackgroundView];
        if (CGRectContainsPoint(self.graphBackgroundView.frame, currentPoint)) {
            //TapGesture 取曲线上直线距离最小的点，并检查距离是否过大，过大则不显示十字线信息；
            //而PanGesture和LongPressGesture 只取曲线x方向距离最近的点即可，不需检查距离是否过大。这样可以保证在拖拽时，曲线上的点依次显示十字线信息。
            [self showMakerNearPoint:currentPoint checkXDistanceOnly:![gesture isMemberOfClass:[UITapGestureRecognizer class]]];
        }
    }
}

#pragma mark - x轴、y轴、曲线图等的长宽
/*水平方向
 self 长度同 backgroundScrollView
 graphBackgroundView长度 >= backgroundScrollView
 graphMarginL, 坐标轴, graphMarginR
 */
-(CGFloat)widthGraph{
    return self.frame.size.width - self.graphMarginL - self.graphMarginR;
}

//当不可scroll时，实际等于[self widthGraph]
-(CGFloat)widthXAxis{
    //x轴的长度，不包括左右的margin
    return self.positionStepX * (self.xAxisArray.count <= 1 ? 1 : self.xAxisArray.count - 1);
}

/*竖直方向
 self
 backgroundScrollView 高度同 graphBackgroundView
 graphMarginV
 曲线坐标轴
 graphMarginV
 heightXAxisLabel
 */
-(CGFloat)heightGraph{
    return self.frame.size.height;
}

-(CGFloat)heightYAxis{
    return [self heightGraph] - self.graphMarginV - self.graphMarginV - self.heightXAxisLabel;
}

-(CGRect)axisFrame{
    return CGRectMake(self.graphMarginL, self.graphMarginV, [self widthXAxis], [self heightYAxis]);
}

#pragma mark - override by subclass
- (void)reloadGraph{
    [self setupDataWithDataSource];
    
    [self calculatePositionStepX];
    [self calculatePointRadius];
    [self calculateYAxis];
    self.originalPoint = CGPointMake([self xPositionOfAxis:0], ((NSNumber *)self.positionYOfYAxisValues.firstObject).floatValue);
    
    [self createGraphBackground];
    [self drawXAxis];
    [self drawYAxis];//设置y坐标和grid横线。在yAxisView上显示y轴刻度值
    [self drawLines];
    
//    NSString *xString = @"X: ";
//    for (NSString *a in self.xAxisArray) {
//        xString = [NSString stringWithFormat:@"%@%@, ", xString, a];
//    }
//    NSLog(xString);
//    NSString *yString = @"Y: ";
//    for (NSString *a in self.lineDataRenderer.yAxisArray) {
//        yString = [NSString stringWithFormat:@"%@%@, ", yString, a];
//    }
//    NSLog(yString);
    
    [self createMarker];
}

- (void)setupDataWithDataSource{}

-(BOOL)calculatePositionStepX{
    //基类只处理x轴只有一个刻度值的情况，多个刻度值由子类处理
    if (self.xAxisArray.count <= 1) {
        //没有点或者只有一个点时，positionStepX等于整个区域宽度
        self.positionStepX = [self widthGraph];
        return YES;
    }
    return NO;
}

-(void)calculatePointRadius{}
-(void)calculateYAxis{}

-(void)createGraphBackground{
    //基类创建graphBackgroundView，但是并没有加入superview中，子类决定加入self还是backgroundScrollView中
    if (graphBackgroundView != nil) {
        [graphBackgroundView removeFromSuperview];
    }
    graphBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.graphMarginL + [self widthXAxis] + self.graphMarginR, [self heightGraph])];//根据x轴的宽度设置graphBackgroundView的宽度
    //如果手势被TapGesture、LongPressGesture成功识别，或者增加了PanGesture（无论是否成功识别），不会触发scrollViewDidScroll，即使 shouldRecognizeSimultaneouslyWithGestureRecognizer:返回YES也不行
    [self.graphBackgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapPanLongPress:)]];
}

- (void)drawXAxis{}
- (void)drawYAxis{}
- (void)drawLines{}
- (void)createMarker{}

- (CGFloat)xPositionOfAxis:(NSUInteger)pointIndex{
    return 0;
}

-(CGPoint)pointAtIndex:(NSUInteger)pointIndex inLine:(LineChartDataRenderer *)lineData{
    return CGPointZero;
}

- (void)showMakerNearPoint:(CGPoint)pointTouched checkXDistanceOnly:(BOOL)checkXDistanceOnly{}
-(CGPoint)calculateMarker:(CGSize)viewSize originWith:(CGPoint)closestPoint{
    //makerView优先显示在selectedPoint的左下角，如果显示不开则显示在右方或上方
    return closestPoint;
}
@end
