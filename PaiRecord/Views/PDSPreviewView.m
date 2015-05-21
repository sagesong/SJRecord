//
//  PDSPreviewView.m
//  PaiRecord
//
//  Created by Lightning on 15/5/5.
//  Copyright (c) 2015年 Lightning. All rights reserved.
//

#import "PDSPreviewView.h"


#define BOX_BOUNDS CGRectMake(0.0f, 0.0f, 150, 150.0f)
@interface PDSPreviewView ()<UIGestureRecognizerDelegate>


@property (nonatomic, strong) UIView *focusBox;
@property (nonatomic, strong) UIView *exposureBox;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleDoubleTapGesture;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;

@property (nonatomic, assign) CGFloat lastScale;
@property (nonatomic, assign) CGFloat effectiveScale;
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
    
    NSLog(@"%s",__func__);
    self.userInteractionEnabled = YES;
    self.effectiveScale = 1.0f;

    _singleTapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    
    _doubleTapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    _doubleTapGesture.numberOfTapsRequired = 2;
    
    _doubleDoubleTapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleDoubleTap:)];
    _doubleDoubleTapGesture.numberOfTapsRequired = 2;
    _doubleDoubleTapGesture.numberOfTouchesRequired = 2;
    
    _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _pinchGesture.delegate = self;
    
    
    [self addGestureRecognizer:_singleTapGesture];
    [self addGestureRecognizer:_doubleTapGesture];
    [self addGestureRecognizer:_doubleDoubleTapGesture];
    [self addGestureRecognizer:_pinchGesture];
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
    NSLog(@"%s",__func__);

}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    [self runBoxAnimationOnView:self.exposureBox point:point];
    if ([self.delegate respondsToSelector:@selector(tappedToExposeAtPoint:)]) {
        [self.delegate tappedToExposeAtPoint:[self captureDevicePointForPoint:point]];
    }
    NSLog(@"%s",__func__);

}

- (void)handleDoubleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    [self runResetAnimation];
    if ([self.delegate respondsToSelector:@selector(tappedToResetFocusAndExposure)]) {
        [self.delegate tappedToResetFocusAndExposure];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(cameraZoomDidBegin)]) {
            [self.delegate cameraZoomDidBegin];
        }
    }
    
    _effectiveScale = _lastScale * recognizer.scale;
    if (_effectiveScale < 1.0)
        _effectiveScale = 1.0;
//    CGFloat maxScaleAndCropFactor = [[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceFormat *deviceFormat = [videoDevice activeFormat];
    
    
//    CGFloat maxScaleAndCropFactor = [deviceFormat videoMaxZoomFactor];
    CGFloat maxScaleAndCropFactor = 4.0;
    if (_effectiveScale > maxScaleAndCropFactor)
        _effectiveScale = maxScaleAndCropFactor;
    
    if ([self.delegate respondsToSelector:@selector(cameraZoomChangingWithValue:)]) {
        [self.delegate cameraZoomChangingWithValue:_effectiveScale];
    }
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    [self.layer setAffineTransform:CGAffineTransformMakeScale(_effectiveScale, _effectiveScale)];
    [CATransaction commit];
//    if (recognizer.state == UIGestureRecognizerStateChanged) {
//        if (recognizer.scale < 1.0f && self.lastScale == 1) {
//            return;
//        }
//        CGFloat currentScale = recognizer.scale + self.lastScale - 1.0f;
//        self.transform = CGAffineTransformScale(self.transform, recognizer.scale, recognizer.scale);
//        self.transform = CGAffineTransformMakeScale(<#CGFloat sx#>, <#CGFloat sy#>)
//        NSLog(@"beging scale %f",currentScale);
//        self.lastScale = recognizer.scale;
    
//        if (recognizer.scale <= 1.0f) {
//            if (self.frame.size.width == [UIScreen mainScreen].bounds.size.width) {
//                return;
//            }
//        }
//        if (recognizer.scale + self.lastScale >= 4.0f) {
//            return;
//        }
//        self.transform = CGAffineTransformMakeScale(recognizer.scale + self.lastScale, recognizer.scale + self.lastScale);
////        if () {
////            
////        }
//        NSLog(@"%s--%f----%f",__func__,recognizer.scale,recognizer.velocity);
//        NSLog(@"------%@-----",NSStringFromCGRect(self.frame));

//    }
    
//    if (recognizer.state == UIGestureRecognizerStateEnded) {
//        
//        self.lastScale = recognizer.scale;
//        NSLog(@"end state -- %f",self.lastScale);
//    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.delegate respondsToSelector:@selector(cameraZoomDidEnd)]) {
            [self.delegate cameraZoomDidEnd];
        }
    }
    
    
    NSError *err;
    [videoDevice lockForConfiguration:&err];
    [videoDevice setVideoZoomFactor:_effectiveScale];
    [videoDevice unlockForConfiguration];
    if (err) {
        NSLog(@"%@",[err localizedDescription]);
    }

}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        _lastScale = _effectiveScale;
    }
    return YES;
}

- (CGPoint)captureDevicePointForPoint:(CGPoint)point {                      
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
