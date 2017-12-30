//
//  VideoList1ViewController.m
//  WYVideoPlayerViewDemo
//
//  Created by Yangguangliang on 2017/12/30.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "VideoList1ViewController.h"
#import "VideoPlayerViewController.h"
#import "ViewController.h"

@interface VideoList1ViewController ()

@property (nonatomic, strong) NSArray *videosArray;
@end

@implementation VideoList1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videosArray = @[@"https://media.w3.org/2010/05/sintel/trailer.mp4",
                         @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4",
                         @"http://120.25.226.186:32812/resources/videos/minion_03.mp4",
                         @"http://120.25.226.186:32812/resources/videos/minion_04.mp4",
                         @"http://120.25.226.186:32812/resources/videos/minion_05.mp4",
                         @"http://120.25.226.186:32812/resources/videos/minion_06.mp4"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//// 必须支持转屏，但只是只支持竖屏，否则横屏启动起来页面是横的
//- (BOOL)shouldAutorotate {
//    return YES;
//}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videosArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *videoUrl = self.videosArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", [videoUrl lastPathComponent]];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    VideoPlayerViewController *playerViewController = [[VideoPlayerViewController alloc] init];
    playerViewController.videoUrl = self.videosArray[indexPath.row];
    [self.navigationController pushViewController:playerViewController animated:YES];
}

@end
