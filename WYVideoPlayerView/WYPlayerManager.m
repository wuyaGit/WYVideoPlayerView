//
//  WYPlayerManager.m
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2018/1/3.
//  Copyright © 2018年 YANGGL. All rights reserved.
//

#import "WYPlayerManager.h"

@implementation WYPlayerManager

+ (instancetype)sharedInstance {
    static WYPlayerManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WYPlayerManager alloc] init];
    });
    return instance;
}

/**
 *  当前viewcontroller
 *
 *  return
 */
+ (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        //返回其选中的控制器
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
        //如果root控制器，是导航控制器类
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* nav = (UINavigationController*)rootViewController;
        //返回其正在运行的控制器
        return [self topViewControllerWithRootViewController:nav.visibleViewController];
        //如果root控制器 现在的控制器 不为空
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        //返回正在运行的控制器
        return [self topViewControllerWithRootViewController:presentedViewController];
        
    } else {
        return rootViewController;
    }
}

@end
