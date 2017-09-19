//
//  TBSwitch.m
//  TunnelBear
//
//  Created by Rod H on 2014-05-27.
//  Most of this code comes from https://github.com/mattlawer/MBSwitch
//  but added the label and did a few design tweaks
//

#import "TBSwitch.h"


#define IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define THUMB_MARGIN 3
#define THUMB_COLOR [UIColor colorWithRed:237/255.0f green:175/255.0f blue:25/255.0f alpha:1]


static CGFloat const kDecreasedGoldenRatio = 1.2;

@interface TBSwitch () <UIGestureRecognizerDelegate> {
  CAShapeLayer *_thumbLayer;
  CAShapeLayer *_fillLayer;
  CAShapeLayer *_backLayer;
  BOOL _dragging;
  BOOL _on;
  BOOL _squished;
}

@property (strong, nonatomic) CAShapeLayer *knobLayer;
@property (strong, nonatomic) UIImageView *backgroundImageView;
@property (nonatomic, assign) BOOL pressed;

- (void) showFillLayer:(BOOL)show animated:(BOOL)animated;
- (CGRect) thumbFrameForState:(BOOL)isOn;


@end

@implementation TBSwitch

//------------------------------------------------------------------------
#pragma mark -  Properties

- (void)setSwitchState: (TBSwitchState)state
{
  _switchState = state;
  
  [self configureKnob];
}

#pragma mark Init
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    
    [self configure];
    _on = NO;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  if( (self = [super initWithCoder:aDecoder]) ){
    _backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"switch_bg_small"]];
    _backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
    _backgroundImageView.image = [_backgroundImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (self.on)
      [self setBackgroundForConnected:YES];
    else
      [self setBackgroundForConnected:NO];
    
    [self addSubview:_backgroundImageView];
    
  }
  return self;
}

-(void)layoutSubviews {
  [super layoutSubviews];
  [self configure];
}

- (void) configure
{
  _onTintColor = UIColor.whiteColor;
  _thumbTintColor = THUMB_COLOR;
  _offTintColor = UIColor.grayColor;
  _thumbLayer.fillColor = _onTintColor.CGColor;
  
  //Check width > height
  if (self.frame.size.height > self.frame.size.width*0.65) {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, ceilf(0.6*self.frame.size.width));
  }
  
  _backgroundImageView.frame = self.bounds;
  
  [self setBackgroundColor:[UIColor clearColor]];
  
  //  [self setBacklayerOnTintColorIfNeeded];
  
  //  [self setBacklayerTintColorIfNeeded];
  if (!_thumbLayer)
    [self configureThumbLayer];
  else {
    [self.layer addSublayer: _thumbLayer];
    [self configureKnob];
  }
  
  _pressed = NO;
  _dragging = NO;
  
  
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(tapped:)];
  [tapGestureRecognizer setDelegate:self];
  [self addGestureRecognizer:tapGestureRecognizer];
  
  UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(toggleDragged:)];
  [panGestureRecognizer requireGestureRecognizerToFail:tapGestureRecognizer];
  [panGestureRecognizer setDelegate:self];
  [self addGestureRecognizer:panGestureRecognizer];
  
  UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                           action:@selector(longPress:)];
  [longPressGestureRecognizer requireGestureRecognizerToFail:panGestureRecognizer];
  [longPressGestureRecognizer setDelegate:self];
  [self addGestureRecognizer:longPressGestureRecognizer];
  
  [self setClipsToBounds:YES];
}

