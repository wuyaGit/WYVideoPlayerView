//
//  WYPlayerBrightnessView.m
//  WYVideoPlayerViewDemo
//
//  Created by Yangguangliang on 2018/1/2.
//  Copyright © 2018年 YANGGL. All rights reserved.
//

#import "WYPlayerBrightnessView.h"

@interface WYPlayerBrightnessView()

@property (nonatomic, strong) NSMutableArray *progressArray;
@end

@implementation WYPlayerBrightnessView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        
        //使用UIToolbar实现毛玻璃效果
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        [toolbar setAlpha:0.97];
        [self addSubview:toolbar];
        
        self.progressArray = [NSMutableArray arrayWithCapacity:16];
        self.alpha = 0.0;
        
        [self setupView];
        [self addObserver];
    }
    
    return self;
}

- (void)dealloc {
    [[UIScreen mainScreen] removeObserver:self forKeyPath:@"brightness"];
}

#pragma mark - Setup

- (void)setupView {
    //
    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.bounds.size.width - 90) / 2, 32, 90, 90)];
    backImageView.image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"WYVideoPlayer.bundle/WYPlayer_player_ctrl_icon_brighress@2x.png"]];
    [self addSubview:backImageView];
    
    //
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4, self.bounds.size.width, 30)];
    titleLabel.font = [UIFont boldSystemFontOfSize:15];
    titleLabel.textColor = [UIColor colorWithRed:0.25 green:0.22 blue:0.21 alpha:1];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"亮度";
    [self addSubview:titleLabel];
    
    //
    UIView *progressView = [[UIView alloc]initWithFrame:CGRectMake(13, 132, self.bounds.size.width - 26, 7)];
    progressView.backgroundColor = [UIColor colorWithRed:0.25 green:0.22 blue:0.21 alpha:1];
    [self addSubview:progressView];
    
    //
    CGFloat width = (progressView.frame.size.width - 17) / 16;
    CGFloat height = 5;
    CGFloat y = 1;
    for (NSInteger i = 0; i < 16; i++) {
        UIView *proView = [[UIView alloc] initWithFrame:CGRectMake( i * (width + 1) + 1, y, width, height)];;
        proView.backgroundColor = [UIColor whiteColor];
        [progressView addSubview:proView];
        [self.progressArray addObject:proView];
    }
    
    [self updateProgeressView:[UIScreen mainScreen].brightness];
}

#pragma mark - KVO

- (void)addObserver {
    [[UIScreen mainScreen] addObserver:self
                            forKeyPath:@"brightness"
                               options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    CGFloat brightess = [change[@"new"] floatValue];
    
    [self displayViewWillAppear];
    [self updateProgeressView:brightess];
}

#pragma mark - Private methods

- (void)displayViewWillAppear {
    if (self.alpha == 0.0) {
        self.alpha = 1.0;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self displayViewWillDisappear];
        });
    }
}

- (void)displayViewWillDisappear {
    if (self.alpha == 1.0) {
        [UIView animateWithDuration:1.0 animations:^{
            self.alpha = 0.0;
        }];
    }
}

- (void)updateProgeressView:(CGFloat)value {
    NSInteger level = value * 16.0;
    
    for (NSInteger i = 0; i < self.progressArray.count; i++) {
        UIView *proView = self.progressArray[i];
        
        if (i <= level) {
            proView.hidden = NO;
        }else {
            proView.hidden = YES;
        }
    }
}

@end
