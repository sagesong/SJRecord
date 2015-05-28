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

@optional
- (void)recordingWillStart;
- (void)recordingDidStart;
- (void)recordingWillStop;
- (void)recordingDidStop;

- (void)totalRecordingTime:(NSInteger)timeCount formaterString:(NSString *)timeString;

@end


@interface PDSRecordManager : NSObject


singleton_interface(PDSRecordManager)

@property (nonatomic, assign) BOOL enableMicro;
@property (nonatomic, assign) BOOL enableFlash;
@property (nonatomic, assign, getter=isRecording, readonly) BOOL recording;
@property (nonatomic, weak) id<PDSRecordManagerDelegate> delegate;

@property (nonatomic, strong, readonly) AVCaptureSession *captureSession;
@property (nonatomic, strong) NSURL *fileUrl;


/*
 //  设置分辨率
 AVCaptureSessionPresetHigh
 AVCaptureSessionPresetMedium
 AVCaptureSessionPresetLow
 AVCaptureSessionPreset640x480
 AVCaptureSessionPreset1280x720
 AVCaptureSessionPreset1280x720
 //*/
@property (nonatomic, strong) NSString *captureSessionPreset;


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
