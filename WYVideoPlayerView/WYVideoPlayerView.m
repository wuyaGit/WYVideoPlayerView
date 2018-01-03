//
//  WYVideoPlayerView.m
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2017/12/27.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "WYVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Masonry.h>
#import <UIImageView+WebCache.h>
#import "WYPlayerBrightnessView.h"

#define WYPlayerBundleSourcePath(file) [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"WYVideoPlayer.bundle"] stringByAppendingPathComponent:file]
#define WYPlayerBundleImageNamed(file) [UIImage imageWithContentsOfFile:WYPlayerBundleSourcePath(file)]

#define WYPlayerColorWithRGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

#define WYPlayerHideControlViewDelay    7.f
#define WYPlayerShowControlViewDuration 0.3f

typedef NS_ENUM(NSInteger, WYPlayerStatus) {
    WYPlayerStatusFailed        = 0,        //播放失败
    WYPlayerStatusBuffering,                //缓冲中
    WYPlayerStatusPlaying,                  //播放中
    WYPlayerStatusStopped,                  //停止播放
    WYPlayerStatusPause                     //暂停播放
};

typedef NS_ENUM(NSInteger, WYPlayerPanChanged) {
    WYPlayerPanChangedSeektime        = 0,
    WYPlayerPanChangedVolume,
    WYPlayerPanChangedLight
};


@implementation WYVideoItem

@end

@interface WYVideoPlayerView ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) WYVideoItem *videoItem;
@property (nonatomic, assign) WYPlayerStatus playerStatus;
@property (nonatomic, assign) WYPlayerPanChanged panChangedType;
@property (nonatomic, assign) CGFloat panSeekTime;
@property (nonatomic, strong) UIScrollView *scrollView;       //滚动视图

@property (nonatomic, strong) AVPlayer *player;                 //控制器
@property (nonatomic, strong) AVPlayerItem *playerItem;       //模型
@property (nonatomic, strong) AVPlayerLayer *playerLayer;     //视图

@property (nonatomic, strong) UIView *playerView;           //播放视图
@property (nonatomic, strong) UIView *topView;             //顶部菜单
@property (nonatomic, strong) UIView *bottomView;          //底部进度条
@property (nonatomic, strong) UIView *resolutionView;       //分辨率视图
@property (nonatomic, strong) UIImageView *placeholderImageView; //占位图
@property (nonatomic, strong) UIView *completedView;           //播放完成、失败

@property (nonatomic, strong) WYPlayerBrightnessView *displayView;        //调节亮度视图
@property (nonatomic, strong) UISlider *volumeViewSlider;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesetureRecognizer;

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *lockButton;                 //锁定屏幕
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *closeButton;                //小屏关闭
@property (nonatomic, strong) UIButton *fullScreenButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIButton *resolutionButton;
@property (nonatomic, strong) UIButton *completedButton;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *totalTimeLabel;
@property (nonatomic, strong) UILabel *percentageLabel;           //快进/倒退时间
@property (nonatomic, strong) UILabel *completedLabel;           //快进/倒退时间

@property (nonatomic, strong) UIProgressView *loadedProgressView;           //缓冲进度条
@property (nonatomic, strong) UIProgressView *faseProgressView;             //快进/倒退进度条
@property (nonatomic, strong) UISlider *videoProgressSlider;                        //播放进度条

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@property (nonatomic, strong) id playTimeObserver;

@property (nonatomic, getter=isDragged, assign) BOOL dragged; //是否正在拖动
@property (nonatomic, getter=isFullScreen, assign) BOOL fullScreen; //是否是横屏
@property (nonatomic, getter=isLockScreen, assign) BOOL lockScreen; //是否是锁屏状态
@property (nonatomic, getter=isBottomVideo, assign) BOOL bottomVideo; //在底部播放

@property (nonatomic, getter=isEnterBackground, assign) BOOL enterBackground; //是否进入了后台
@property (nonatomic, getter=isShowCtrlView, assign) BOOL showCtrlView; //是否显示控制视图

@end

@implementation WYVideoPlayerView

/*--------------------------
结构：
 WYVideoPlayerView ->
                PlayerView ->
                        PlayerLayer ->

 ---------------------------*/

#pragma mark - Initializer

//代码创建调用
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        [self setupView];
        [self setupAVPlayer];
        [self setupConstraints];
    }
    
    return self;
}


//xib创建调用
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupView];
        [self setupAVPlayer];
        [self setupConstraints];

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

//移出内存调用
- (void)dealloc {
    //移除通知
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //移除KVO
    [self setPlayerItem:nil];
    //移除监听
    if (self.playTimeObserver) {
        [self.player removeTimeObserver:self.playTimeObserver];
        self.playTimeObserver = nil;
    }
}

#pragma mark - Setup Methods

- (void)setupView {
    //setup player view
    [self addSubview:self.playerView];

    //setup placeholderImageView
    [self addSubview:self.placeholderImageView];
    
    //setup top view
    [self addSubview:self.topView];

    [self.topView addSubview:self.backButton];
    [self.topView addSubview:self.titleLabel];
    [self.topView addSubview:self.shareButton];
    [self.topView addSubview:self.moreButton];

    //setup bottom view
    [self addSubview:self.bottomView];
    
    [self.bottomView addSubview:self.playButton];
    [self.bottomView addSubview:self.loadedProgressView];
    [self.bottomView addSubview:self.videoProgressSlider];
    [self.bottomView addSubview:self.fullScreenButton];
    [self.bottomView addSubview:self.currentTimeLabel];
    [self.bottomView addSubview:self.totalTimeLabel];
    [self.bottomView addSubview:self.resolutionButton];

    //setup lock button
    [self addSubview:self.lockButton];
    
    //setup activity view
    [self addSubview:self.activityView];
    
    //setup percentage label
    [self addSubview:self.percentageLabel];

    //setup close button
    [self addSubview:self.closeButton];

    //setup displayView
    [self addSubview:self.displayView];
    
    //setup completionView
    [self addSubview:self.completedView];
    
    [self.completedView addSubview:self.completedButton];
    [self.completedView addSubview:self.completedLabel];
}

