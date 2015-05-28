//
//  PDSRecordManager.m
//  paidashi
//
//  Created by Lightning on 15/5/27.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import "PDSRecordManager.h"

@interface PDSRecordManager ()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureStillImageOutput           *_stillImageOutput;
    AVCaptureFileOutput *fileOutput;
    AVCaptureDeviceInput                *_videoDeviceInput;
    AVCaptureDeviceInput                *_audioDeviceInput;
    AVCaptureConnection					*_audioConnection;
    AVCaptureConnection					*_videoConnection;
    
    
    AVAssetWriter						*_assetWriter;
    AVAssetWriterInput					*_assetWriterAudioIn;
    AVAssetWriterInput					*_assetWriterVideoIn;
    dispatch_queue_t                    _movieWritingQueue;
    dispatch_queue_t                    _sessionQueue;
    
    
    NSInteger                           _bitRate;
    NSInteger                           _fps;
    NSInteger                           _width;
    NSInteger                           _height;
    
    NSTimer                             *_timer;
    NSInteger                           _timeCount;
}


@end

@implementation PDSRecordManager

singleton_implementation(PDSRecordManager)

- (instancetype)init
{
    if (self = [super init]) {
        _captureSession = [[AVCaptureSession alloc] init];
        _enableFlash = YES;
        _enableMicro = YES;
        _bitRate = 800;
        _fps = 15;
        _width = 600;
        _height = 450;
        _movieWritingQueue = dispatch_queue_create("Movie writing queue", 0);
        _sessionQueue = dispatch_queue_create("Capture session queue", 0);
        
    }

    return self;
}


- (void)switchCamera
{
    dispatch_async(_sessionQueue, ^{
        AVCaptureDevice *currentVideoDevice = [_videoDeviceInput device];
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
        
        switch (currentPosition) {
            case AVCaptureDevicePositionUnspecified:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
        }
        
        AVCaptureDevice *videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [_captureSession beginConfiguration];
        [_captureSession removeInput:_videoDeviceInput];
        if ([_captureSession canAddInput:videoDeviceInput]) {
            [_captureSession addInput:videoDeviceInput];
        } else {
            [_captureSession addInput:_videoDeviceInput];
        }
        [_captureSession commitConfiguration];
        
        
    });
    
}

- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

- (void)takeSnap
{
    dispatch_async(_sessionQueue, ^{
        [[_stillImageOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:0];
        // ToDo 方向待定
        [_stillImageOutput captureStillImageAsynchronouslyFromConnection:[_stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (imageDataSampleBuffer)
            {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [[UIImage alloc] initWithData:imageData];
//                [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
            }
        }];
        
        
    });
}

- (void)startRecord
{
    [_timer invalidate];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerCallBack) userInfo:nil repeats:YES];
    
    [self resumeRecord];
    NSError *error;
    _assetWriter = [AVAssetWriter assetWriterWithURL:_fileUrl fileType:AVMediaTypeVideo error:&error];
    
    if ([self.delegate respondsToSelector:@selector(recordingWillStart)]) {
        [self.delegate recordingWillStart];
    }
    
    if (error) {
        NSLog(@"Fail with AVAssetWriter allocation");
    }
    
    dispatch_async(_sessionQueue, ^{
        [_captureSession stopRunning];
    });
    
}

#pragma mark - timerCallBack
- (void)timerCallBack
{
    _timeCount++;
    // ToDo time processing
    NSInteger min = _timeCount / 60;
    NSInteger second = _timeCount % 60;
    
    NSString *timeString = [NSString stringWithFormat:@"%02lu:%02lu", (unsigned long)min, (unsigned long)second];
    if ([self.delegate respondsToSelector:@selector(totalRecordingTime:formaterString:)]) {
        [self.delegate totalRecordingTime:_timeCount formaterString:timeString];
    }
}


- (void)stopRecord
{
    [self pauseRecord];
    _timeCount = 0;
    if ([self.delegate respondsToSelector:@selector(recordingWillStop)]) {
        [self.delegate recordingWillStop];
    }
    
    [_assetWriter finishWritingWithCompletionHandler:^{
        if (_assetWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"AVAssetWriterStatusCompleted");
            if ([self.delegate respondsToSelector:@selector(recordingDidStop)]) {
                [self.delegate recordingDidStop];
            }
            
            _recording = NO;
        }
        
        if (_assetWriter.status == AVAssetWriterStatusFailed) {
            NSLog(@"AVAssetWriterStatusFailed %@",_assetWriter.error);
        }
    }];
    
}
- (void)pauseRecord
{
    if ([_captureSession isRunning])
    {
        dispatch_async(_sessionQueue, ^{
            [_captureSession stopRunning];
        });
    }
    
}
- (void)resumeRecord
{
    if (![_captureSession isRunning]) {
        dispatch_async(_sessionQueue, ^{
            [_captureSession startRunning];
        });
        
    }
}


