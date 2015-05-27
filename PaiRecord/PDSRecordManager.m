//
//  PDSRecordManager.m
//  paidashi
//
//  Created by Lightning on 15/5/27.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import "PDSRecordManager.h"

@interface PDSRecordManager ()
{
    AVCaptureStillImageOutput *stillImageOutput;
    AVCaptureFileOutput *fileOutput;
}


@end

@implementation PDSRecordManager

singleton_implementation(PDSRecordManager)

- (instancetype)init
{
    if (self = [super init]) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    
    return self;
}


- (void)switchCamera
{
    
}
- (void)takeSnap
{
    
}

- (void)startRecord
{
    
}
- (void)stopRecord
{
    
}
- (void)pauseRecord
{
    
}
- (void)resumeRecord
{
    
}


// 初始化AVCaptureSession 输入 输出
- (BOOL)setupSessionContext
{
    if (!_captureSession) {
        NSLog(@"AVCaptureSessing couldn't alloc");
        return NO;
    }
    // 考虑是否暴漏接口
    _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    // add input
    NSArray * videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (videoDevices.count == 0) {
        NSLog(@"there is no video device");
        return NO;
    }
    AVCaptureDevice *videoDevice = [videoDevices objectAtIndex:0];
    NSError *error = nil;
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"fail with video device input allocation");
    }
    
    if ([_captureSession canAddInput:videoDeviceInput]) {
        [_captureSession addInput:videoDeviceInput];
    } else {
        NSLog(@"AVCaptureSession couldn't add video input");
    }
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (!audioDevice) {
        NSLog(@"there is no audio input");
        return NO;
    }
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"fail with audio device input allocation");
    }
    
    if ([_captureSession canAddInput:audioDeviceInput]) {
        [_captureSession addInput:audioDeviceInput];
    } else {
        NSLog(@"AVCaptureSession couldn't add audio input");
    }
    self.enableMicro = YES;
    
    // add output
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    if ([_captureSession canAddOutput:stillImageOutput]) {
        [_captureSession addOutput:stillImageOutput];
    } else {
        NSLog(@"AVCaptureSession couldn't add stillImageOutput ");
    }
    
    fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if ([_captureSession canAddOutput:fileOutput]) {
        [_captureSession addOutput:fileOutput];
    } else {
        NSLog(@"AVCaptureSession couldn't add FileOutput");
    }
    
    
    [_captureSession startRunning];
    
    return YES;
    
}
- (void)tearDownSessionContext
{
    
}

@end
