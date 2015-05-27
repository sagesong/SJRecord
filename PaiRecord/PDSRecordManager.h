//
//  PDSRecordManager.h
//  paidashi
//
//  Created by Lightning on 15/5/27.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Singleton.h"
@protocol PDSRecordManagerDelegate <NSObject>

- (void)recordingWillStart;
- (void)recordingDidStart;
- (void)recordingWillStop;
- (void)recordingDidStop;

- (void)totalRecordingTime:(NSInteger)timeCount formaterString:(NSString *)timeString;

@end


@interface PDSRecordManager : NSObject

#warning single to do
singleton_interface(PDSRecordManager)

@property (nonatomic, assign) BOOL enableMicro;
@property (nonatomic, assign) BOOL enableFlash;
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, weak) id<PDSRecordManagerDelegate> delegate;

@property (nonatomic, strong, readonly) AVCaptureSession *captureSession;
@property (nonatomic, strong) NSURL *fileUrl;


//@property (nonatomic, assign)

- (void)switchCamera;
- (void)takeSnap;

- (void)startRecord;
- (void)stopRecord;
- (void)pauseRecord;
- (void)resumeRecord;

- (BOOL)setupSessionContext;
- (void)tearDownSessionContext;



@end
