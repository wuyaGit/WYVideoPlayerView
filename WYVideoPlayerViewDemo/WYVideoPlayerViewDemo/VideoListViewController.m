//
//  VideoListViewController.m
//  WYVideoPlayerViewDemo
//
//  Created by Yangguangliang on 2017/12/30.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "VideoListViewController.h"

@interface VideoListViewController ()

@end

@implementation VideoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"VideoList%@", @(indexPath.row + 1)];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *identifier = [NSString stringWithFormat:@"pushVideoList%@",@(indexPath.row + 1)];
    [self performSegueWithIdentifier:identifier sender:nil];
}

@end
