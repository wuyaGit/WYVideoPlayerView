//
//  ViewController.m
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2017/12/27.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "ViewController.h"
#import "WYVideoPlayerView.h"
#import <Masonry.h>

@interface ViewController ()

@property (nonatomic, strong) UIView *videoPlayerView;          //播放器容器
@property (nonatomic, strong) WYVideoPlayerView *playerView;    //播放器视图
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.videoPlayerView];

    [self.videoPlayerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(0);
        make.left.right.equalTo(self.view);
        make.height.equalTo(self.videoPlayerView.mas_width).multipliedBy(9.0/16.0);
    }];

    WYVideoItem *item = [[WYVideoItem alloc] init];
    item.title = @"big_buck_bunny";
    item.videoURL = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
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

// 返回值要必须为NO
- (BOOL)shouldAutorotate {
    return NO;
}

@end
