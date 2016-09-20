//
//  GraphContainerView.h
//  xlchart
//
//  Created by lei xue on 16/9/20.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GraphContainerView : UIView
@property(copy, nonatomic) void(^touchLocationBlock)(CGPoint);
@property(copy, nonatomic) void(^touchFinishedBlock)();
@end