- (void)setupAVPlayer {
    self.player = [[AVPlayer alloc] init];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.playerView.layer addSublayer:self.playerLayer];
}

- (void)setupConstraints {
    [self layoutIfNeeded];
    
    //------------ 播放器视图
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    //------------ 占位图
    [self.placeholderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    //------------ 顶部
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.mas_offset(0);
        make.height.mas_equalTo(50);        //顶部视图高50
    }];
    
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.topView.mas_leading).offset(5);
        make.top.equalTo(self.topView.mas_top).offset(3);
        make.width.height.mas_equalTo(28);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.backButton.mas_trailing).offset(5);
        make.top.equalTo(self.backButton.mas_top).offset(3);
        make.trailing.equalTo(self.shareButton.mas_leading).offset(-10);
    }];
    
    [self.shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.moreButton.mas_leading).offset(10);
        make.centerY.equalTo(self.backButton.mas_centerY);
        make.width.height.mas_equalTo(0);
    }];
    
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.topView.mas_trailing).offset(-8);
        make.centerY.equalTo(self.backButton.mas_centerY);
        make.width.height.mas_equalTo(0);
    }];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self);
        make.top.equalTo(self.mas_top).offset(0);
        make.width.height.mas_equalTo(32);
    }];
    
    //------------- 底部
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.mas_equalTo(0);
        make.height.mas_equalTo(50);
    }];
    
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bottomView.mas_leading).offset(5);
        make.bottom.equalTo(self.bottomView.mas_bottom).offset(-5);
        make.width.height.mas_equalTo(28);
    }];
    
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.playButton.mas_trailing).offset(-3);
        make.centerY.equalTo(self.playButton.mas_centerY);
        make.width.mas_equalTo(42);
    }];
    
    [self.loadedProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(4);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-4);
        make.centerY.equalTo(self.playButton.mas_centerY);
    }];
    
    [self.videoProgressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.loadedProgressView);
        make.centerY.equalTo(self.loadedProgressView);
    }];
    
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.fullScreenButton.mas_leading).offset(3);
        make.centerY.equalTo(self.playButton.mas_centerY);
        make.width.mas_equalTo(42).priority(700);
    }];

    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.bottomView.mas_trailing).offset(-5);
        make.centerY.equalTo(self.playButton.mas_centerY);
        make.width.height.mas_equalTo(30);
    }];
    
    self.resolutionButton.hidden = YES;
    [self.resolutionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.fullScreenButton);
        make.centerY.equalTo(self.playButton.mas_centerY);
    }];
    
    //------------ 中间
    self.lockButton.hidden = YES;
    [self.lockButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.mas_leading).offset(10);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(32);
    }];
    
    [self.activityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(50);
    }];
    
    self.percentageLabel.alpha = 0.0f;
    [self.percentageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self);
    }];
    
    [self.displayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self);
        make.width.height.mas_offset(156);
    }];
    
    //------------ 完成后
    [self.completedView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.completedButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self).offset(-20);
        make.width.height.mas_offset(50);
    }];
    
    [self.completedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.completedButton.mas_bottom).offset(4);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(30);
    }];
}

//初始化数据
- (void)setupData {
    [self.placeholderImageView sd_setImageWithURL:_videoItem.placeholderImageURL placeholderImage:WYPlayerBundleImageNamed(@"WYPlayer_player_discover_moment@2x.jpg")];
    
    self.titleLabel.text = _videoItem.title;
    self.loadedProgressView.progress = 0;
    self.videoProgressSlider.value = 0;
    self.currentTimeLabel.text = @"00:00";
    self.totalTimeLabel.text = @"00:00";
    self.completedLabel.text = @"重新播放";
    self.panSeekTime = 0;
    
    self.closeButton.hidden = YES;
    self.completedView.hidden = YES;
    self.placeholderImageView.alpha = 1.0f;

    self.dragged = NO;
    self.enterBackground = NO;
    self.lockScreen = NO;
    self.fullScreen = NO;
    self.showCtrlView = NO;
    self.bottomVideo = NO;
    
    //设置通知
    [self setupNotificationCenter];
    
    [self setupGestureRecognizer];
    
    [self updateViewConstraints];
}

// 重置数据
- (void)setupPlayData {
    
    if (self.videoItem.videoURL) {
        self.playerItem = [AVPlayerItem playerItemWithURL:_videoItem.videoURL];
        //重置播放模型
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];

        //播放进度监听
        [self setupMonitoringPlayback];

        if ([self.videoItem.videoURL.scheme isEqualToString:@"file"]) {
            self.playerStatus = WYPlayerStatusPlaying;
        }else {
            self.playerStatus = WYPlayerStatusBuffering;
        }
    }
}

#pragma mark - Setting

//监听播放进度
- (void)setupMonitoringPlayback {
    __weak typeof(self) weakSelf = self;
    self.playTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time) {
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *timeRanges = currentItem.seekableTimeRanges;
        if (timeRanges.count && currentItem.duration.timescale != 0) {
            NSInteger currentTime = (NSInteger)CMTimeGetSeconds([currentItem currentTime]);
            CGFloat totalTime = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            CGFloat value = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
            
            [weakSelf updateCurrentTime:currentTime totalTime:totalTime sliderValue:value];
        }
    }];
}

- (void)setupGestureRecognizer {
    [self.playerView addGestureRecognizer:self.singleTapGesture];
    [self.playerView addGestureRecognizer:self.doubleTapGesture];

    // 解决点击当前view时候响应其他控件事件
    [self.singleTapGesture setDelaysTouchesBegan:YES];
    [self.doubleTapGesture setDelaysTouchesBegan:YES];
    // 双击失败响应单击事件
    [self.singleTapGesture requireGestureRecognizerToFail:self.doubleTapGesture];

    //平移：声音、亮度、播放进度
    [self.playerView addGestureRecognizer:self.panGesetureRecognizer];
}

#pragma mark - NSNotificationCenter

