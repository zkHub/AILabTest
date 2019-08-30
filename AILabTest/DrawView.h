//
//  DrawView.h
//  画板
//
//  Created by zyj on 2017/12/13.
//  Copyright © 2017年 ittest. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DrawView : UIView
@property(nonatomic,assign) CGFloat lineWidth;//画笔宽度
@property(nonatomic,strong) UIColor* lineColor;//画笔颜色

@property (nonatomic, readonly, strong) NSMutableArray *paths;//用来管理画板上所有的路径



- (void)clean;//清除画板
- (void)undo;//回退上一步
- (void)eraser;//橡皮擦
- (void)save;//保存到相册
@end