- (void)configureThumbLayer
{
  _thumbLayer = [CAShapeLayer layer];
  CGFloat height = self.bounds.size.height- (THUMB_MARGIN * 2);
  CGFloat width = self.bounds.size.height-(THUMB_MARGIN * 2);
  CGFloat y = THUMB_MARGIN;
#if  __has_feature(attribute_availability_app_extension)
  CGFloat frameWidth = self.frame.size.width;
  CGFloat x = (!_on) ? THUMB_MARGIN : frameWidth - THUMB_MARGIN - width;
#else
  CGFloat frameWidth = self.frame.size.width;
  CGFloat x = is_left_to_right() ? THUMB_MARGIN
  : frameWidth - THUMB_MARGIN - width;
#endif
  _thumbLayer.frame = CGRectMake(x, y, width, height);
  _thumbLayer.fillColor = _onTintColor.CGColor;
  _thumbLayer.backgroundColor = _onTintColor.CGColor;
  _thumbLayer.cornerRadius = _thumbLayer.frame.size.height/2.0;
  _thumbLayer.shadowColor = [[UIColor blackColor] CGColor];
  _thumbLayer.shadowOffset = (CGSize){ .width = 0.f, .height = 2.f };
  _thumbLayer.shadowRadius = 1.f;
  _thumbLayer.shadowOpacity = 0.3f;
  
  // TODO: use proper circular shape
  CGPathRef knobPath =
  [UIBezierPath
   bezierPathWithRoundedRect: _thumbLayer.bounds
   cornerRadius: floorf(_thumbLayer.bounds.size.height/2.0)].CGPath;
  _thumbLayer.path = knobPath;
  
  [self.layer addSublayer: _thumbLayer];
  
  [self configureKnob];
  
}