- (void)setupNotificationCenter {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnterForegroundNotification)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    //进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnterBackgroundNotification)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // 监测设备方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];

}


#pragma mark - NSNotificationCenter Actions

- (void)appEnterForegroundNotification {
    [self play];
    [self showControlView];
    self.enterBackground = YES;
}

- (void)appEnterBackgroundNotification {
    [self pause];
    [self playerCancelAutoFadeOutControlView];
    self.enterBackground = NO;
}

- (void)onDeviceOrientationChange {
    //进入后台
    if (self.isEnterBackground) {
        return;
    }
    //锁屏后
    if (self.isLockScreen) {
        return;
    }
    
    if (!self.isShowCtrlView) {
        [self showControlView];
    }
    
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:{
            if (self.isFullScreen) {
                self.fullScreen = NO;
                [self setupOrientationPortraitConstraints:UIInterfaceOrientationPortrait];
                
                [self updateViewConstraints];

                if (self.isBottomVideo) {
                    [self updatePlayerViewToBottomView:NO];
                }
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            if (!self.isFullScreen) {
                self.fullScreen = YES;
            }
            [self setupOrientationLandscapeConstraints:UIInterfaceOrientationLandscapeLeft];
            [self updateViewConstraints];
        }
            break;
        case UIInterfaceOrientationLandscapeRight: {
            if (!self.isFullScreen) {
                self.fullScreen = YES;
            }
            [self setupOrientationLandscapeConstraints:UIInterfaceOrientationLandscapeRight];
            [self updateViewConstraints];
        }
            break;
        default:
            break;
    }
}

- (void)videoPlayToEndTimeNotification:(NSNotification *)notification {
    self.playerStatus = WYPlayerStatusStopped;
    
    if (!self.isDragged) {
        [self hideControlView];
    }
    
    if (self.isBottomVideo) {
        [self removeFromSuperview];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(wy_videoPlayerToEndTime:)]) {
        [self.delegate wy_videoPlayerToEndTime:self];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.playerItem) {
        if ([keyPath isEqualToString:@"status"]) {
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                [self play];
                
                if (self.panSeekTime) {
                    [self seekToTime:self.panSeekTime completionHandler:nil];
                }
            }else if (self.playerItem.status == AVPlayerItemStatusFailed) {
                self.playerStatus = WYPlayerStatusFailed;
            }
            
        }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            [self updateLoadedTimeRanges];
            
        }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            if (self.playerItem.playbackBufferEmpty) {
                self.playerStatus = WYPlayerStatusBuffering;
            }
        }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            //缓冲完成
            if (self.playerItem.playbackLikelyToKeepUp && self.playerStatus == WYPlayerStatusBuffering) {
                self.playerStatus = WYPlayerStatusPlaying;
            }
        }
    }else if (object == self.scrollView) {
        if ([keyPath isEqualToString:@"contentOffset"] ) {
            [self handelBottomVideoWithScrollOffset];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.isBottomVideo) {
        return NO;
    }

    //非横屏状态，不能改变进度条、声音、亮度
    if (!self.isFullScreen && [gestureRecognizer isEqual:self.panGesetureRecognizer]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Public Methods

- (void)playerVideoItem:(WYVideoItem *)videoItem {
    self.videoItem = videoItem;
    
    if (videoItem.scrollView) {
        self.scrollView = videoItem.scrollView;
    }
    
    [self updatePlayerViewToFatherView];
    
    [self updateResolutionView];

    [self setupData];

    if (videoItem.autoPlay) {
        [self setupPlayData];
    }
    
    [self showControlView];
}

- (void)pause {
    self.playButton.selected = NO;
    self.playerStatus = WYPlayerStatusPause;
    
    [self.player pause];
}

- (void)play {
    self.playButton.selected = YES;
    self.playerStatus = WYPlayerStatusPlaying;
    
    if (self.playerItem) {
        [self.player play];
    }else {
        [self setupPlayData];
    }
}

#pragma mark - Private Methods

//更新播放进度
- (void)updateCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value {
    //当前播放时长
    NSInteger proMin = currentTime / 60;//当前秒
    NSInteger proSec = currentTime % 60;//当前分钟
    
    //总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟

    //在拖动的时候，不更新播放进度
    if (!self.isDragged) {
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
        self.videoProgressSlider.value = value;
    }
    //
    self.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
}

//更新拖拽进度
- (void)updateDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd {
    //当前播放时长
    NSInteger proMin = draggedTime / 60;//当前秒
    NSInteger proSec = draggedTime % 60;//当前分钟
    
    //总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟
    
    NSString *currTime = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    NSString *totlTime = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    NSString *percentage = [NSString stringWithFormat:@"%@/%@", currTime, totlTime];
    
    //
    self.currentTimeLabel.text = currTime;
    self.videoProgressSlider.value = draggedTime / (totalTime * 1.0);

    //显示快进多少/倒退多少
    self.percentageLabel.text = percentage;
}

//更新缓冲进度
- (void)updateLoadedTimeRanges {
    NSArray *loadedTimeRanges = [self.playerItem loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval timeInterval     = startSeconds + durationSeconds;//计算缓冲总进度
    
    CMTime duration             = self.playerItem.duration;
    CGFloat totalDuration       = CMTimeGetSeconds(duration);
    
    self.loadedProgressView.progress = timeInterval / totalDuration;
}

//调整到多少秒播放
- (void)seekToTime:(NSInteger)seconds completionHandler:(void (^)(BOOL))completionHandler {
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        //
        [self.activityView startAnimating];
        [self.player pause];
        CMTime time = CMTimeMake(seconds, 1);
        
        __weak typeof(self) weakSelf = self;
        [self.player seekToTime:time toleranceBefore:time toleranceAfter:CMTimeMake(1, 1) completionHandler:^(BOOL finished) {
            [weakSelf.activityView stopAnimating];
            [weakSelf.player play];
            [weakSelf setPlayerStatus:WYPlayerStatusPlaying];
            
            if (completionHandler) {
                completionHandler(finished);
            }
            weakSelf.dragged = NO;
            weakSelf.panSeekTime = 0;
            weakSelf.playButton.selected = YES;
            [weakSelf playerAutoFadeOutControlView];
        }];
    }
}

- (void)updatePlayerViewToFatherView {
    self.transform = CGAffineTransformIdentity;
    if (_videoItem.indexPath) {
        [self removeFromSuperview];
        
        UIView *fatherView = nil;
        if ([self.scrollView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)self.scrollView;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:self.videoItem.indexPath];
            
            fatherView = [cell viewWithTag:self.videoItem.fatherViewTag];
            
        }else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)self.scrollView;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:self.videoItem.indexPath];
            
            fatherView = [cell viewWithTag:self.videoItem.fatherViewTag];
        }
        
        if (fatherView) {
            [fatherView addSubview:self];
            [self mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.edges.mas_equalTo(UIEdgeInsetsZero);
            }];
        }
    }else if (_videoItem.fatherView) {
        [self removeFromSuperview];
        [_videoItem.fatherView addSubview:self];
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
    }
}

