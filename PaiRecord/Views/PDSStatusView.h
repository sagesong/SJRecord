//
//  PDSStatusView.h
//  PaiRecord
//
//  Created by Lightning on 15/5/19.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDSStatusView : UIControl

@property (weak, nonatomic) IBOutlet UILabel *timeLable;

@property (weak, nonatomic) IBOutlet UIButton *backBtn;

@property (weak, nonatomic) IBOutlet UIButton *micBtn;

@property (weak, nonatomic) IBOutlet UIButton *flashBtn;

@property (weak, nonatomic) IBOutlet UIButton *cameraBtn;

@property (weak, nonatomic) IBOutlet UIButton *thumbleBtn;

- (void)hideFunctionComponent;
- (void)displayFunctionComponent;
@end