- (void)configureKnob
{
  if (self.knobLayer) {
    if (_switchState == TBSwitchStateNormal) {
      _thumbLayer.borderWidth =  5;
      _thumbLayer.borderColor = _onTintColor.CGColor;
      [self.knobLayer removeAllAnimations];
      [self.knobLayer removeFromSuperlayer];
      
    }
    else if (_switchState == TBSwitchStateInProgressIndefinite) {
      [self.knobLayer removeAllAnimations];
      [self.knobLayer removeFromSuperlayer];
      self.knobLayer = nil;
    }
  }
  
  switch (self.switchState) {
      
    case TBSwitchStateNormal:
    {
      self.knobLayer = [CAShapeLayer layer];
      self.knobLayer.frame = _thumbLayer.bounds;
      self.knobLayer.cornerRadius = _thumbLayer.frame.size.height/2.0;
      
      //      _onTintColor = THUMB_COLOR;
      
      if (_on && !_pressed)
        self.knobLayer.fillColor = _thumbTintColor.CGColor;
      else
        self.knobLayer.fillColor = _onTintColor.CGColor;
      
      // TODO: use proper circular shape
      CGPathRef knobPath =
      [UIBezierPath
       bezierPathWithRoundedRect: self.knobLayer.bounds
       cornerRadius: floorf(self.knobLayer.bounds.size.height/2.0)].CGPath;
      self.knobLayer.path = knobPath;
      
      CAMediaTimingFunction *secondLinearCurve =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
      CABasicAnimation *dismissAnimation =
      [CABasicAnimation animationWithKeyPath:@"transform.scale"];
      dismissAnimation.toValue = @0;
      dismissAnimation.duration = 0.55;
      dismissAnimation.timingFunction = secondLinearCurve;
      dismissAnimation.removedOnCompletion = NO;
      dismissAnimation.fillMode = kCAFillModeForwards;
      dismissAnimation.autoreverses =NO;
      [self.knobLayer addAnimation:dismissAnimation forKey:nil];
      [_thumbLayer addSublayer: self.knobLayer];
      
      
      break;
    }
      
    case TBSwitchStateInProgressIndefinite:
    {
      if (_on)
        _thumbLayer.fillColor = _thumbTintColor.CGColor;
      else
        _thumbLayer.fillColor = _onTintColor.CGColor;
      
      CGPoint arcCenter =
      CGPointMake(CGRectGetMidX(_thumbLayer.bounds),
                  CGRectGetMidY(_thumbLayer.bounds));
      CGFloat arcRadius = CGRectGetWidth(_thumbLayer.bounds) / 2 - 2;
      CGFloat strokeThickness = 4;
      UIBezierPath *smoothedPath =
      [UIBezierPath bezierPathWithArcCenter: arcCenter
                                     radius: arcRadius
                                 startAngle: M_PI*3/2
                                   endAngle: M_PI/2+M_PI*5
                                  clockwise: YES];
      self.knobLayer = [CAShapeLayer layer];
      
      self.knobLayer.frame = _thumbLayer.bounds;
      self.knobLayer.fillColor = UIColor.clearColor.CGColor;
      self.knobLayer.strokeColor = _onTintColor.CGColor;
      self.knobLayer.lineWidth = strokeThickness;
      self.knobLayer.lineCap = kCALineCapRound;
      self.knobLayer.lineJoin = kCALineJoinBevel;
      self.knobLayer.path = smoothedPath.CGPath;
      
      self.knobLayer.rasterizationScale = 2.0 * [UIScreen mainScreen].scale;
      self.knobLayer.shouldRasterize = YES;
      
      CALayer *maskLayer = [CALayer layer];
      maskLayer.contents = (id)[UIImage imageNamed: @"angle-mask"].CGImage;
      maskLayer.frame = self.knobLayer.bounds;
      self.knobLayer.mask = maskLayer;
      
      NSTimeInterval animationDuration = 1;
      CAMediaTimingFunction *linearCurve =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
      
      CABasicAnimation *animation =
      [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
      animation.fromValue = 0;
      animation.toValue = [NSNumber numberWithFloat:M_PI*2];
      animation.duration = animationDuration;
      animation.timingFunction = linearCurve;
      animation.removedOnCompletion = NO;
      animation.repeatCount = INFINITY;
      animation.fillMode = kCAFillModeForwards;
      animation.autoreverses = NO;
      [self.knobLayer.mask addAnimation:animation forKey:@"rotate"];
      
      CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
      animationGroup.duration = animationDuration;
      animationGroup.repeatCount = INFINITY;
      animationGroup.removedOnCompletion = NO;
      animationGroup.timingFunction = linearCurve;
      
      CABasicAnimation *strokeStartAnimation =
      [CABasicAnimation animationWithKeyPath:@"strokeStart"];
      strokeStartAnimation.fromValue = @0.015;
      strokeStartAnimation.toValue = @0.515;
      
      CABasicAnimation *strokeEndAnimation =
      [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
      strokeEndAnimation.fromValue = @0.485;
      strokeEndAnimation.toValue = @0.985;
      
      [self.knobLayer addAnimation:animationGroup forKey:@"progress"];
      [_thumbLayer addSublayer: self.knobLayer];
      
      break;
    }
      
  }
  
}


- (void)setBackgroundForConnected:(BOOL)isConnected{
  if (isConnected) {
    
    if (_switchState == TBSwitchStateNormal) {
      _backgroundImageView.tintColor = _thumbTintColor;
      _thumbLayer.fillColor = _onTintColor.CGColor;
    }
    else {
      _backgroundImageView.tintColor = _thumbTintColor;
      _thumbLayer.borderColor = UIColor.clearColor.CGColor;
    }
    
  }
  else {
    if (_switchState == TBSwitchStateNormal) {
      _backgroundImageView.tintColor = _offTintColor;
      _thumbLayer.fillColor = _onTintColor.CGColor;
    }
    else {
      _backgroundImageView.tintColor = _offTintColor;
      _thumbLayer.fillColor = _onTintColor.CGColor;
    }
    
  }
}

#pragma mark Animations

- (BOOL) isOn {
  return _on;
}


- (void) setOn:(BOOL)on {
  if(on) {
    [self setBackgroundForConnected:YES];
    NSLog(@"setting switch to on");
  }
  else {
    [self setBackgroundForConnected:NO];
    NSLog(@"setting switch to off");
  }
}

- (void)setOn: (BOOL)on
     animated: (BOOL)animated
{
  [self setOn: on
     animated: animated
       action: NO];
}

- (void)setOn: (BOOL)on
     animated: (BOOL)animated
       action: (BOOL)action
{
  [self setOn:on animated:animated
       action:action userInteraction:_pressed];
  if (on)
    [self setBackgroundForConnected:YES];
  else
    [self setBackgroundForConnected:NO];
}

- (void)setOn: (BOOL)on
     animated: (BOOL)animated
       action: (BOOL)action
userInteraction: (BOOL)userinteraction
{
  if (userinteraction) {
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName: TBUserInitiatedConnectionNotification object:nil];
  }
  
  if (_on != on) {
    _on = on;
    if (action) {
      [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
  }
  
  [UIView animateWithDuration:0.4
                   animations:^{
                     _thumbLayer.frame = [self thumbFrameForState:_on];
                   }];
  
  [self showFillLayer:!_on animated:animated];
  
  if (!_on) {
    [self showFillLayer:!userinteraction animated:YES];
  }
  self.thumbTintColor = _onTintColor; //the moving loader, should be white
  
}


- (void) showFillLayer:(BOOL)show animated:(BOOL)animated {
  BOOL isVisible = [[_fillLayer valueForKey:@"isVisible"] boolValue];
  if (isVisible != show) {
    [_fillLayer setValue:[NSNumber numberWithBool:show] forKey:@"isVisible"];
    CGFloat scale = show ? 1.0 : 0.0;
    if (animated) {
      CGFloat from = show ? 0.0 : 1.0;
      CABasicAnimation *animateScale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
      animateScale.duration = 0.22;
      animateScale.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(from, from, 1.0)];
      animateScale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scale, scale, 1.0)];
      animateScale.removedOnCompletion = NO;
      animateScale.fillMode = kCAFillModeForwards;
      animateScale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
      
      [_fillLayer addAnimation:animateScale forKey:@"animateScale"];
    }else {
      [_fillLayer removeAllAnimations];
      _fillLayer.transform = CATransform3DMakeScale(scale,scale,1.0);
    }
  }
  
}

