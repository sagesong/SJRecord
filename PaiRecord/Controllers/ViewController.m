//
//  ViewController.m
//  PaiRecord
//
//  Created by Lightning on 15/5/4.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import "ViewController.h"
#import "PDSCameraViewController.h"
#import "PDSPreviewView.h"
#import "PDSOverLayerView.h"

@interface ViewController ()<PDSPreviewViewDelegate>
- (IBAction)switchCamera:(UIButton *)sender;
- (IBAction)backToPre:(UIButton *)sender;
- (IBAction)switchFlashMode:(UIButton *)sender;
- (IBAction)recordWithMicroOrNot:(UIButton *)sender;
- (IBAction)beginRecordVideo:(UIButton *)sender;
- (IBAction)beginTakingPhoto:(UIButton *)sender;
- (IBAction)stopRecord:(UIButton *)sender;

@property (weak,nonatomic) IBOutlet PDSPreviewView *previewView;
@property (weak, nonatomic) IBOutlet PDSOverLayerView *overLayerView;

@property (nonatomic, strong) PDSCameraViewController *cameraController;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateThumbnail:) name:PDSThumbnailCreatedNotification object:nil];
    
    self.cameraController = [[PDSCameraViewController alloc] init];
    
    NSError *error;
    if ([self.cameraController setupSession:&error]) {
        [self.previewView setSession:self.cameraController.captureSession];
        self.previewView.delegate = self;
        self.cameraController.flashMode = AVCaptureFlashModeOn;
        [self.cameraController startSession];
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    self.previewView.tapToFocusEnabled = self.cameraController.cameraSupportsTapToFocus;
    self.previewView.tapToExposeEnabled = self.cameraController.cameraSupportsTapToExpose;
    
    NSLog(@"%@",self.previewView.subviews);
    self.overLayerView.backgroundColor = [UIColor clearColor];
    
}

- (void)updateThumbnail:(NSNotification *)noti
{
    UIImage *image = [noti object];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tap response
- (IBAction)switchCamera:(UIButton *)sender {
}

- (IBAction)backToPre:(UIButton *)sender {
}

- (IBAction)switchFlashMode:(UIButton *)sender {
    if (self.cameraController.captureSession.isRunning) {
        return;
    }
    self.cameraController.flashMode = self.cameraController.flashMode == AVCaptureFlashModeOn ? AVCaptureFlashModeOff : AVCaptureFlashModeOn;
}

- (IBAction)recordWithMicroOrNot:(UIButton *)sender {
}

- (IBAction)beginRecordVideo:(UIButton *)sender {
    if (!self.cameraController.isRecording) {
        dispatch_async(dispatch_queue_create("PDSgood", NULL), ^{
            [self.cameraController startRecording];
            [self startTimer];
        });
    }
    return;
}

- (void)startTimer
{
    [self.timer invalidate];
    self.overLayerView.statusView.timeLable.hidden = NO;
    self.timer = [NSTimer timerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(updateTimeDisplay)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)updateTimeDisplay
{
    CMTime duration = self.cameraController.recordedDuration;
    NSUInteger time = (NSUInteger)CMTimeGetSeconds(duration);
    NSInteger hours = (time / 3600);
    NSInteger minutes = (time / 60) % 60;
    NSInteger seconds = time % 60;
    
    NSString *format = @"%02i:%02i:%02i";
    NSString *timeString = [NSString stringWithFormat:format, hours, minutes, seconds];
    self.overLayerView.statusView.timeLable.text = timeString;
}

- (IBAction)beginTakingPhoto:(UIButton *)sender {
#warning ToDo two different situations
    [self.cameraController captureStillImage];
}

- (IBAction)stopRecord:(UIButton *)sender {
    [self.cameraController stopRecording];
    [self stopTimer];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.overLayerView.statusView.timeLable.hidden = YES;
    self.timer = nil;
    self.overLayerView.statusView.timeLable.text = @"00:00:00";
}


#pragma mark - PDSPreviewViewDelegate
- (void)tappedToFocusAtPoint:(CGPoint)point
{
    [self.cameraController focusAtPoint:point];
}

- (void)tappedToExposeAtPoint:(CGPoint)point
{
    [self.cameraController exposeAtPoint:point];
}

- (void)tappedToResetFocusAndExposure
{
    [self.cameraController resetFocusAndExposureModes];
}
@end
