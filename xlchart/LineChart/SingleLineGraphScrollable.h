//
//  SingleLineGraphScrollable.h
//  xlchart
//
//  Created by lei xue on 16/9/7.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "SingleLineGraphBase.h"

@interface SingleLineGraphScrollable : SingleLineGraphBase<UIScrollViewDelegate>
@property (assign, nonatomic) CGFloat minPositionStepX;//默认25，用户自定义相邻点的x方向距离，用于设置positionStepX。如果不能占满横向区域，则实际距离positionStepX会采用恰好占满的值
@property (nonatomic, strong) UIScrollView *backgroundScrollView;
@end