- (void) setPressed:(BOOL)pressed {
  if (_pressed != pressed) {
    _pressed = pressed;
    
    if (!_on) {
      [self showFillLayer:!_pressed animated:YES];
    }
  }
}

#pragma mark Appearance


- (void) setOnTintColor:(UIColor *)onTintColor {
  _onTintColor = onTintColor;
  [self setBacklayerOnTintColorIfNeeded];
}

- (void)setBacklayerOnTintColorIfNeeded
{
  if ([[_backLayer valueForKey:@"isOn"] boolValue]) {
    _backLayer.fillColor = [_onTintColor CGColor];
  }
}

- (void) setOffTintColor:(UIColor *)offTintColor {
  _fillLayer.fillColor = [offTintColor CGColor];
  _thumbLayer.fillColor = [offTintColor CGColor];
}


- (void) setThumbTintColor:(UIColor *)thumbTintColor {
  _thumbTintColor = THUMB_COLOR;
  [self setBacklayerThumbTintColorIfNeeded];
  
}
- (void)setBacklayerThumbTintColorIfNeeded
{
  if ([[_backLayer valueForKey:@"isOn"] boolValue]) {
    _backLayer.fillColor = [_onTintColor CGColor];
  }
}


#pragma mark Interaction

- (void)tapped:(UITapGestureRecognizer *)gesture
{
  if (gesture.state == UIGestureRecognizerStateEnded)
    [self setOn: !self.on
       animated: YES
         action: YES];
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
  if (gesture.state == UIGestureRecognizerStateEnded)
    [self setOn: !self.on
       animated: YES
         action: YES];
}

