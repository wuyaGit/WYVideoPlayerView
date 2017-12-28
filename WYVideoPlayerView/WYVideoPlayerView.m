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


@implementation WYVideoItem

@end

@interface WYVideoPlayerView ()

@property (nonatomic, strong) AVPlayer *player;                 //控制器
@property (nonatomic, strong) AVPlayerItem *playerItem;       //模型
@property (nonatomic, strong) AVPlayerLayer *playerLayer;     //视图

@property (nonatomic, strong) UIView *playerView;               //播放视图
@property (nonatomic, strong) UIImageView *topView;             //顶部菜单
@property (nonatomic, strong) UIImageView *bottomView;          //底部进度条

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

@property (nonatomic, strong) id playTimeObserver;


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
        [self resetControlData];
    }
    
    return self;
}


//xib创建调用
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupView];

    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutIfNeeded];
    
    self.playerLayer.frame = self.bounds;
    [UIApplication sharedApplication].statusBarHidden = NO;
    
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
        make.centerY.equalTo(self.playButton.mas_centerY);
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
}

#pragma mark - Setup init data(重置数据)

// 重置数据
- (void)resetControlData {
    
    self.titleLabel.text = @"标题";
    self.loadedProgressView.progress = 0;
    self.videoProgressSlider.value = 0;
    self.currentTimeLabel.text = @"00:00";
    self.totalTimeLabel.text = @"00:00";
    
//    if (self.playTimeObserver) {
//        [self.player removeTimeObserver:self.playTimeObserver];
//        self.playTimeObserver = nil;
//    }
    
    //播放进度监听
    [self monitoringPlayback];
    
    
}

#pragma mark - Setting

//监听播放进度
- (void)monitoringPlayback {
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

#pragma mark - Rotation
//旋转屏幕时调用
//第一次加载调用
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    //添加约束
    [self.playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
}

#pragma mark - NSNotificationCenter

- (void)addNotifications {
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
    //进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // 监测设备方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

}


#pragma mark - NSNotificationCenter Actions

- (void)appEnterForegroundNotification {
    
}

- (void)appEnterBackgroundNotification {
    
}

- (void)onDeviceOrientationChange {
    
}

- (void)videoPlayToEndTimeNotification:(NSNotification *)notification {
    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.playerItem) {
        if ([keyPath isEqualToString:@"status"]) {
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                
                [self.player play];
            }else if (self.playerItem.status == AVPlayerItemStatusFailed) {
                NSLog(@"AVPlayerItemStatusFailed");
            }
            
        }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            [self updateLoadedTimeRanges];
            
        }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            
        }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
        }
    }
}

#pragma mark - Public Methods

- (void)playerVideoItem:(WYVideoItem *)videoItem {
    
    if (videoItem.videoURL) {
        self.playerItem = [AVPlayerItem playerItemWithURL:videoItem.videoURL];
        //重置播放模型
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    
}


- (void)autoPlayVideo {
    
}

- (void)resetPlayer {
    
}

- (void)pause {
    
}

- (void)play {
    
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

    //
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    
    //
    self.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    
    //
    self.videoProgressSlider.value = value;

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

#pragma mark - Touch Methods

- (void)onTouchGobackAction:(id)sender {
    
}

- (void)onTouchLockScreenAction:(id)sender {
    
}

- (void)onTouchPlayVideoAction:(id)sender {
    
}

- (void)onTouchCloseVideoAction:(id)sender {
    
}

#pragma mark - Setter

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区空了，需要等待数据
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区有足够数据可以播放了
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}

#pragma mark - Getter

- (UIView *)playerView {
    if (_playerView == nil) {
        _playerView = [[UIView alloc] init];
        _playerView.backgroundColor = [UIColor blackColor];
    }
    return _playerView;
}

- (UIImageView *)topView {
    if (_topView == nil) {
        _topView = [[UIImageView alloc] init];
        _topView.image =  WYPlayerBundleImageNamed(@"WYPlayer_top_shadow");
    }
    return _topView;
}

- (UIImageView *)bottomView {
    if (_bottomView == nil) {
        _bottomView = [[UIImageView alloc] init];
        _bottomView.image = WYPlayerBundleImageNamed(@"WYPlayer_bottom_shadow");
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
        [_fullScreenButton addTarget:self action:@selector(onTouchCloseVideoAction:) forControlEvents:UIControlEventTouchUpInside];
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
        _videoProgressSlider.minimumTrackTintColor = [UIColor whiteColor];
        _videoProgressSlider.maximumTrackTintColor = [UIColor clearColor];
        _videoProgressSlider.currentThumbImage = WYPlayerBundleImageNamed(@"WYPlayer_slider");
    }
    return _videoProgressSlider;
}



@end
