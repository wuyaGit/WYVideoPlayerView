//
//  WYVideoPlayerView.m
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2017/12/27.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "WYVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry.h>

#define WYPlayerBundleSourcePath(file) [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"WYVideoPlayer.bundle"] stringByAppendingPathComponent:file]
#define WYPlayerBundleImageNamed(file) [UIImage imageWithContentsOfFile:WYPlayerBundleSourcePath(file)]

#define WYPlayerColorWithRGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

#define WYPlayerHideControlViewDelay    7.f
#define WYPlayerShowControlViewDuration 0.3f


@implementation WYVideoItem

@end

@interface WYVideoPlayerView ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) WYVideoItem *videoItem;

@property (nonatomic, strong) AVPlayer *player;                 //控制器
@property (nonatomic, strong) AVPlayerItem *playerItem;       //模型
@property (nonatomic, strong) AVPlayerLayer *playerLayer;     //视图

@property (nonatomic, strong) UIView *playerView;           //播放视图
@property (nonatomic, strong) UIImageView *topView;             //顶部菜单
@property (nonatomic, strong) UIImageView *bottomView;          //底部进度条
@property (nonatomic, strong) UIView *maskView;             //遮罩视图（工具视图）

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *resolutionButton;       //选择分辨率
@property (nonatomic, strong) UIButton *lockButton;                 //锁定屏幕
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *fullScreenButton;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *totalTimeLabel;
@property (nonatomic, strong) UILabel *fastTimeLabel;           //快进/倒退时间

@property (nonatomic, strong) UIProgressView *loadedProgressView;           //缓冲进度条
@property (nonatomic, strong) UIProgressView *faseProgressView;             //快进/倒退进度条
@property (nonatomic, strong) UISlider *videoProgressSlider;                        //播放进度条

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@property (nonatomic, strong) id playTimeObserver;

@property (nonatomic, getter=isDragged, assign) BOOL dragged; //是否正在拖动
@property (nonatomic, getter=isFullScreen, assign) BOOL fullScreen; //是否是横屏
@property (nonatomic, getter=isLockScreen, assign) BOOL lockScreen; //是否是锁屏状态
@property (nonatomic, getter=isplayDidEnd, assign) BOOL playDidEnd; //播放完成

@property (nonatomic, getter=isEnterBackground, assign) BOOL enterBackground; //是否进入了后台
@property (nonatomic, getter=isShowCtrlView, assign) BOOL showCtrlView; //是否显示控制视图

@end

@implementation WYVideoPlayerView

//https://github.com/cxj3599819/CCNMoviePlayerViewController
//http://blog.csdn.net/u012881779/article/category/2739893/2
//https://www.jianshu.com/p/813a74cc7e41
//http://www.cocoachina.com/ios/20160921/17609.html

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

//    [self addSubview:self.maskView];
    //setup top view
    [self addSubview:self.topView];

    [self.topView addSubview:self.backButton];
    [self.topView addSubview:self.titleLabel];
    [self.topView addSubview:self.resolutionButton];

    //setup bottom view
    [self addSubview:self.bottomView];
    
    [self.bottomView addSubview:self.playButton];
    [self.bottomView addSubview:self.loadedProgressView];
    [self.bottomView addSubview:self.videoProgressSlider];
    [self.bottomView addSubview:self.fullScreenButton];
    [self.bottomView addSubview:self.currentTimeLabel];
    [self.bottomView addSubview:self.totalTimeLabel];
    
    //setup lock button
    [self addSubview:self.lockButton];
    
    //setup activity view
    [self addSubview:self.activityView];
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
    
