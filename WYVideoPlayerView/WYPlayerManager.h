//
//  WYPlayerManager.h
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2018/1/3.
//  Copyright © 2018年 YANGGL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WYPlayerManager : NSObject

/** 状态栏是否隐藏 */
@property (nonatomic, assign) BOOL statusBarHidden;
/** 是否是横屏状态 */
@property (nonatomic, assign) BOOL isLandscape;

+ (instancetype)sharedInstance;

+ (UIViewController *)topViewController;

@end