- (void)updateViewConstraints {
    if (self.isFullScreen) {
        [self.backButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.topView.mas_leading).offset(5);
            make.top.equalTo(self.topView.mas_top).offset(20);
            make.width.height.mas_equalTo(28);
        }];
        
        self.titleLabel.hidden = NO;
        self.titleLabel.numberOfLines = 1;
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.backButton.mas_trailing).offset(5);
            make.centerY.equalTo(self.backButton.mas_centerY);
            make.trailing.equalTo(self.shareButton.mas_leading).offset(-10);
        }];
        
        [self.shareButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.moreButton.mas_leading).offset(0);
            make.centerY.equalTo(self.backButton.mas_centerY);
            make.width.height.mas_equalTo(32);
        }];
        
        [self.moreButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.topView.mas_trailing).offset(-12);
            make.centerY.equalTo(self.backButton.mas_centerY);
            make.width.height.mas_equalTo(32);
        }];

        [self.fullScreenButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.bottomView.mas_trailing).offset(-5);
            make.centerY.equalTo(self.playButton.mas_centerY);
            make.width.mas_equalTo(50);
            make.height.mas_equalTo(30);
        }];

        [self.displayView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.equalTo(self);
            make.width.height.mas_offset(156);
        }];
        
        self.resolutionButton.hidden = NO;
        self.fullScreenButton.hidden = YES;
        self.lockButton.hidden = NO;

    }else {
        if (_playerViewType == WYPlayerViewTypeDefault) {
            [self.backButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(self.topView.mas_leading).offset(5);
                make.top.equalTo(self.topView.mas_top).offset(3);
                make.width.height.mas_equalTo(28);
            }];
        }else if (_playerViewType == WYPlayerViewTypeCellList) {
            self.titleLabel.hidden = NO;
            
            [self.backButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(self.topView.mas_leading).offset(5);
                make.top.equalTo(self.topView.mas_top).offset(3);
                make.width.mas_equalTo(0);
                make.height.mas_equalTo(28);
            }];
        }else if (_playerViewType == WYPlayerViewTypeCellListNoTitle) {
            self.titleLabel.hidden = YES;
            
            [self.backButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(self.topView.mas_leading).offset(5);
                make.top.equalTo(self.topView.mas_top).offset(3);
                make.width.mas_equalTo(0);
                make.height.mas_equalTo(28);
            }];
        }

        self.titleLabel.numberOfLines = 2;
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.backButton.mas_trailing).offset(5);
            make.top.equalTo(self.backButton.mas_top).offset(3);
            make.trailing.equalTo(self.shareButton.mas_leading).offset(-10);
        }];
        
        [self.shareButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.moreButton.mas_leading).offset(10);
            make.centerY.equalTo(self.backButton.mas_centerY);
            make.width.height.mas_equalTo(0);
        }];
        
        [self.moreButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.topView.mas_trailing).offset(-8);
            make.centerY.equalTo(self.backButton.mas_centerY);
            make.width.height.mas_equalTo(0);
        }];
        
        [self.fullScreenButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.bottomView.mas_trailing).offset(-5);
            make.centerY.equalTo(self.playButton.mas_centerY);
            make.width.height.mas_equalTo(30);
        }];
        
        self.resolutionButton.hidden = YES;
        self.fullScreenButton.hidden = NO;
        self.lockButton.hidden = YES;

    }
    
    [self layoutIfNeeded];
}

//orientation: 主要是为了在小屏状态下，横屏后全屏；然后竖屏后需要再小屏显示
- (void)updatePlayerViewToBottomView:(BOOL)orientation {
    if (self.isBottomVideo && orientation) {
        return;
    }
    
    //在暂停、播放完毕、播放失败时，不显示在底部
    if (self.playerStatus == WYPlayerStatusPause ||
        self.playerStatus == WYPlayerStatusFailed ||
        self.playerStatus == WYPlayerStatusStopped) {
        [self removeFromSuperview];
        return;
    }
    
    self.bottomVideo = YES;
    self.closeButton.hidden = NO;

    self.topView.alpha = 0;
    self.bottomView.alpha = 0;
    self.lockButton.alpha = 0;
    self.showCtrlView = NO;
    [self playerCancelAutoFadeOutControlView];
  
    [self removeFromSuperview];
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    CGFloat width = [[UIScreen mainScreen] bounds].size.width * 0.5 - 20;
    CGFloat heightBy = self.bounds.size.height / self.bounds.size.width;
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width);
        make.height.equalTo(self.mas_width).multipliedBy(heightBy);
        make.bottom.mas_equalTo(0);
        make.trailing.mas_equalTo(width);
    }];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.transform = CGAffineTransformMakeTranslation(-width, 0);
    }];
}

- (void)updatePlayerViewToScrollCellView {
    if (!self.isBottomVideo) {
        return;
    }
    self.bottomVideo = NO;
    self.closeButton.hidden = YES;

    [self showControlView];
    
    [self updatePlayerViewToFatherView];
}