// 初始化AVCaptureSession 输入 输出  运行
- (BOOL)setupSessionContext
{
    _captureSession = [[AVCaptureSession alloc] init];
    
    if (!_captureSession) {
        NSLog(@"AVCaptureSessing couldn't alloc");
        return NO;
    }
    if ([_captureSession canSetSessionPreset:_captureSessionPreset]) {
        [_captureSession setSessionPreset:_captureSessionPreset];
    }
    
    // add input
    NSArray * videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (videoDevices.count == 0) {
        NSLog(@"there is no video device");
        return NO;
    }
    AVCaptureDevice *videoDevice = [videoDevices objectAtIndex:0];
    NSError *error = nil;
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    _videoDeviceInput = videoDeviceInput;
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
    _audioDeviceInput = audioDeviceInput;
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
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    _stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    if ([_captureSession canAddOutput:_stillImageOutput]) {
        [_captureSession addOutput:_stillImageOutput];
    } else {
        NSLog(@"AVCaptureSession couldn't add stillImageOutput ");
    }
    // audio output
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    [audioOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
    
    if ([_captureSession canAddOutput:audioOutput]) {
        [_captureSession addOutput:audioOutput];
    } else {
        NSLog(@"AVCaptureSession couldn't add audioOutput");
    }
    _audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
    // video output
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
    if ([_captureSession canAddOutput:videoOutput]) {
        [_captureSession addOutput:videoOutput];
    } else {
        NSLog(@"AVCaptureSession couldn't add videoOutput");
    }
    
    _videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionStoppedRunningNotification:) name:AVCaptureSessionDidStopRunningNotification object:nil];
    dispatch_async(_sessionQueue, ^{
        [_captureSession startRunning];
    });
    
    
    return YES;
    
}

#pragma mark - AVCaptureSessionDidStopRunningNotification due to external reason
- (void)captureSessionStoppedRunningNotification:(NSNotification *)noti
{
    dispatch_async(_movieWritingQueue, ^{
        if (self.isRecording) {
            [self stopRecord];
        }
    });
}

