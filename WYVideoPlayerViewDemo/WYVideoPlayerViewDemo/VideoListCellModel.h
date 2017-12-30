//
//  VideoListCellModel.h
//  WYVideoPlayerViewDemo
//
//  Created by Yangguangliang on 2017/12/30.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoListCellModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, assign) NSInteger comments;

- (instancetype)initWithTitle:(NSString *)title author:(NSString *)author imageUrl:(NSString *)imageUrl comments:(NSInteger)comments;
+ (instancetype)videoCellWithTitle:(NSString *)title author:(NSString *)author imageUrl:(NSString *)imageUrl comments:(NSInteger)comments;

@end