- (void)handelBottomVideoWithScrollOffset {
    if ([self.scrollView isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self.scrollView;
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:self.videoItem.indexPath];
        
        NSArray *visibleCells = tableView.visibleCells;
        //在复用列表中，且正在播放
        if (![visibleCells containsObject:cell]) {
            [self updatePlayerViewToBottomView:YES];
        }else {
            if (self.bottomVideo) {
                [self updatePlayerViewToScrollCellView];
            }
        }
        
    }else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self.scrollView;
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:self.videoItem.indexPath];
        
        NSArray *visibleCells = collectionView.visibleCells;
        //在复用列表中，且正在播放
        if (![visibleCells containsObject:cell]) {
            [self updatePlayerViewToBottomView:YES];
        }else {
            if (self.bottomVideo) {
                [self updatePlayerViewToScrollCellView];
            }
        }
    }
}

- (void)playerCancelAutoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)playerAutoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
    [self performSelector:@selector(hideControlView) withObject:nil afterDelay:WYPlayerHideControlViewDelay];
}

- (void)playerShowOrHideControlView {
    if (self.isShowCtrlView) {
        [self hideControlView];
    } else {
        [self showControlView];
    }
}

//隐藏控制视图
- (void)hideControlView {
    [self playerCancelAutoFadeOutControlView];
    
    //在横屏状态下隐藏或显示状态栏
    if (self.isFullScreen) {
        [WYPlayerManager sharedInstance].statusBarHidden = YES;
        [UIView animateWithDuration:0.25 animations:^{
            [[WYPlayerManager topViewController] setNeedsStatusBarAppearanceUpdate];
        }];
    }
    
    [UIView animateWithDuration:WYPlayerShowControlViewDuration animations:^{
        self.topView.alpha = 0;
        self.bottomView.alpha = 0;
        self.lockButton.alpha = 0;
        self.resolutionView.hidden = YES;
    } completion:^(BOOL finished) {
        self.showCtrlView = NO;
    }];
}

//显示控制视图
- (void)showControlView {
    [self playerCancelAutoFadeOutControlView];
    
    //在横屏状态下隐藏或显示状态栏
    if (self.isFullScreen) {
        [WYPlayerManager sharedInstance].statusBarHidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            [[WYPlayerManager topViewController] setNeedsStatusBarAppearanceUpdate];
        }];
    }
    
    [UIView animateWithDuration:WYPlayerShowControlViewDuration animations:^{
        if (self.lockScreen) {
            self.topView.alpha = 0;
            self.bottomView.alpha = 0;
        }else {
            self.topView.alpha = 1;
            self.bottomView.alpha = 1;
        }
        self.lockButton.alpha = 1;
    } completion:^(BOOL finished) {
        self.showCtrlView = YES;
        [self playerAutoFadeOutControlView];
    }];
}


- (void)updateChangedSeektime:(CGFloat)value {
    self.panSeekTime += value / 200;
    
    CGFloat totalTime = self.playerItem.duration.value / self.playerItem.duration.timescale;
    if (self.panSeekTime > totalTime) {
        self.panSeekTime = totalTime;
    }
    if (self.panSeekTime < 0) {
        self.panSeekTime = 0;
    }
    
    self.dragged = YES;
    [self updateDraggedTime:self.panSeekTime totalTime:totalTime isForward:NO];
}

- (void)updateChangedVolume:(CGFloat)value {
    self.volumeViewSlider.value -= value / 10000;
}

- (void)updateChangedLight:(CGFloat)value {
    [UIScreen mainScreen].brightness -= value / 10000;

}

- (void)updateResolutionView {
    if (_videoItem.resolutionDic.count) {
        //设置分辨率按钮标题；默认高清
        for (NSString *key in [_videoItem.resolutionDic allKeys]) {
            if ([_videoItem.resolutionDic[key] isEqualToString:_videoItem.videoURL.absoluteString]) {
                [self.resolutionButton setTitle:key forState:UIControlStateNormal];
                break;
            }
        }
        
        self.resolutionView.hidden = YES;
        [self addSubview:self.resolutionView];
        
        [self.resolutionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.resolutionButton);
            make.bottom.equalTo(self.resolutionButton.mas_top).offset(2);
            make.width.mas_equalTo(50);
            make.height.mas_equalTo(_videoItem.resolutionDic.count * 30.0);
        }];
        
        NSArray *titles = [_videoItem.resolutionDic allKeys];
        for (NSInteger i = 0; i < titles.count; i++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setFrame:CGRectMake(0, 30.0 * i, 50, 30)];
            [button setTitle:titles[i] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(onTouchChangedResolution:) forControlEvents:UIControlEventTouchUpInside];

            [button.titleLabel setFont:[UIFont systemFontOfSize:12]];
            button.layer.borderColor = [UIColor whiteColor].CGColor;
            button.layer.borderWidth = 0.5;
            
            [self.resolutionView addSubview:button];
        }
    }else {
        [self.resolutionButton setEnabled:NO];
    }
}

#pragma mark - InterfaceOrientation

- (void)interfaceorientation:(UIInterfaceOrientation)interfaceOrientation {
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        [self setupOrientationLandscapeConstraints:interfaceOrientation];
    }else if (interfaceOrientation == UIInterfaceOrientationPortrait){
        [self setupOrientationPortraitConstraints:interfaceOrientation];
    }
}

//重新设置横屏的约束
- (void)setupOrientationLandscapeConstraints:(UIInterfaceOrientation)orientation {
    [self toOrientation:orientation];
}

//重新设置竖屏的约束
- (void)setupOrientationPortraitConstraints:(UIInterfaceOrientation)orientation {
    //重新添加到父视图上
    [self updatePlayerViewToFatherView];
    [self toOrientation:orientation];
}

