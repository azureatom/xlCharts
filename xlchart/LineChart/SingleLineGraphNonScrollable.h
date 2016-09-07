//
//  SingleLineGraphNonScrollable.h
//  xlchart
//
//  Created by lei xue on 16/9/7.
//  Copyright © 2016年 userstar. All rights reserved.
//

#import "SingleLineGraphBase.h"

@interface SingleLineGraphNonScrollable : SingleLineGraphBase
/**
 *  是否支持Pan和LongPress手势。
 *  默认YES，不可左右滚动，识别多种手势
 *  NO 只支持TapGesture显示Marker，不识别LongPressGesture和PanGesture手势
 */
@property (assign, nonatomic) BOOL enablePanAndLongPress;
@end
