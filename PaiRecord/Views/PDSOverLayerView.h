//
//  PDSOverLayerView.h
//  PaiRecord
//
//  Created by Lightning on 15/5/19.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDSStatusView.h"
#import "PDSCameraModeView.h"
@interface PDSOverLayerView : UIView

@property (weak, nonatomic) IBOutlet PDSCameraModeView *cameraModeView;
@property (weak, nonatomic) IBOutlet PDSStatusView *statusView;
@property (nonatomic, weak) IBOutlet UISlider *slider;

- (void)hideFunctionComponent;
- (void)displayFunctionComponent;


@end