- (void)toOrientation:(UIInterfaceOrientation)orientation {
    UIInterfaceOrientation currOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (orientation == currOrientation) {
        return;
    }
    
    //想要旋转的方向是横屏
    if (orientation != UIInterfaceOrientationPortrait) {
        //当前方向是竖屏
        if (currOrientation == UIInterfaceOrientationPortrait) {
            [self removeFromSuperview];
            [[UIApplication sharedApplication].keyWindow addSubview:self];
            
            [self mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo([[UIScreen mainScreen] bounds].size.height);
                make.height.mas_equalTo([[UIScreen mainScreen] bounds].size.width);
                make.center.equalTo([UIApplication sharedApplication].keyWindow);
            }];
        }
    }
    
    //设置状态条的方向
    //视图控制器-(BOOL)shouldAutorotate方法必须返回NO，否则设置状态条方向的方法不生效
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];

    //设置播放视图方向
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = [self transformRotationAngle];
    } completion:nil];
}

//获取变换的旋转角度
- (CGAffineTransform)transformRotationAngle {
    // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

#pragma mark - Touch Methods

//横屏点击返回键
- (void)onTouchGotobackAction:(id)sender {
    if (self.isFullScreen) {
        [self onTouchFullScreenAction:nil];
    }else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(wy_dismissViewControllerAnimated:completion:)]) {
            [self.delegate wy_dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)onTouchResolutionAction:(id)sender {
    self.resolutionView.hidden = !self.resolutionView.hidden;
}

- (void)onTouchLockScreenAction:(id)sender {
    UIButton *button = sender;
    button.selected = !button.selected;

    self.lockScreen = button.selected;
    [self showControlView];
}

- (void)onTouchPlayVideoAction:(id)sender {
    UIButton *button = sender;
    button.selected = !button.selected;
    
    //playButton == YES: 用户正在播放
    if (button.selected) {
        [self play];
    }else {
        [self pause];
    }
}

- (void)onTouchFullScreenAction:(id)sender {
    if (self.isFullScreen) {
        [self interfaceorientation:UIInterfaceOrientationPortrait];
        self.fullScreen = NO;
    }else {
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation == UIDeviceOrientationLandscapeRight) {
            [self interfaceorientation:UIInterfaceOrientationLandscapeLeft];
        }else {
            [self interfaceorientation:UIInterfaceOrientationLandscapeRight];
        }
        self.fullScreen = YES;
    }
    [self updateViewConstraints];
}

- (void)onTouchSharedAction:(id)sender {
    
}

- (void)onTouchMoreAction:(id)sender {
    
}

- (void)onTouchReplayAction:(id)sender {
    self.completedView.hidden = YES;
    
    [self setupPlayData];
}

- (void)onTouchCloseVideoAction:(id)sender {
    [self pause];
    
    [self removeFromSuperview];
}

- (void)onTouchSliderBegan:(id)sender {
    self.dragged = YES;
}

- (void)onTouchSliderValueChanged:(id)sender {
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        UISlider *slider = sender;
        
        CGFloat totalTime = (CGFloat)self.playerItem.duration.value / self.playerItem.duration.timescale;
        CGFloat seconds = floor(totalTime * slider.value);

        [self updateDraggedTime:seconds totalTime:totalTime isForward:NO];
    }
}

- (void)onTouchSliderEnd:(id)sender {
    self.dragged = NO;
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        UISlider *slider = sender;
        
        CGFloat totalTime = (CGFloat)self.playerItem.duration.value / self.playerItem.duration.timescale;
        CGFloat seconds = floor(totalTime * slider.value);
        [self seekToTime:seconds completionHandler:nil];
    }
}

- (void)onTouchSingleTapAction:(UITapGestureRecognizer *)gestureRecognizer {
    [self playerShowOrHideControlView];
}

- (void)onTouchDoubleTapAction:(UITapGestureRecognizer *)gestureRecognizer {
    if (self.playerStatus == WYPlayerStatusPlaying) {
        [self pause];
    }else {
        [self play];
    }
}

- (void)onTouchPanAction:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:self.playerView];
    CGPoint veloctyPoint = [gestureRecognizer velocityInView:self.playerView];
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            
            //水平移动
            if (x > y) {
                self.panChangedType = WYPlayerPanChangedSeektime;
                self.percentageLabel.alpha = 1;

                CMTime currTime = self.player.currentTime;
                self.panSeekTime = currTime.value / currTime.timescale;
            //垂直移动
            }else if (x < y) {
                //左边亮度
                if (location.x < [self bounds].size.width / 2) {
                    self.panChangedType = WYPlayerPanChangedLight;
                //右边声音
                }else {
                    self.panChangedType = WYPlayerPanChangedVolume;
                }
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            switch (self.panChangedType) {
                case WYPlayerPanChangedSeektime:
                    [self updateChangedSeektime:veloctyPoint.x];
                    break;
                case WYPlayerPanChangedVolume:
                    [self updateChangedVolume:veloctyPoint.y];
                    break;
                case WYPlayerPanChangedLight:
                    [self updateChangedLight:veloctyPoint.y];
                    break;
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        {
            switch (self.panChangedType) {
                case WYPlayerPanChangedSeektime:
                    [self seekToTime:self.panSeekTime completionHandler:nil];
                    self.percentageLabel.alpha = 0;

                    break;
                case WYPlayerPanChangedVolume:
                    break;
                case WYPlayerPanChangedLight:
                    break;
            }
        }
            break;
        default:
            break;
    }
    
}

- (void)onTouchChangedResolution:(id)sender {
    UIButton *button = sender;
    NSURL *url = [NSURL URLWithString:_videoItem.resolutionDic[button.titleLabel.text]];
    
    if (![_videoItem.videoURL isEqual:url]) {
        self.videoItem.videoURL = url;
        [self.resolutionButton setTitle:button.titleLabel.text forState:UIControlStateNormal];
        
        NSInteger currentTime = (NSInteger)CMTimeGetSeconds([self.player currentTime]);
        self.panSeekTime = currentTime;
        
        [self setupPlayData];
    }
    
    self.resolutionView.hidden = YES;
}

#pragma mark - Setter

