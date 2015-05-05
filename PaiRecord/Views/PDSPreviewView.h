//
//  PDSPreviewView.h
//  PaiRecord
//
//  Created by Lightning on 15/5/5.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol  PDSPreviewViewDelegate <NSObject>

- (void)tappedToFocusAtPoint:(CGPoint)point;
- (void)tappedToExposeAtPoint:(CGPoint)point;
- (void)tappedToResetFocusAndExposure;

@end

@interface PDSPreviewView : UIView

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, weak) id<PDSPreviewViewDelegate> delegate;
@property (nonatomic, assign) BOOL tapToFocusEnabled;
@property (nonatomic, assign) BOOL  tapToExposeEnabled;


@end