- (void)tearDownSessionContext
{
    dispatch_async(_sessionQueue, ^{
        [_captureSession stopRunning];
    });
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:nil];
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate video
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFRetain(sampleBuffer);
    assert(_movieWritingQueue);
    dispatch_async(_movieWritingQueue, ^{
        if (connection == _videoConnection) {
            [self setupAssetWriterVideoInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
            [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
        } else if (connection == _audioConnection) {
            [self setupAssetWriterAudioInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
            [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
        }
    });
}

#pragma mark - AssetWriterInput setttings && write sample buffer

- (BOOL)setupAssetWriterVideoInput:(CMFormatDescriptionRef) FormatDescription
{
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(FormatDescription);
    // AVVideoCodecKey, AVVideoWidthKey, and AVVideoHeightKey
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    NSInteger tempWidth = dimensions.width;
    NSInteger tempHeight = dimensions.height;
    // 最小边为450
    //
    if (tempWidth < tempHeight) {
        _width = 450;
        _height = (tempHeight * _width) / tempWidth;
    } else {
        _height = 450;
        _width = (tempWidth * _height) / tempHeight;
    }
    [outputSettings setObject:@(_width) forKey:AVVideoWidthKey];
    [outputSettings setObject:@(_height) forKey:AVVideoHeightKey];
    [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    
    NSMutableDictionary *compressionDict = [NSMutableDictionary dictionary];
    [compressionDict setObject:@(_bitRate * 1000) forKey:AVVideoAverageBitRateKey];
    [compressionDict setObject:@(_fps) forKey:AVVideoMaxKeyFrameIntervalKey];
    [compressionDict setObject:AVVideoProfileLevelH264Baseline31 forKey:AVVideoProfileLevelKey];
    [outputSettings setObject:compressionDict forKey:AVVideoCompressionPropertiesKey];
    
    if (![_assetWriter canApplyOutputSettings:outputSettings forMediaType:AVMediaTypeVideo]) {
        NSLog(@"AVAssetWriter couldn't apply videoOutputSettings");
        return NO;
    }
    _assetWriterVideoIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    _assetWriterVideoIn.expectsMediaDataInRealTime = YES;
    if (![_assetWriter canAddInput:_assetWriterVideoIn]) {
        NSLog(@"AVAssetWriter couldn't add video input");
        return NO;
    }
    [_assetWriter addInput:_assetWriterVideoIn];
    
    
    
    return YES;
}

- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef) FormatDescription
{
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(FormatDescription);
    size_t aclSize = 0;
    const AudioChannelLayout * currentAudioChannelLayout= CMAudioFormatDescriptionGetChannelLayout(FormatDescription, &aclSize);
    NSData *audioChannelData = nil;
    
    if (currentAudioChannelLayout && aclSize > 0) {
        audioChannelData = [NSData dataWithBytes:currentAudioChannelLayout length:aclSize];
    } else {
        audioChannelData = [NSData data];
    }
    // AVFormatIDKey, AVSampleRateKey, and AVNumberOfChannelsKey keys. If no other channel layout information is available, a value of 1 for the AVNumberOfChannelsKey key results in mono output and a value of 2 results in stereo output
    NSMutableDictionary *audioSettings = [NSMutableDictionary dictionary];
    [audioSettings setObject:@(kAudioFormatMPEG4AAC) forKey:AVFormatIDKey];
    [audioSettings setObject:@(currentASBD->mSampleRate) forKey:AVSampleRateKey];
    [audioSettings setObject:@(currentASBD->mChannelsPerFrame) forKey:AVNumberOfChannelsKey];
    [audioSettings setObject:audioChannelData forKey:AVChannelLayoutKey];
    [audioSettings setObject:@(64000) forKey:AVEncoderBitRatePerChannelKey];
    if (![_assetWriter canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio]) {
        NSLog(@"AVAssetWriter couldn't apply audioOutputSettings");
        return NO;
    }
    _assetWriterAudioIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
    _assetWriterAudioIn.expectsMediaDataInRealTime = YES;
    if (![_assetWriter canAddInput:_assetWriterAudioIn]) {
        NSLog(@"AVAssetWriter couldn't add video input");
        return NO;
    }
    [_assetWriter addInput:_assetWriterAudioIn];
    
    return YES;
}

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType
{
    if (_assetWriter.status == AVAssetWriterStatusUnknown) {
        if ([_assetWriter startWriting]) {
            [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        } else {
            NSLog(@"%@",_assetWriter.error);
        }
    }
    
    if (_assetWriter.status == AVAssetWriterStatusWriting) {
        if (mediaType == AVMediaTypeVideo) {
            static NSInteger temp = 0;
            if (temp++ % 2 == 0) {
                return;
            }
            if (_assetWriterVideoIn.readyForMoreMediaData) {
                [_assetWriterVideoIn appendSampleBuffer:sampleBuffer];
            }
        } else if (mediaType == AVMediaTypeAudio) {
            if (_assetWriterAudioIn.readyForMoreMediaData) {
                [_assetWriterAudioIn appendSampleBuffer:sampleBuffer];
            }
        }
    }
}

#pragma mark - mic setting
- (void)setEnableFlash:(BOOL)enableFlash
{
    _enableFlash = enableFlash;
    AVCaptureDevice *videoDevice = [_videoDeviceInput device];
    if (![videoDevice hasFlash]) {
        return;
    }
    NSError *error;
    if ([videoDevice lockForConfiguration:&error]) {
        if (enableFlash) {
            videoDevice.flashMode = AVCaptureFlashModeOn;
        } else {
            videoDevice.flashMode = AVCaptureFlashModeOff;
        }
        [videoDevice unlockForConfiguration];
    } else {
        NSLog(@"%s--%@",__func__,error);
    }
    

    //
}

- (void)setEnableMicro:(BOOL)enableMicro
{
    if (self.recording) {
        NSLog(@"when recording micro couldn't be changed");
        return;
    }
    if (_enableMicro == enableMicro) {
        return;
    }
    _enableMicro = enableMicro;
    if (enableMicro) {
        [_captureSession beginConfiguration];
        [_captureSession addInput:_audioDeviceInput];
        [_captureSession commitConfiguration];
    } else {
        assert(_audioDeviceInput);
        [_captureSession beginConfiguration];
        [_captureSession removeInput:_audioDeviceInput];
        [_captureSession commitConfiguration];
        
    }
    
    
}




@end
