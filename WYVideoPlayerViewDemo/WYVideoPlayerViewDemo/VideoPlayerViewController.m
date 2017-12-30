//
//  VideoPlayerViewController.m
//  WYVideoPlayerViewDemo
//
//  Created by Yangguangliang on 2017/12/30.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "WYVideoPlayerView.h"
#import <Masonry.h>

@interface VideoPlayerViewController ()

@property (nonatomic, strong) UIView *videoPlayerView;          //播放器容器
@property (nonatomic, strong) WYVideoPlayerView *playerView;    //播放器视图
@end

@implementation VideoPlayerViewController

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    if (self.playerView) {
        [self.playerView pause];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];

    if (self.playerView) {
        [self.playerView play];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.videoPlayerView];
    
    [self.videoPlayerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(0);
        make.left.right.equalTo(self.view);
        make.height.equalTo(self.videoPlayerView.mas_width).multipliedBy(9.0/16.0);
    }];
    
    WYVideoItem *item = [[WYVideoItem alloc] init];
    item.title = [self.videoUrl lastPathComponent];
    item.videoURL = [NSURL URLWithString:self.videoUrl];
    item.autoPlay = YES;
    item.fatherView = self.videoPlayerView;
    
    [self.playerView playerVideoItem:item];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)videoPlayerView {
    if (_videoPlayerView == nil) {
        _videoPlayerView = [[UIView alloc] init];
    }
    return _videoPlayerView;
}

- (WYVideoPlayerView *)playerView {
    if (_playerView == nil) {
        _playerView = [[WYVideoPlayerView alloc] init];
    }
    
    return _playerView;
}

//// 返回值要必须为NO
//- (BOOL)shouldAutorotate {
//    return NO;
//}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
