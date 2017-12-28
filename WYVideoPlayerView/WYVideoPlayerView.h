//
//  WYVideoPlayerView.h
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2017/12/27.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 播放模型
 */
@interface WYVideoItem: NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSURL *videoURL;

@end

/**
 * 播放器
 */
@interface WYVideoPlayerView : UIView

- (void)playerVideoItem:(WYVideoItem *)videoItem;

- (void)autoPlayVideo;

//重置播放器
- (void)resetPlayer;

- (void)pause;

- (void)play;
@end
