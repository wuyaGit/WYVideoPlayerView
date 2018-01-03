//
//  VideoList3ViewController.m
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2018/1/3.
//  Copyright © 2018年 YANGGL. All rights reserved.
//

#import "VideoList3ViewController.h"
#import <UIImageView+WebCache.h>
#import <Masonry.h>
#import "VideoListCellModel.h"
#import "WYVideoPlayerView.h"

@interface VideoList3ViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) WYVideoPlayerView *playerView;
@property (nonatomic, strong) WYVideoItem *playerViewItem;
@property (nonatomic, strong) NSArray *dataArray;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation VideoList3ViewController

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"listCell" forIndexPath:indexPath];
    
    VideoListCellModel *model = self.dataArray[indexPath.row];
    
    if (![[cell viewWithTag:110] viewWithTag:1997]) {
        [self setupPlayButton:[cell viewWithTag:110]];
    }
    
    [(UILabel *)[cell viewWithTag:1998] setText:model.title];
    [(UIImageView *)[cell viewWithTag:110] sd_setImageWithURL:[NSURL URLWithString:model.imageUrl] placeholderImage:[UIImage imageNamed:@"cell_loading_bg"]];
    
    return cell;
}

#pragma mark - Collection view delegate flowLayout

//Cell设置宽高
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake(self.view.frame.size.width, ((self.view.frame.size.width / 16) * 9 + 70));
}

//两行cell设置 间距（上下行cell的间距）
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    
    return 0.1;
}

//两个cell设置 间距（同一行的cell的间距）
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.1;
}

#pragma mark - Life cycle

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_playerView) {
        [_playerView pause];
        [_playerView removeFromSuperview];
        
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        
    [self createData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [WYPlayerManager sharedInstance].isLandscape ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

//此处必须设置，在横屏状态下隐藏状态栏
- (BOOL)prefersStatusBarHidden {
    return [WYPlayerManager sharedInstance].statusBarHidden;
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

- (void)playVideo:(id)sender {
    while (![[sender superview] isKindOfClass:[UICollectionViewCell class]]) {
        sender = [sender superview];
    }
    UICollectionViewCell *cell = (UICollectionViewCell *)[sender superview];
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    
    VideoListCellModel *model = self.dataArray[indexPath.row];
    
    self.playerViewItem.title = model.title;
    self.playerViewItem.videoURL = [NSURL URLWithString:model.videoUrl];
    self.playerViewItem.placeholderImageURL = [NSURL URLWithString:model.imageUrl];
    self.playerViewItem.indexPath = indexPath;
    self.playerViewItem.scrollView = self.collectionView;
    self.playerViewItem.fatherViewTag = 110;
    
    [self.playerView playerVideoItem:self.playerViewItem];
}

#pragma mark - Private

- (void)setupPlayButton:(UIView *)view {
    UIButton *playButton = [[UIButton alloc] init];
    [playButton setImage:[UIImage imageNamed:@"new_detail_head_play"] forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    [playButton setTag:1997];
    [view addSubview:playButton];
    
    [playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(view);
    }];
    
    UILabel *title = [[UILabel alloc] init];
    [title setTextColor:[UIColor whiteColor]];
    [title setNumberOfLines:2];
    [title setTag:1998];
    [view addSubview:title];
    
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view.mas_top).offset(5);
        make.trailing.leading.equalTo(view).offset(5);
        
    }];
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
        _playerViewItem.autoPlay = YES;
    }
    return _playerViewItem;
    
}

@end
