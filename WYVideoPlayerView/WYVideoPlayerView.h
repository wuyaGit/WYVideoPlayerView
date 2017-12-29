//
//  WYVideoPlayerView.h
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2017/12/27.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WYPlayerStatus) {
    WYPlayerStatusFailed        = 0,        //播放失败
    WYPlayerStatusBuffering,                //缓冲中
    WYPlayerStatusPlaying,                  //播放中
    WYPlayerStatusStopped,                  //停止播放
    WYPlayerStatusPause                     //暂停播放
};
/**
 * 播放模型
 */
@interface WYVideoItem: NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) UIView *fatherView; //父视图
@property (nonatomic, assign) BOOL autoPlay; //自动播放

@end

// 
/**
 * 播放器
 */
@interface WYVideoPlayerView : UIView

@property (nonatomic, readonly, assign) WYPlayerStatus playerStatus;

- (void)playerVideoItem:(WYVideoItem *)videoItem;

//重置播放器
- (void)resetPlayer;

- (void)pause;

- (void)play;
@end
