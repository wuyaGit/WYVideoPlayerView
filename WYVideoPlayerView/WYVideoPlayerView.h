//
//  WYVideoPlayerView.h
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2017/12/27.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WYPlayerManager.h"

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
@property (nonatomic, strong) NSURL *placeholderImageURL;
@property (nonatomic, strong) NSDictionary *resolutionDic;

@property (nonatomic, strong) UIView *fatherView;     //父视图
@property (nonatomic, assign) BOOL autoPlay;            //自动播放

@property (nonatomic, strong) UIScrollView *scrollView;         //UITableView 或CUICollectionView
@property (nonatomic, strong) NSIndexPath *indexPath;           //UITableView 或CUICollectionView 的位置信息
@property (nonatomic, assign) NSInteger fatherViewTag;          //UITableView 或CUICollectionView 的父视图TAG

@end

@protocol WYVideoPlayerViewDelegate;

@interface WYVideoPlayerView : UIView
@property (nonatomic, assign) WYPlayerViewType playerViewType;
@property (nonatomic, assign) id<WYVideoPlayerViewDelegate> delegate;

- (void)playerVideoItem:(WYVideoItem *)videoItem;
- (void)pause;
- (void)play;
@end

@protocol WYVideoPlayerViewDelegate <NSObject>

@optional
- (void)wy_dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)wy_videoPlayerToEndTime:(WYVideoPlayerView *)playerView;

@end

@interface UIViewController (WYVideoPlayerRotation)
@end

@interface UITabBarController (WYVideoPlayerRotation)
@end

@interface UINavigationController (WYVideoPlayerRotation)<UIGestureRecognizerDelegate>
@end

@interface UIAlertController (WYVideoPlayerRotation)
@end
