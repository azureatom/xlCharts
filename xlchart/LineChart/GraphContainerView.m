//
//  GraphContainerView.m
//  xlchart
//
//  Created by lei xue on 16/9/20.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "GraphContainerView.h"

@interface GraphContainerView()
@property(assign, nonatomic) CGPoint longPressLocation;
@property(strong, nonatomic) NSTimer *longPressTimer;
@end

@implementation GraphContainerView
@synthesize touchLocationBlock;
@synthesize touchFinishedBlock;
@synthesize longPressLocation;
@synthesize longPressTimer;

-(void)invalidateLongPress{
    if (longPressTimer != nil) {
        [longPressTimer invalidate];
        longPressTimer = nil;
    }
}

-(void)longPressed{
    [self invalidateLongPress];
    touchLocationBlock(longPressLocation);
}

/*处理长按、移动事件*/
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self invalidateLongPress];
    UITouch *touch = [touches anyObject];
    if (touch.tapCount == 1) {
        longPressLocation = [touch locationInView:self];
        longPressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(longPressed) userInfo:nil repeats:NO];
    }
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self invalidateLongPress];
    UITouch *aTouch = [touches anyObject];
    //CGPoint preLocation = [aTouch previousLocationInView:self];
    CGPoint currentLocation = [aTouch locationInView:self];
    if (CGRectContainsPoint(self.bounds, currentLocation)) {
        touchLocationBlock(currentLocation);
    }
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self invalidateLongPress];
    touchFinishedBlock();
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self invalidateLongPress];
    touchFinishedBlock();
}

@end
