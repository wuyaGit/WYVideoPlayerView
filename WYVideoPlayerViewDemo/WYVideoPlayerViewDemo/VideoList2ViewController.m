//
//  VideoList2ViewController.m
//  WYVideoPlayerViewDemo
//
//  Created by Yangguangliang on 2017/12/30.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "VideoList2ViewController.h"
#import <UIImageView+WebCache.h>
#import "VideoListCellModel.h"
#import "WYVideoPlayerView.h"

@interface VideoList2ViewController ()

@property (nonatomic, strong) WYVideoPlayerView *playerView;
@property (nonatomic, strong) WYVideoItem *playerViewItem;
@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation VideoList2ViewController

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_playerView) {
        [_playerView pause];
        [_playerView removeFromSuperview];
        
        _playerView = nil;
        _playerViewItem = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 330.0f;
    
    [self createData];
}

//此处必须设置，在横屏状态下隐藏状态栏；否则，横屏状态下点击返回按钮无效，因为被状态栏遮挡了
- (BOOL)prefersStatusBarHidden {
    return self.playerViewItem.statusBarHidden;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)createData {
    self.dataArray = @[[VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/3b99a00a216cf4fbc8fbb07fbcd58f7b_0_0.jpeg"
                                                     comments:2],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_02.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/efb2d3f26118e06bb88be3976cfb5831_0_0.jpeg"
                                                     comments:10],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_03.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/6f34edeed80473c3234db4e561f9d1f3_0_0.jpeg"
                                                     comments:21],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_04.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/2daf93803502bce502c15f73fcd9feec_0_0.jpeg"
                                                     comments:12],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_05.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/c83878ca9ef9c0589345665aa818b717_0_0.jpeg"
                                                     comments:33],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_06.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/4fbad361a5679214bc4e41b79e260b0b_0_0.jpeg"
                                                     comments:25],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_07.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/9ea4b301748105d1e1fcfbfddda84e78_0_0.jpeg"
                                                     comments:6],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_08.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/53b50b87675a0c0134b7c760c5f115f2_0_0.jpeg"
                                                     comments:0],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_09.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/695169b6b4e867a558e2c16ee3d97129_0_0.jpeg"
                                                     comments:10],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_10.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/53170c1097b3614ef6c7e1a3ce25164a_0_0.jpeg"
                                                     comments:1],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_11.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/21912be28e75eaf5cab64e242f89ec91_0_0.jpeg"
                                                     comments:18],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_12.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/11844a5f2ee70ee595a597eb79f875a3_0_0.jpeg"
                                                     comments:20],
                       [VideoListCellModel videoCellWithTitle:@"动画片好看还是武打片好看？看了这个你就知道了"
                                                       author:@"li真瞎"
                                                     videoUrl:@"http://120.25.226.186:32812/resources/videos/minion_13.mp4"
                                                     imageUrl:@"http://img.wdjimg.com/image/video/d536b9c09b2681630afcc92222599f0e_0_0.jpeg"
                                                     comments:29]];
}

#pragma mark - Touch

- (IBAction)playVideo:(id)sender {
    while (![[sender superview] isKindOfClass:[UITableViewCell class]]) {
        sender = [sender superview];
    }
    UITableViewCell *cell = (UITableViewCell *)[sender superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    VideoListCellModel *model = self.dataArray[indexPath.row];

    self.playerViewItem.title = model.title;
    self.playerViewItem.videoURL = [NSURL URLWithString:model.videoUrl];
    self.playerViewItem.indexPath = indexPath;
    self.playerViewItem.scrollView = self.tableView;
    self.playerViewItem.fatherViewTag = 110;
    self.playerViewItem.visibleViewController = self;

    [self.playerView playerVideoItem:self.playerViewItem];
}

#pragma mark - Getter

- (WYVideoPlayerView *)playerView {
    if (_playerView == nil) {
        _playerView = [[WYVideoPlayerView alloc] init];
        _playerView.playerViewType = WYPlayerViewTypeCellList;
    }
    
    return _playerView;
}

- (WYVideoItem *)playerViewItem {
    if (_playerViewItem == nil) {
        _playerViewItem = [[WYVideoItem alloc] init];
        _playerViewItem.scrollView = self.tableView;
        _playerViewItem.autoPlay = YES;
    }
    return _playerViewItem;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    
    VideoListCellModel *model = self.dataArray[indexPath.row];
    
    [(UIImageView *)[cell viewWithTag:110] sd_setImageWithURL:[NSURL URLWithString:model.imageUrl] placeholderImage:[UIImage imageNamed:@"cell_loading_bg"]];
    [(UILabel *)[cell viewWithTag:11] setText:model.title];
    [(UILabel *)[cell viewWithTag:13] setText:[NSString stringWithFormat:@"%@",@(model.comments)]];
    [(UIButton *)[cell viewWithTag:12] setTitle:model.author forState:UIControlStateNormal];
    
    return cell;
}


@end
