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
    WYPlayerViewTypeCellListNoTitle,          //列表中的播放器无标题
};

/**
 * 播放模型
 */
@interface WYVideoItem: NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) UIView *fatherView;     //父视图
@property (nonatomic, assign) BOOL autoPlay;            //自动播放
@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, strong) UIViewController *visibleViewController;

@property (nonatomic, strong) UIScrollView *scrollView;         //UITableView 或CUICollectionView
@property (nonatomic, strong) NSIndexPath *indexPath;           //UITableView 或CUICollectionView 的位置信息
@property (nonatomic, assign) NSInteger fatherViewTag;          //UITableView 或CUICollectionView 的父视图TAG

@end

/**
 * 播放器
 */
@interface WYVideoPlayerView : UIView
@property (nonatomic, assign) WYPlayerViewType playerViewType;

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
