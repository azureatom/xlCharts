//
//  LineGraphBase.m
//  xlchart
//
//  Created by lei xue on 16/9/5.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "LineGraphBase.h"

@implementation LineGraphBase
@synthesize enablePanAndLongPress;
@synthesize fractionDigits;
@synthesize graphBackgroundView;
@synthesize originalPoint;
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
@synthesize showLegend;
@synthesize legendViewType;

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.fractionDigits = 0;
        self.gridLineColor = [UIColor lightGrayColor];
        self.gridLineWidth = 0.3;
        shouldDrawPoints = YES;
        maxPointRadius = 1.5;
        
        self.enablePanAndLongPress = YES;
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
    formatter.roundingMode = isCeiling ? kCFNumberFormatterRoundCeiling : NSNumberFormatterRoundFloor;
    formatter.minimumFractionDigits = self.fractionDigits;
    formatter.maximumFractionDigits = self.fractionDigits;
    return [formatter stringFromNumber:[NSNumber numberWithDouble:d]].doubleValue;
}

- (CGPoint)optimizedPoint:(CGPoint)point{
    //当view的位置不是整数或者0.5的倍数时，由于屏幕分辨率和像素匹配问题，view显示会略微模糊
    return CGPointMake(floor(point.x), floor(point.y));
}

- (void)drawGraph{
    /*
     ******界面布局******
     y轴和y轴刻度值在self上，覆盖在graphScrollView上面，这样在graphScrollView左右滑动时y轴刻度值仍会显示
     x轴和x轴刻度值、曲线在graphScrollView上，随graphScrollView左右滑动。
     x轴和y轴的刻度值都是label中点对准刻度线。
     原点的
     x刻度值xAxisLabel显示在y轴的正下方，也即xAxisLabel中心和y轴对齐。当x轴刻度值label左滑超过y轴，且超过label一半长度后，继续左滑逐渐变透明，也即xAxisLabel.alpha = xAxisLabel在y轴右边的长度/xAxisLabel半长。
     y刻度值显示在x轴的正左方，也即文字中点和x轴对齐，因此x轴下方余出k_graphVerticalMargin再显示x刻度值。
     由于x轴刻度值左滑过y轴才会逐渐透明，因此self、graphBackgroundView、graphScrollView宽度一样，但在self左部覆盖一个柱形yAxisView遮住graphScrollView左小半部。
     
     ******view排列关系******
     self水平方向：
     self(yAxisView(宽度k_graphLeftMargin，显示y轴和y轴刻度值),
     graphScrollView(左小半部k_graphLeftMargin范围被yAxisView覆盖)
     )
     self竖直方向：
     graphScrollView
     LegendView
     
     如果y比y轴最大的刻度值还大，则y轴往上延伸一段表示无穷大，超大的数据点用空心而不是实心
     
     graphBackgroundView占满graphScrollView，曲线点少则x相邻刻度值长度拉长，以保证graphBackgroundView长度==graphScrollView长度；曲线点多则超过graphScrollView长度，需要左右滑动。graphScrollView.contentSize = graphBackgroundView.frame.size
     水平方向：
     左边空白 k_graphLeftMargin
     曲线和各刻度线表格
     右边空白 k_graphRightMargin
     竖直方向：
     空白 k_graphVerticalMargin
     曲线和各刻度线表格
     x轴
     空白 k_graphVerticalMargin
     x轴刻度值 k_xAxisLabelHeight
     */
    [self createGraphBackground];
    
    [self createXAxisLine];
    
    //注意，如果self是navigationcontroller的第一个view，graphScrollView.contentInset.top自动设为64，需要设置viewController.automaticallyAdjustsScrollViewInsets = NO;
    [self createYAxisLine];//设置y坐标和grid横线。在yAxisView上显示y轴刻度值
    originalPoint = CGPointMake([self xPositionOfAxis:0], ((NSNumber *)positionYOfYAxisValues.firstObject).floatValue);
    
    [self calculatePointRadius];
    [self drawLines];
    
    if (self.showMarker) {
        [self createMarker];
    }
    if (self.showLegend) {
        [self createLegend];
    }
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
        
        [path appendPath:[self drawPathWithStartPoint:startPoint endPoint:nextPoint]];
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
    [pathAnimation setDuration:ANIMATION_DURATION];
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
    [pathAnimation setDuration:ANIMATION_DURATION];
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
    shapeLayer.path = [[self drawPathWithStartPoint:startPoint endPoint:endPoint] CGPath];
    shapeLayer.strokeColor = self.gridLineColor.CGColor;
    shapeLayer.lineWidth = self.gridLineWidth;
    return shapeLayer;
}

- (UIBezierPath *)drawPathWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint{
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

#pragma mark - override by subclass
-(CGPoint)pointAtIndex:(NSUInteger)pointIndex inLine:(LineChartDataRenderer *)lineData{
    return CGPointZero;
}
- (void)createXAxisLine{}
- (void)createYAxisLine{}
- (CGFloat)xPositionOfAxis:(NSUInteger)pointIndex{
    return 0;
}
- (void)calculatePointRadius{}
- (void)drawLines{}
- (void)createMarker{}
- (void) createLegend{}
@end
