//
//  WYVideoPlayerView.m
//  WYVideoPlayerViewDemo
//
//  Created by YANGGL on 2017/12/27.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "WYVideoPlayerView.h"

@implementation WYVideoPlayerView

//https://github.com/cxj3599819/CCNMoviePlayerViewController
//http://blog.csdn.net/u012881779/article/category/2739893/2
//https://www.jianshu.com/p/813a74cc7e41
//http://www.cocoachina.com/ios/20160921/17609.html

#pragma mark - Initializer

//代码创建调用
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        [self setupView];
    }
    return self;
}


//xib创建调用
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupView];

    }
    return self;
}

//移出内存调用
- (void)dealloc {
    
}

#pragma mark - Setup Methods

//添加视图
- (void)setupView {
    //顶部
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 60)];
    
    [self addSubview:topView];
    
    //中间
    
    //底部
//    UIView *bottomView = [UIView alloc] initWithFrame:CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
}

#pragma mark - Action Methods


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