//    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.mas_equalTo(UIEdgeInsetsZero);
//    }];
    //------------ 顶部
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(self.mas_top).offset(0);
        make.height.mas_equalTo(50);        //顶部视图高50
    }];
    
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.topView.mas_leading).offset(8);
        make.top.equalTo(self.topView.mas_top).offset(3);
        make.width.height.mas_equalTo(40);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.backButton.mas_trailing).offset(5);
        make.centerY.equalTo(self.backButton.mas_centerY);
        make.trailing.equalTo(self.resolutionButton.mas_leading).offset(-10);
    }];
    
    [self.resolutionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.topView.mas_trailing).offset(-10);
        make.centerY.equalTo(self.backButton.mas_centerY);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(25);
    }];
    
    //------------- 底部
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.mas_equalTo(0);
        make.height.mas_equalTo(50);
    }];
    
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bottomView.mas_leading).offset(5);
        make.bottom.equalTo(self.bottomView.mas_bottom).offset(-5);
        make.width.height.mas_equalTo(30);
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
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(4);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-4);
        make.centerY.equalTo(self.playButton.mas_centerY).offset(-1);
        make.height.mas_offset(30);
    }];
    
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.fullScreenButton.mas_leading).offset(3);
        make.centerY.equalTo(self.playButton.mas_centerY);
        make.width.mas_equalTo(42);
    }];
    
    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.bottomView.mas_trailing).offset(-5);
        make.centerY.equalTo(self.playButton.mas_centerY);
        make.width.height.mas_equalTo(30);
    }];
    
    //------------ 中间
    [self.lockButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.mas_leading).offset(15);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(32);
    }];
    
    [self.activityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(50);
    }];
}

//初始化数据
- (void)setupData {
    self.titleLabel.text = _videoItem.title;
    self.loadedProgressView.progress = 0;
    self.videoProgressSlider.value = 0;
    self.currentTimeLabel.text = @"00:00";
    self.totalTimeLabel.text = @"00:00";
    
    self.dragged = NO;
    self.enterBackground = NO;
    self.lockScreen = NO;
    self.fullScreen = NO;
    self.playDidEnd = NO;
    self.showCtrlView = NO;
    
    //设置通知
    [self setupNotificationCenter];
    
    [self setupGestureRecognizer];
}

#pragma mark - Reset data

// 重置数据
- (void)resetPlayData {
    
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
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTouchSingleTapAction:)];
    singleTapGesture.delegate = self;
    singleTapGesture.numberOfTouchesRequired = 1;
    singleTapGesture.numberOfTapsRequired = 1;
    [self.playerView addGestureRecognizer:singleTapGesture];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTouchDoubleTapAction:)];
    doubleTapGesture.delegate = self;
    doubleTapGesture.numberOfTouchesRequired = 1; //一个手指
    doubleTapGesture.numberOfTapsRequired = 2;      //两次
    [self.playerView addGestureRecognizer:doubleTapGesture];

    // 解决点击当前view时候响应其他控件事件
    [singleTapGesture setDelaysTouchesBegan:YES];
    [doubleTapGesture setDelaysTouchesBegan:YES];
    // 双击失败响应单击事件
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
}

#pragma mark - NSNotificationCenter

- (void)setupNotificationCenter {
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
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            if (!self.isFullScreen) {
                self.fullScreen = YES;
            }
            [self setupOrientationLandscapeConstraints:UIInterfaceOrientationLandscapeLeft];
        }
            break;
        case UIInterfaceOrientationLandscapeRight: {
            if (!self.isFullScreen) {
                self.fullScreen = YES;
            }
            [self setupOrientationLandscapeConstraints:UIInterfaceOrientationLandscapeRight];
        }
            break;
        default:
            break;
    }
}

- (void)videoPlayToEndTimeNotification:(NSNotification *)notification {
    self.playerStatus = WYPlayerStatusStopped;
    
    if (self.isFullScreen) {
        self.playDidEnd = NO;
    }else {
        if (!self.isDragged) {
            self.playDidEnd = YES;
            self.showCtrlView = NO;
            [self hideControlView];
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.playerItem) {
        if ([keyPath isEqualToString:@"status"]) {
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                [self play];
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
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    
    return YES;
}

#pragma mark - Public Methods

- (void)playerVideoItem:(WYVideoItem *)videoItem {
    self.videoItem = videoItem;
    
    [self updatePlayerViewToFatherView];
    
    [self setupData];
    
    if (videoItem.autoPlay) {
        [self resetPlayData];
    }
}

- (void)resetPlayer {
    [self setupData];

    [self resetPlayData];
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
        [self resetPlayData];
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
    NSString *percentage = [NSString stringWithFormat:@"%@ / %@", currTime, totlTime];
    
    //
    self.currentTimeLabel.text = currTime;
    self.videoProgressSlider.value = draggedTime / (totalTime * 1.0);

    //显示快进多少/倒退多少
    
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
            
            if (completionHandler) {
                completionHandler(finished);
            }
            weakSelf.playButton.selected = YES;
            [weakSelf playerAutoFadeOutControlView];
        }];
        
    }
}

