//
//  PDSOverLayerView.m
//  PaiRecord
//
//  Created by Lightning on 15/5/19.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import "PDSOverLayerView.h"

@implementation PDSOverLayerView

#pragma mark - init method

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.slider.hidden = NO;
        self.slider.minimumValue = 1.0;
        self.slider.maximumValue = 4.0;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.slider.hidden = NO;
    }
    return self;
}


- (void)hideFunctionComponent
{
    [self.statusView hideFunctionComponent];
}

- (void)displayFunctionComponent
{
    [self.statusView displayFunctionComponent];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self.statusView pointInside:[self convertPoint:point toView:self.statusView] withEvent:event] ||
        [self.cameraModeView pointInside:[self convertPoint:point toView:self.cameraModeView] withEvent:event]) {
        return YES;
    }
    return NO;
}

@end