- (void)toggleDragged:(UIPanGestureRecognizer *)gesture
{
  CGFloat minToggleX = 1.0;
  CGFloat maxToggleX = self.bounds.size.width-self.bounds.size.height*kDecreasedGoldenRatio+1.0 + 2 + 2;
  
  if (gesture.state == UIGestureRecognizerStateBegan)
  {
    self.pressed = YES;
    _dragging = YES;
  }
  else if (gesture.state == UIGestureRecognizerStateChanged)
  {
    CGPoint translation = [gesture translationInView:self];
    
    [CATransaction setDisableActions:YES];
    
    self.pressed = YES;
    
    CGFloat newX = _thumbLayer.frame.origin.x + translation.x;
    if (newX < minToggleX) newX = minToggleX;
    if (newX > maxToggleX) newX = maxToggleX;
    _thumbLayer.frame = CGRectMake(newX,
                                   _thumbLayer.frame.origin.y,
                                   _thumbLayer.frame.size.width,
                                   _thumbLayer.frame.size.height);
    [gesture setTranslation:CGPointZero inView:self];
  }
  else if (gesture.state == UIGestureRecognizerStateEnded)
  {
    CGFloat toggleCenter = CGRectGetMidX(_thumbLayer.frame);
#if __has_feature(attribute_availability_app_extension)
    BOOL inOnPosition = (toggleCenter > CGRectGetMidX(self.bounds));
#else
    BOOL inOnPosition = is_left_to_right() ?
    (toggleCenter > CGRectGetMidX(self.bounds)):
    (toggleCenter < CGRectGetMidX(self.bounds));
#endif
    
    [self setOn: inOnPosition
       animated: YES
         action: YES];
    _dragging = NO;
    self.pressed = NO;
  }
  
  CGPoint locationOfTouch = [gesture locationInView:self];
  if (CGRectContainsPoint(self.bounds, locationOfTouch))
    [self sendActionsForControlEvents:UIControlEventTouchDragInside];
  else
    [self sendActionsForControlEvents:UIControlEventTouchDragOutside];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  [super touchesBegan:touches withEvent:event];
  
  self.pressed = YES;
  [self squishThumb];
  [self sendActionsForControlEvents:UIControlEventTouchDown];
  
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  
  [super touchesEnded:touches withEvent:event];
  if (!_dragging) {
    self.pressed = NO;
  }
  
  [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  [super touchesCancelled:touches withEvent:event];
  
  if (!_dragging) {
    self.pressed = NO;
  }
  
  [self sendActionsForControlEvents:UIControlEventTouchUpOutside];
}

- (void)squishThumb {
  
  if (_switchState != TBSwitchStateInProgressIndefinite) {
    self.knobLayer.fillColor = _onTintColor.CGColor;
    _thumbLayer.fillColor = _onTintColor.CGColor;
    if (!self.on)
      _thumbLayer.frame = CGRectMake(_thumbLayer.frame.origin.x,
                                     _thumbLayer.frame.origin.y,
                                     _thumbLayer.frame.size.width*kDecreasedGoldenRatio,
                                     _thumbLayer.frame.size.height);
    
    else
      _thumbLayer.frame = CGRectMake(_thumbLayer.frame.origin.x - (_thumbLayer.frame.size.width*kDecreasedGoldenRatio - _thumbLayer.frame.size.width),
                                     _thumbLayer.frame.origin.y,
                                     _thumbLayer.frame.size.width*kDecreasedGoldenRatio,
                                     _thumbLayer.frame.size.height);
  }
}



#pragma mark Thumb Frame
- (CGRect) thumbFrameForState:(BOOL)isOn {
#if __has_feature(attribute_availability_app_extension)
  return CGRectMake(isOn ? self.bounds.size.width-self.bounds.size.height+THUMB_MARGIN :THUMB_MARGIN,
                    THUMB_MARGIN,
                    self.bounds.size.height-THUMB_MARGIN *2,
                    self.bounds.size.height-THUMB_MARGIN *2);
#else
  if (is_left_to_right())
    return CGRectMake(isOn ? self.bounds.size.width-self.bounds.size.height+THUMB_MARGIN :THUMB_MARGIN,
                      THUMB_MARGIN,
                      self.bounds.size.height-THUMB_MARGIN *2,
                      self.bounds.size.height-THUMB_MARGIN *2);
  else
    return CGRectMake(!isOn ? self.bounds.size.width-self.bounds.size.height+THUMB_MARGIN :THUMB_MARGIN,
                      THUMB_MARGIN,
                      self.bounds.size.height-THUMB_MARGIN *2,
                      self.bounds.size.height-THUMB_MARGIN *2);
#endif
}


@end
