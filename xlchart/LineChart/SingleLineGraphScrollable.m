//
//  SingleLineGraphScrollable.m
//  xlchart
//
//  Created by lei xue on 16/9/7.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "SingleLineGraphScrollable.h"

@implementation SingleLineGraphScrollable
@synthesize minPositionStepX;
@synthesize backgroundScrollView;

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        minPositionStepX = (320 - self.graphMarginL - self.graphMarginR) / 10;//25
    }
    return self;
}

-(BOOL)calculatePositionStepX{
    if (![super calculatePositionStepX]) {
        CGFloat everagePStepX = [self widthGraph] / (self.xAxisArray.count - 1);
        self.positionStepX = MAX(minPositionStepX, everagePStepX);//保持相邻点的x方向距离>=minPositionStepX，同时尽量占满显示区域
    }
    return YES;
}

-(void)createGraphBackground{
    [super createGraphBackground];
    
    //如果手势被TapGesture、LongPressGesture成功识别，或者增加了PanGesture（无论是否成功识别），不会触发scrollViewDidScroll，即使 shouldRecognizeSimultaneouslyWithGestureRecognizer:返回YES也不行
    if (backgroundScrollView != nil) {
        [backgroundScrollView removeFromSuperview];
    }
    backgroundScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, [self heightGraph])];
    backgroundScrollView.showsVerticalScrollIndicator = NO;
    backgroundScrollView.showsHorizontalScrollIndicator = NO;
    backgroundScrollView.bounces = NO;
    backgroundScrollView.delegate = self;
    [self addSubview:backgroundScrollView];
    
    [self.graphBackgroundView removeFromSuperview];//之前加在self.view，需要移到backgroundScrollView中
    [backgroundScrollView addSubview:self.graphBackgroundView];
    backgroundScrollView.contentSize = self.graphBackgroundView.frame.size;
}

#pragma mark UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView == backgroundScrollView) {
        CGFloat comparedX = backgroundScrollView.contentOffset.x + self.graphMarginL;//坐标系原点距离左边缘 graphMarginL
        for (UILabel *l in self.xAxisLabels) {
            if (CGRectGetMaxX(l.frame) <= comparedX) {
                l.alpha = 0;
            }
            else{
                CGFloat halfWidth = l.frame.size.width / 2;
                CGFloat labelCenterRightYAxis = CGRectGetMaxX(l.frame) - comparedX;//label中点在y轴右侧的长度
                if (labelCenterRightYAxis >= halfWidth){//label中点在y轴右侧的长度>=半个长度
                    l.alpha = 1;
                }
                else{
                    //alpha = label中点在y轴右侧长度 / 半个长度
                    l.alpha = labelCenterRightYAxis / halfWidth;
                }
            }
        }
    }
}

-(CGPoint)calculateMarker:(CGSize)viewSize originWith:(CGPoint)closestPoint{
    CGPoint contentOffset = self.backgroundScrollView.contentOffset;
    if (closestPoint.x - (closestPoint.x == self.originalPoint.x ? 0 : self.pointRadius) < self.originalPoint.x + contentOffset.x) {
        if (closestPoint.x == self.originalPoint.x){
        }
        //closestPoint左边缘在y轴左侧，需要将backgroundScrollView向右滑动使其完全显示出来，但是第一个点只显示一半
        CGFloat needScroll = (self.originalPoint.x + contentOffset.x) - (closestPoint.x - (closestPoint.x == self.originalPoint.x ? 0 : self.pointRadius));
        contentOffset.x -= needScroll;
        [UIView animateWithDuration:0.2 animations:^{
            self.backgroundScrollView.contentOffset = contentOffset;
        }];
    }
    else if(closestPoint.x + (closestPoint.x == self.originalPoint.x ? 0 : self.pointRadius) > contentOffset.x + self.backgroundScrollView.frame.size.width){
        //closestPoint在屏幕外右边，右边缘没有显示出来，需要将backgroundScrollView向左滑动使其完全显示出来
        CGFloat needScroll = (closestPoint.x + self.pointRadius) - (contentOffset.x + self.backgroundScrollView.frame.size.width);
        contentOffset.x += needScroll;
        [UIView animateWithDuration:0.2 animations:^{
            self.backgroundScrollView.contentOffset = contentOffset;
        }];
    }
    
    CGPoint markerViewOrigin;
    CGRect lineFrame = [self axisFrame];
    if (CGRectGetMaxY(lineFrame) - closestPoint.y >= viewSize.height) {
        markerViewOrigin.y = closestPoint.y;
    }
    else{
        markerViewOrigin.y = closestPoint.y - viewSize.height;
    }
    
    if (closestPoint.x - lineFrame.origin.x >= viewSize.width
        && closestPoint.x - viewSize.width >= self.originalPoint.x + self.backgroundScrollView.contentOffset.x) {
        //如果lineFrame中closestPoint左边空间足够 && backgroundScrollView当前滚动后的显示区域仍然足够
        markerViewOrigin.x = closestPoint.x - viewSize.width;
    }
    else{
        markerViewOrigin.x = closestPoint.x;
    }
    return markerViewOrigin;
}
@end