- (void)updatePlayerViewToFatherView {
    if (_videoItem.fatherView) {
        [self removeFromSuperview];
        [_videoItem.fatherView addSubview:self];
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
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
    [UIView animateWithDuration:WYPlayerShowControlViewDuration animations:^{
        self.topView.alpha = 0;
        self.bottomView.alpha = 0;
        self.lockButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.showCtrlView = NO;
    }];
}

//显示控制视图
- (void)showControlView {
    [self playerCancelAutoFadeOutControlView];
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

- (void)onTouchGobackAction:(id)sender {
    
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
}

- (void)onTouchCloseVideoAction:(id)sender {
    
}

- (void)onTouchSliderBegan:(id)sender {
    self.dragged = YES;
    self.playDidEnd = NO;
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
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (self.playDidEnd) {
            return;
        }else {
            [self playerShowOrHideControlView];
        }
    }
}

- (void)onTouchDoubleTapAction:(UITapGestureRecognizer *)gestureRecognizer {
    if (self.playDidEnd) {
        return;
    }
    
    [self showControlView];
}

#pragma mark - Setter

- (void)setPlayerStatus:(WYPlayerStatus)playerStatus {
    _playerStatus = playerStatus;
    
    if (playerStatus == WYPlayerStatusBuffering) {
        [self.activityView startAnimating];
    }else {
        [self.activityView stopAnimating];
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

- (void)setFullScreen:(BOOL)fullScreen {
    _fullScreen = fullScreen;
    
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

- (UIView *)maskView {
    if (_maskView == nil) {
        _maskView = [[UIView alloc] init];
        _maskView.backgroundColor = WYPlayerColorWithRGBA(0, 0, 0, 0.4);
    }
    return _maskView;
}

- (UIImageView *)topView {
    if (_topView == nil) {
        _topView = [[UIImageView alloc] init];
//        _topView.image =  WYPlayerBundleImageNamed(@"WYPlayer_top_shadow");
        _topView.userInteractionEnabled = YES;
    }
    return _topView;
}

- (UIImageView *)bottomView {
    if (_bottomView == nil) {
        _bottomView = [[UIImageView alloc] init];
//        _bottomView.image = WYPlayerBundleImageNamed(@"WYPlayer_bottom_shadow");
        _bottomView.userInteractionEnabled = YES;
    }
    return _bottomView;
}

- (UIButton *)backButton {
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_back") forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(onTouchGobackAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)resolutionButton {
    if (_resolutionButton == nil) {
        _resolutionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _resolutionButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _resolutionButton.backgroundColor = WYPlayerColorWithRGBA(0, 0, 0, 0.4);
        [_resolutionButton addTarget:self action:@selector(onTouchGobackAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resolutionButton;
}

- (UIButton *)lockButton {
    if (_lockButton == nil) {
        _lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_lockButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_unlock") forState:UIControlStateNormal];
        [_lockButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_lock") forState:UIControlStateSelected];
        [_lockButton addTarget:self action:@selector(onTouchLockScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _lockButton;
}

- (UIButton *)playButton {
    if (_playButton == nil) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_play") forState:UIControlStateNormal];
        [_playButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_pause") forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(onTouchPlayVideoAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (UIButton *)closeButton {
    if (_closeButton == nil) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_close") forState:UIControlStateNormal];
        [_lockButton addTarget:self action:@selector(onTouchCloseVideoAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIButton *)fullScreenButton {
    if (_fullScreenButton == nil) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_fullscreen") forState:UIControlStateNormal];
        [_fullScreenButton setImage:WYPlayerBundleImageNamed(@"WYPlayer_shrinkscreen") forState:UIControlStateSelected];
        [_fullScreenButton addTarget:self action:@selector(onTouchFullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenButton;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:14.f];
    }
    return _titleLabel;
}

- (UILabel *)currentTimeLabel {
    if (_currentTimeLabel == nil) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:12.f];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel {
    if (_totalTimeLabel == nil) {
        _totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.font = [UIFont systemFontOfSize:12.f];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
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
        
        [_videoProgressSlider setThumbImage:WYPlayerBundleImageNamed(@"WYPlayer_slider") forState:UIControlStateNormal];
        
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


@end
