//
//  MJRefreshBaseView.m
//  weibo
//
//  Created by mj on 13-3-4.
//  Copyright (c) 2013年 itcast. All rights reserved.
//

#import "MJRefreshBaseView.h"

@interface  MJRefreshBaseView()
// 合理的Y值
- (CGFloat)validY;
// view的类型
- (int)viewType;
@end

@implementation MJRefreshBaseView

#pragma mark - 初始化方法
- (id)initWithScrollView:(UIScrollView *)scrollView
{
    if (self = [super init]) {
        self.scrollView = scrollView;
    }
    return self;
}

#pragma mark 初始化
- (void)initial
{
    // 1.自己的属性
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor clearColor];
    // 2.时间标签
    [self addSubview:_lastUpdateTimeLabel = [self labelWithFont: UISystemFontT8]];
    
    // 3.状态标签
    [self addSubview:_statusLabel = [self labelWithFont:UISystemFontT8]];
    
    // 4.箭头图片
    UIImageView *arrowImage = [[UIImageView alloc] init];
    arrowImage.contentMode = UIViewContentModeScaleAspectFit;
    arrowImage.image = [UIImage imageNamed:@"arrow.png"];
    [self addSubview:_arrowImage = arrowImage];
    
    // 5.指示器
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.hidden = YES;
//    [self addSubview:_activityView = activityView];
    
    // 6.设置默认状态
    [self setState:RefreshStateNormal];
}

- (void)awakeFromNib
{
    [self initial];
}

#pragma mark 构造方法
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initial];
    }
    return self;
}

#pragma mark 创建一个UILabel
- (UILabel *)labelWithFont:(UIFont *)font
{
    UILabel *label = [[UILabel alloc] init];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.font = font;
    label.textColor = [BTCommonUtil setColorWithInt:0x7c7c7c];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

#pragma mark 设置frame
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CGFloat statusY = [BTResource topBarHeight] / 6;
    
    if (frame.size.width == 0 || _statusLabel.frame.origin.y == statusY) return;
    
    // 1.状态标签
    
    CGFloat statusX = 0;
    CGFloat statusHeight = statusY * 4;
    CGFloat statusWidth = self.frame.size.width;
    _statusLabel.frame = CGRectMake(statusX, statusY, statusWidth, statusHeight);
    
    // 2.时间标签
    CGFloat lastUpdateY = statusY * 2 + statusHeight;
    _lastUpdateTimeLabel.frame = CGRectMake(statusX, lastUpdateY, statusWidth, statusHeight);
    
    // 3.箭头
    CGFloat arrowX = statusY * 4;
    _arrowImage.frame = CGRectMake(arrowX, statusY, statusY * 6, statusY * 10);
    
    // 4.指示器
    _activityView.bounds = CGRectMake(0, 0, statusY * 4, statusY * 4);
    _activityView.center = _arrowImage.center;
    
    CGPoint center = _statusLabel.center;
    center.y = _arrowImage.center.y;
    _statusLabel.center = center;
}

#pragma mark - UIScrollView相关
#pragma mark 设置UIScrollView
- (void)setScrollView:(UIScrollView *)scrollView
{
    // 移除之前的监听器
    [_scrollView removeObserver:self forKeyPath:@"contentOffset" context:nil];
    // 设置scrollView
    _scrollView = scrollView;
    [_scrollView addSubview:self];
    // 监听contentOffset
    [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)free
{
    [_scrollView removeObserver:self forKeyPath:@"contentOffset" context:nil];
}

#pragma mark 监听UIScrollView的contentOffset属性
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"contentOffset" isEqualToString:keyPath]) {
        CGFloat offsetY = _scrollView.contentOffset.y * self.viewType;
        CGFloat validY = self.validY;
        if (!self.userInteractionEnabled || self.alpha <= 0.01 || self.hidden
            || _state == RefreshStateRefreshing
            || offsetY <= validY) return;
        
        // 即将刷新 && 手松开
        if (_scrollView.isDragging) {
            //加上49导航栏高度直接刷新不需要转为普通状态
            CGFloat validOffsetY = validY + 49;
            NSLog(@"%lf,%lf",validOffsetY,offsetY);
            if (_state == RefreshStatePulling && offsetY <= validOffsetY) {
                // 转为普通状态
//                [self setState:RefreshStateNormal];
                 [self setState:RefreshStateRefreshing];
            } else if (_state == RefreshStateNormal && offsetY > validOffsetY) {
                // 转为即将刷新状态
                [self setState:RefreshStatePulling];
            }
        } else {
            if (_state == RefreshStatePulling) {
                // 开始刷新
                [self setState:RefreshStateRefreshing];
            }
        }
    }
}

#pragma mark 设置状态
- (void)setState:(RefreshState)state
{
    switch (state) {
		case RefreshStateNormal:
            _arrowImage.hidden = NO;
			[_activityView startAnimating];
			break;
            
        case RefreshStatePulling:
            break;
            
		case RefreshStateRefreshing:
			[_activityView startAnimating];
			_arrowImage.hidden = NO;
            _arrowImage.transform = CGAffineTransformIdentity;
            
            // 通知代理
            if ([_delegate respondsToSelector:@selector(refreshViewBeginRefreshing:)]) {
                [_delegate refreshViewBeginRefreshing:self];
            }
            
            // 回调
            if (_beginRefreshingBlock) {
                _beginRefreshingBlock(self);
            }
			break;
	}
}

#pragma mark - 状态相关
#pragma mark 是否正在刷新
- (BOOL)isRefreshing
{
    return RefreshStateRefreshing == _state;
}
#pragma mark 开始刷新
- (void)beginRefreshing
{
    [self setState:RefreshStateRefreshing];
}
#pragma mark 结束刷新
- (void)endRefreshing
{
    [self setState:RefreshStateNormal];
}

- (CGFloat)validY {
    return 0;
}

- (int)viewType {
    return 0;
}

@end