//
//  WYVideoPlayerView.h
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2017/12/27.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WYPlayerViewType) {
    WYPlayerViewTypeDefault        = 0,         //默认单个播放器
    WYPlayerViewTypeCellList,                   //列表中的播放器
};

/**
 * 播放模型
 */
@interface WYVideoItem: NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) UIView *fatherView; //父视图
@property (nonatomic, assign) WYPlayerViewType playerViewType;
@property (nonatomic, assign) BOOL autoPlay; //自动播放

@end

// 
/**
 * 播放器
 */
@interface WYVideoPlayerView : UIView

- (void)playerVideoItem:(WYVideoItem *)videoItem;

//重置播放器
- (void)resetPlayer;

- (void)pause;

- (void)play;
@end

@interface UIViewController (WYVideoPlayerRotation)
@end

@interface UITabBarController (WYVideoPlayerRotation)
@end

@interface UINavigationController (WYVideoPlayerRotation)<UIGestureRecognizerDelegate>
@end

@interface UIAlertController (WYVideoPlayerRotation)
@end
