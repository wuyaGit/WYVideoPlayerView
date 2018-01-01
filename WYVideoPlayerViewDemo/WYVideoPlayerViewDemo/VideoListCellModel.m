//
//  VideoListCellModel.m
//  WYVideoPlayerViewDemo
//
//  Created by Yangguangliang on 2017/12/30.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "VideoListCellModel.h"

@implementation VideoListCellModel

- (instancetype)initWithTitle:(NSString *)title
                       author:(NSString *)author
                     videoUrl:(NSString *)videoUrl
                     imageUrl:(NSString *)imageUrl
                     comments:(NSInteger)comments {
    if (self = [super init]) {
        self.title = title;
        self.author = author;
        self.videoUrl = videoUrl;
        self.comments = comments;
        self.imageUrl = imageUrl;
    }
    return self;
}

+ (instancetype)videoCellWithTitle:(NSString *)title
                            author:(NSString *)author
                          videoUrl:(NSString *)videoUrl
                          imageUrl:(NSString *)imageUrl
                          comments:(NSInteger)comments {
    return [[self alloc] initWithTitle:title author:author videoUrl:videoUrl imageUrl:imageUrl comments:comments];
}

@end
