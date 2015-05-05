//
//  PDSPreviewView.m
//  PaiRecord
//
//  Created by Lightning on 15/5/5.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import "PDSPreviewView.h"


#define BOX_BOUNDS CGRectMake(0.0f, 0.0f, 150, 150.0f)
@interface PDSPreviewView ()

@property (nonatomic, strong) UIView *focusBox;
@property (nonatomic, strong) UIView *exposureBox;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleDoubleTapGesture;

@end


@implementation PDSPreviewView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupViews];
    }
    return self;
}


- (void)setupViews {
    [(AVCaptureVideoPreviewLayer *)self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    
    _singleTapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    
    _doubleTapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    _doubleTapGesture.numberOfTapsRequired = 2;
    
    _doubleDoubleTapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleDoubleTap:)];
    _doubleDoubleTapGesture.numberOfTapsRequired = 2;
    _doubleDoubleTapGesture.numberOfTouchesRequired = 2;
    
    [self addGestureRecognizer:_singleTapGesture];
    [self addGestureRecognizer:_doubleTapGesture];
    [self addGestureRecognizer:_doubleDoubleTapGesture];
    [_singleTapGesture requireGestureRecognizerToFail:_doubleTapGesture];
    
    _focusBox = [self viewWithColor:[UIColor colorWithRed:0.102 green:0.636 blue:1.000 alpha:1.000]];
    _exposureBox = [self viewWithColor:[UIColor colorWithRed:1.000 green:0.421 blue:0.054 alpha:1.000]];
    [self addSubview:_focusBox];
    [self addSubview:_exposureBox];
}

#pragma mark - Tap response

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    [self runBoxAnimationOnView:self.focusBox point:point];
    if ([self.delegate respondsToSelector:@selector(tappedToFocusAtPoint:)]) {
        [self.delegate tappedToFocusAtPoint:[self captureDevicePointForPoint:point]];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    [self runBoxAnimationOnView:self.exposureBox point:point];
    if ([self.delegate respondsToSelector:@selector(tappedToExposeAtPoint:)]) {
        [self.delegate tappedToExposeAtPoint:[self captureDevicePointForPoint:point]];
    }
}

- (void)handleDoubleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    [self runResetAnimation];
    if ([self.delegate respondsToSelector:@selector(tappedToResetFocusAndExposure)]) {
        [self.delegate tappedToResetFocusAndExposure];
    }
}

- (CGPoint)captureDevicePointForPoint:(CGPoint)point {                      // 3
    AVCaptureVideoPreviewLayer *layer =
    (AVCaptureVideoPreviewLayer *)self.layer;
    return [layer captureDevicePointOfInterestForPoint:point];
}

#pragma mark - Box Animation

- (void)runBoxAnimationOnView:(UIView *)view point:(CGPoint)point {
    view.center = point;
    view.hidden = NO;
    [UIView animateWithDuration:0.15f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
                     }
                     completion:^(BOOL complete) {
                         double delayInSeconds = 0.5f;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                             view.hidden = YES;
                             view.transform = CGAffineTransformIdentity;
                         });
                     }];
}

- (void)runResetAnimation {
    if (!self.tapToFocusEnabled && !self.tapToExposeEnabled) {
        return;
    }
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    CGPoint centerPoint = [previewLayer pointForCaptureDevicePointOfInterest:CGPointMake(0.5f, 0.5f)];
    self.focusBox.center = centerPoint;
    self.exposureBox.center = centerPoint;
    self.exposureBox.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
    self.focusBox.hidden = NO;
    self.exposureBox.hidden = NO;
    [UIView animateWithDuration:0.15f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.focusBox.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
                         self.exposureBox.layer.transform = CATransform3DMakeScale(0.7, 0.7, 1.0);
                     }
                     completion:^(BOOL complete) {
                         double delayInSeconds = 0.5f;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                             self.focusBox.hidden = YES;
                             self.exposureBox.hidden = YES;
                             self.focusBox.transform = CGAffineTransformIdentity;
                             self.exposureBox.transform = CGAffineTransformIdentity;
                         });
                     }];
}


- (void)setTapToFocusEnabled:(BOOL)enabled {
    _tapToFocusEnabled = enabled;
    self.singleTapGesture.enabled = enabled;
}

- (void)setTapToExposeEnabled:(BOOL)enabled {
    _tapToExposeEnabled = enabled;
    self.doubleTapGesture.enabled = enabled;
}

- (UIView *)viewWithColor:(UIColor *)color {
    UIView *view = [[UIView alloc] initWithFrame:BOX_BOUNDS];
    view.backgroundColor = [UIColor clearColor];
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 5.0f;
    view.hidden = YES;
    return view;
}

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession*)session {
    return [(AVCaptureVideoPreviewLayer*)self.layer session];
}

- (void)setSession:(AVCaptureSession *)session {
    [(AVCaptureVideoPreviewLayer*)self.layer setSession:session];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