- (void)setPlayerStatus:(WYPlayerStatus)playerStatus {
    _playerStatus = playerStatus;
    
    if (playerStatus == WYPlayerStatusBuffering) {
        [self.activityView startAnimating];
    }else {
        [self.activityView stopAnimating];
    }
    
    if (playerStatus == WYPlayerStatusPlaying || playerStatus == WYPlayerStatusBuffering) {
        [UIView animateWithDuration:0.5 animations:^{
            self.placeholderImageView.alpha = 0.0;
        }];
    }
    
    if (playerStatus == WYPlayerStatusFailed || playerStatus == WYPlayerStatusStopped) {
        if (playerStatus == WYPlayerStatusFailed) {
            self.completedLabel.text = @"播放失败，重新播放";
        }
        self.completedView.hidden = NO;
    }
}

- (void)setPlayerViewType:(WYPlayerViewType)playerViewType {
    _playerViewType = playerViewType;
    //默认单个播放器：在小屏状态下，有返回按钮和标题
    //默认列表播放器：在小屏状态下，无返回按钮，有标题
    //无标题列表播放器：在小屏状态下，无返回按钮和标题
    if (playerViewType == WYPlayerViewTypeCellList) {
        self.titleLabel.hidden = NO;
        
        [self.backButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.topView.mas_leading).offset(5);
            make.top.equalTo(self.topView.mas_top).offset(3);
            make.width.mas_equalTo(0);
            make.height.mas_equalTo(28);
        }];

    }else if (playerViewType == WYPlayerViewTypeCellListNoTitle){
        self.titleLabel.hidden = YES;

        [self.backButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.topView.mas_leading).offset(5);
            make.top.equalTo(self.topView.mas_top).offset(3);
            make.width.mas_equalTo(0);
            make.height.mas_equalTo(28);
        }];
    }
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem == playerItem) {
        return;
    }
    
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    
    _playerItem = playerItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(videoPlayToEndTimeNotification:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView == scrollView) {
        return;
    }
    if (_scrollView) {
        [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    _scrollView = scrollView;
    
    if (scrollView) {
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)setFullScreen:(BOOL)fullScreen {
    _fullScreen = fullScreen;
    
    [WYPlayerManager sharedInstance].isLandscape = fullScreen;
    [[WYPlayerManager topViewController] setNeedsStatusBarAppearanceUpdate];

    self.fullScreenButton.selected = fullScreen;
}

#pragma mark - Getter

- (UIView *)playerView {
    if (_playerView == nil) {
        _playerView = [[UIView alloc] init];
        _playerView.backgroundColor = [UIColor blackColor];
    }
    return _playerView;
}

- (UIImageView *)placeholderImageView {
    if (_placeholderImageView == nil) {
        _placeholderImageView = [[UIImageView alloc] init];
        _placeholderImageView.userInteractionEnabled = YES;
    }
    return _placeholderImageView;
}

- (UIView *)topView {
    if (_topView == nil) {
        _topView = [[UIView alloc] init];
    }
    return _topView;
}

- (UIView *)bottomView {
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc] init];
    }
    return _bottomView;
}

- (UIView *)completedView {
    if (_completedView == nil) {
        _completedView = [[UIView alloc] init];
        _completedView.backgroundColor = WYPlayerColorWithRGBA(16, 19, 25, 0.86);
    }
    return _completedView;
}

- (UIView *)resolutionView {
    if (_resolutionView == nil) {
        _resolutionView = [[UIView alloc] init];
        _resolutionView.backgroundColor = WYPlayerColorWithRGBA(0, 0, 0, 0.76);
    }
    return _resolutionView;
}

