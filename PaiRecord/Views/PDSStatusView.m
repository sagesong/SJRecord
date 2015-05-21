//
//  PDSStatusView.m
//  PaiRecord
//
//  Created by Lightning on 15/5/19.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import "PDSStatusView.h"

@implementation PDSStatusView


- (void)hideFunctionComponent
{
    self.backBtn.hidden = YES;
    self.flashBtn.hidden = YES;
    self.cameraBtn.hidden = YES;
    self.thumbleBtn.hidden = YES;
    self.micBtn.hidden = YES;
}

- (void)displayFunctionComponent
{
    self.backBtn.hidden = NO;
    self.flashBtn.hidden = NO;
    self.cameraBtn.hidden = NO;
    self.thumbleBtn.hidden = NO;
    self.micBtn.hidden = NO;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