- (UIButton *)backButton {
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_player_icon_nav_back") forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(onTouchGotobackAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)resolutionButton {
    if (_resolutionButton == nil) {
        _resolutionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _resolutionButton.titleLabel.font = [UIFont systemFontOfSize:12.f];
        [_resolutionButton setTitle:@"高清" forState:UIControlStateNormal];
        [_resolutionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_resolutionButton addTarget:self action:@selector(onTouchResolutionAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resolutionButton;
}

- (UIButton *)lockButton {
    if (_lockButton == nil) {
        _lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_lockButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_player_icon_unlock") forState:UIControlStateNormal];
        [_lockButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_player_icon_lock") forState:UIControlStateSelected];
        [_lockButton addTarget:self action:@selector(onTouchLockScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _lockButton;
}

- (UIButton *)playButton {
    if (_playButton == nil) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_player_ctrl_icon_play") forState:UIControlStateNormal];
        [_playButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_player_ctrl_icon_pause") forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(onTouchPlayVideoAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (UIButton *)closeButton {
    if (_closeButton == nil) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setBackgroundColor:WYPlayerColorWithRGBA(0, 0, 0, 0.4)];
        [_closeButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_player_fullscreen_nav_close") forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(onTouchCloseVideoAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIButton *)fullScreenButton {
    if (_fullScreenButton == nil) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_player_icon_fullscreen") forState:UIControlStateNormal];
        [_fullScreenButton addTarget:self action:@selector(onTouchFullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenButton;
}

- (UIButton *)shareButton {
    if (_shareButton == nil) {
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_fullplayer_icon_share") forState:UIControlStateNormal];
        [_shareButton addTarget:self action:@selector(onTouchSharedAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareButton;
}

- (UIButton *)moreButton {
    if (_moreButton == nil) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_fullplayer_icon_more") forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(onTouchMoreAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (UIButton *)completedButton {
    if (_completedButton == nil) {
        _completedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_completedButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_player_ctrl_icon_replay") forState:UIControlStateNormal];
        [_completedButton addTarget:self action:@selector(onTouchReplayAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _completedButton;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.numberOfLines = 2;
        _titleLabel.font = [UIFont boldSystemFontOfSize:15.f];
    }
    return _titleLabel;
}

- (UILabel *)currentTimeLabel {
    if (_currentTimeLabel == nil) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:10.f];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel {
    if (_totalTimeLabel == nil) {
        _totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.font = [UIFont systemFontOfSize:10.f];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UILabel *)percentageLabel {
    if (_percentageLabel == nil) {
        _percentageLabel = [[UILabel alloc] init];
        _percentageLabel.textColor = [UIColor whiteColor];
        _percentageLabel.font = [UIFont boldSystemFontOfSize:26.f];
        _percentageLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _percentageLabel;
}

- (UILabel *)completedLabel {
    if (_completedLabel == nil) {
        _completedLabel = [[UILabel alloc] init];
        _completedLabel.textColor = [UIColor whiteColor];
        _completedLabel.font = [UIFont systemFontOfSize:15.f];
        _completedLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _completedLabel;
}

- (UIProgressView *)loadedProgressView {
    if (_loadedProgressView == nil) {
        _loadedProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _loadedProgressView.progressTintColor = WYPlayerColorWithRGBA(255, 255, 255, 0.5);
        _loadedProgressView.trackTintColor = WYPlayerColorWithRGBA(0, 0, 0, 0.2);
    }
    return _loadedProgressView;
}

- (UISlider *)videoProgressSlider {
    if (_videoProgressSlider == nil) {
        _videoProgressSlider = [[UISlider alloc] init];
        _videoProgressSlider.minimumTrackTintColor = WYPlayerColorWithRGBA(0, 122, 255, 1);
        _videoProgressSlider.maximumTrackTintColor = [UIColor clearColor];
        
        [_videoProgressSlider setThumbImage:WYPlayerBundleImageNamed(@"WYPlayer_player_icon_slider") forState:UIControlStateNormal];
        
        [_videoProgressSlider addTarget:self action:@selector(onTouchSliderBegan:) forControlEvents:UIControlEventTouchDown];
        [_videoProgressSlider addTarget:self action:@selector(onTouchSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_videoProgressSlider addTarget:self action:@selector(onTouchSliderEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return _videoProgressSlider;
}

- (UIActivityIndicatorView *)activityView {
    if (_activityView == nil) {
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    return _activityView;
}

- (WYPlayerBrightnessView *)displayView {
    if (_displayView == nil) {
        _displayView = [[WYPlayerBrightnessView alloc] initWithFrame:CGRectMake(0, 0, 156, 156)];
    }
    return _displayView;
}

- (UISlider *)volumeViewSlider {
    if (_volumeViewSlider == nil) {
        MPVolumeView *volumeView = [[MPVolumeView alloc] init];
        [[volumeView subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[UISlider class]]) {
                _volumeViewSlider = obj;
                *stop = YES;
            }
        }];
    }
    
    return _volumeViewSlider;
}

- (UITapGestureRecognizer *)singleTapGesture {
    if (_singleTapGesture == nil) {
        _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTouchSingleTapAction:)];
        _singleTapGesture.numberOfTouchesRequired = 1;
        _singleTapGesture.numberOfTapsRequired = 1;
        _singleTapGesture.delegate = self;
    }
    
    return _singleTapGesture;
}

- (UITapGestureRecognizer *)doubleTapGesture {
    if (_doubleTapGesture == nil) {
        _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTouchDoubleTapAction:)];
        _doubleTapGesture.numberOfTouchesRequired = 1; //一个手指
        _doubleTapGesture.numberOfTapsRequired = 2;      //两次
        _doubleTapGesture.delegate = self;
    }

    return _doubleTapGesture;
}

- (UIPanGestureRecognizer *)panGesetureRecognizer {
    if (_panGesetureRecognizer == nil) {
        _panGesetureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onTouchPanAction:)];
        _panGesetureRecognizer.maximumNumberOfTouches = 1;
        _panGesetureRecognizer.delaysTouchesBegan = YES;
        _panGesetureRecognizer.delaysTouchesEnded = YES;
        _panGesetureRecognizer.cancelsTouchesInView = YES;
        _panGesetureRecognizer.delegate = self;
    }

    return _panGesetureRecognizer;
}

@end

#pragma mark - Video Player Rotation

#import <objc/runtime.h>

@implementation UIViewController (WYVideoPlayerRotation)

/**
 * 默认所有都不支持转屏,如需个别页面支持除竖屏外的其他方向，请在viewController重新下边这三个方法
 */

// 是否支持自动转屏
- (BOOL)shouldAutorotate {
    return NO;
}

// 支持哪些屏幕方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

// 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent; // your own style
//}
//
//- (BOOL)prefersStatusBarHidden {
//    return NO; // your own visibility code
//}

@end

@implementation UITabBarController (WYVideoPlayerRotation)

+ (void)load {
    SEL selectors[] = {
        @selector(selectedIndex)
    };
    
    for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
        SEL originalSelector = selectors[index];
        SEL swizzledSelector = NSSelectorFromString([@"zf_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        if (class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    }
}

- (NSInteger)zf_selectedIndex {
    NSInteger index = [self zf_selectedIndex];
    if (index > self.viewControllers.count) { return 0; }
    return index;
}

/**
 * 如果window的根视图是UITabBarController，则会先调用这个Category，然后调用UIViewController+ZFPlayerRotation
 * 只需要在支持除竖屏以外方向的页面重新下边三个方法
 */

// 是否支持自动转屏
- (BOOL)shouldAutorotate {
    UIViewController *vc = self.viewControllers[self.selectedIndex];
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return [nav.topViewController shouldAutorotate];
    } else {
        return [vc shouldAutorotate];
    }
}

// 支持哪些屏幕方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIViewController *vc = self.viewControllers[self.selectedIndex];
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return [nav.topViewController supportedInterfaceOrientations];
    } else {
        return [vc supportedInterfaceOrientations];
    }
}

// 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    UIViewController *vc = self.viewControllers[self.selectedIndex];
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return [nav.topViewController preferredInterfaceOrientationForPresentation];
    } else {
        return [vc preferredInterfaceOrientationForPresentation];
    }
}

@end

@implementation UINavigationController (WYVideoPlayerRotation)

/**
 * 如果window的根视图是UINavigationController，则会先调用这个Category，然后调用UIViewController+ZFPlayerRotation
 * 只需要在支持除竖屏以外方向的页面重新下边三个方法
 */

// 是否支持自动转屏
- (BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

// 支持哪些屏幕方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

// 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

@end

@implementation UIAlertController (WYVideoPlayerRotation)

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations; {
    return UIInterfaceOrientationMaskAll;
}
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}
#endif

@end

