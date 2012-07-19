//
//  PanningViewController.m
//
//  Created by Frankie Laguna on 3/13/12.
//  Copyright (c) 2012 Frankie Laguna. All rights reserved.
//

typedef enum{
  Panning_Unknown,
  Panning_Vertical, 
  Panning_Horizontal,
} PanningDirection;

static CGFloat const DURATION_OPEN = 0.2f;
static CGFloat const DURATION_CLOSE = 0.2f;

static CGFloat const SLIDE_DISTANCE = 5.0f;

static CGFloat const CORNER_RADIUS = 5.0f;
static CGFloat const CORNER_RADIUS_DEFAULT = 5.0f;

static CGFloat const BOUNCE_DISTANCE = 5.0f;
static CGFloat const BOUNCE_DURATION = 0.2f;

#import "PanningViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface PanningViewController ()
@property(nonatomic, readonly) CGRect bounds;
@property(nonatomic, strong) UIView *centerView;
@property(nonatomic, strong) UIButton *centerCloseButton;

//Ledges
@property(nonatomic, readonly) CGFloat topLedge;
@property(nonatomic, readonly) CGFloat bottomLedge;

@property(nonatomic) PanningDirection panningDirection;

@property(nonatomic) CGPoint panStartOrigin;
@property(nonatomic) CGPoint panViewStartOrigin;

@property(nonatomic, readonly) BOOL leftIsOpen;
@property(nonatomic, readonly) BOOL rightIsOpen;
@property(nonatomic, readonly) BOOL bottomIsOpen;
@property(nonatomic, readonly) BOOL topIsOpen;

@property(nonatomic) BOOL centerDidDisappear;

-(void)configureController:(UIViewController *)controller;

-(void)addCenterController;
-(void)addTopController;
-(void)addLeftController;
-(void)addBottomController;
-(void)addRightController;

//Panning
-(void)addPanner;
-(void)panning:(UIPanGestureRecognizer *)gesture;

-(void)centerWasHidden;

-(void)closeLeftView;
-(void)closeRightView;
-(void)closeTopView;
-(void)closeBottomView;

//Helpers
-(BOOL)isOpen:(UIViewController *)controller;
-(void)addViewController:(UIViewController *)controller;
@end

@implementation PanningViewController
@synthesize centerViewController;
@synthesize centerCloseButton;

@synthesize topViewController, leftViewController;
@synthesize rightViewController, bottomViewController;
@synthesize ledge;

@synthesize panStartOrigin, panViewStartOrigin;
@synthesize centerView;
@synthesize panningDirection;

@dynamic bounds;
@dynamic topLedge, bottomLedge;
@dynamic leftIsOpen, rightIsOpen, topIsOpen, bottomIsOpen;

@synthesize centerDidDisappear;

#pragma mark - Init/Dealloc
-(void)loadView{
  self.view = [[UIView alloc] init];
  [self.view setBackgroundColor:[UIColor blackColor]];
  [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
  [self.view setAutoresizesSubviews:YES];
  [self.view setClipsToBounds:YES];
}

#pragma mark - Getters
-(CGRect)bounds{
  return self.view.bounds;
}

-(CGFloat)statusBarHeight {
  return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) 
  ? [UIApplication sharedApplication].statusBarFrame.size.width 
  : [UIApplication sharedApplication].statusBarFrame.size.height;
}

- (CGRect)slidingRectForOffset:(CGFloat)offset {
  return (CGRect) { 
    {offset, 0}, //CGPoint
    self.bounds.size //CGSize
  };
}

-(BOOL)leftIsOpen{
  return [self isOpen:self.leftViewController];
}

-(BOOL)rightIsOpen{
  return [self isOpen:self.rightViewController];
}

-(BOOL)topIsOpen{
  return [self isOpen:self.topViewController];
}

-(BOOL)bottomIsOpen{
  return [self isOpen:self.bottomViewController];
}

-(CGFloat)topLedge{
  return MAX(CGRectGetHeight(self.topViewController.view.frame) - CORNER_RADIUS, 0);
}

-(CGFloat)bottomLedge{
  return MAX(CGRectGetHeight(self.bottomViewController.view.frame) - CORNER_RADIUS, 0);
}

#pragma mark - View Life Cycle
-(void)viewDidLoad{
  [super viewDidLoad];
  
  self.ledge = 50;
  
  self.centerView = [[UIView alloc] init];
  self.centerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.centerView.autoresizesSubviews = YES;
  self.centerView.clipsToBounds = YES;
  
  [self.view addSubview:self.centerView];
}

-(void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  
  [self addCenterController];
  [self addTopController];
  [self addBottomController];
  [self addLeftController];
  [self addRightController];
  
  [self addPanner];
  
  self.centerView.layer.masksToBounds = NO;
  self.centerView.layer.shadowRadius = 10;
  self.centerView.layer.shadowOpacity = 0.5;
  self.centerView.layer.shadowColor = [[UIColor blackColor] CGColor];
  self.centerView.layer.shadowOffset = CGSizeZero;
  self.centerView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:self.bounds] CGPath];
  
  //Create the center button
  self.centerCloseButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.centerCloseButton setFrame:self.bounds];
  [self.centerCloseButton addTarget:self action:@selector(openCenterView) forControlEvents:UIControlEventTouchUpInside];
}

-(void)viewDidUnload{
  [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
  BOOL shouldRotate = YES;
  
  if(self.centerViewController){
    shouldRotate = [self.centerViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
  }
  
  return shouldRotate;
}

#pragma mark - View Adding
-(void)configureController:(UIViewController *)controller{
  [controller.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
}

-(void)addCenterController{
  self.centerViewController.view.frame = self.bounds;
  
  [self configureController:self.centerViewController];
  
  [self addChildViewController:self.centerViewController];
  [self.centerView addSubview:self.centerViewController.view];
}

-(void)addTopController{
  if(!self.topViewController){ return; }
  
  CGRect frame = self.topViewController.view.frame;
  
  frame.origin.x = 0;
  frame.origin.y = 0;
  frame.size.width = self.bounds.size.width;
  
  [self.topViewController.view setFrame:frame];
  
  [self addViewController:self.topViewController];
}

-(void)addLeftController{
  if(!self.leftViewController){ return; }
  
  CGRect frame = self.leftViewController.view.frame;
  
  frame.origin.x = 0;
  frame.origin.y = 0;
  frame.size = self.bounds.size;
  
  [self.leftViewController.view setFrame:frame];
  
  [self addViewController:self.leftViewController];
}

-(void)addBottomController{
  if(!self.bottomViewController){ return; }
  
  CGRect frame = self.bottomViewController.view.frame;
  
  frame.origin.x = 0;
  frame.origin.y = self.bounds.size.height - frame.size.height;
  frame.size.width = self.bounds.size.width;

  [self.bottomViewController.view setFrame:frame];
  
  [self addViewController:self.bottomViewController];
}

-(void)addRightController{
  if(!self.rightViewController){ return; }
  
  CGRect frame = self.rightViewController.view.frame;
  
  frame.size = self.bounds.size;
  frame.origin.x = (self.bounds.size.width - frame.size.width);
  frame.origin.y = 0;
  
  [self.rightViewController.view setFrame:frame];
  
  [self addViewController:self.rightViewController];
}

#pragma mark - Opening
-(void)openLeftView{    
  NSTimeInterval duration = DURATION_CLOSE;
  
  if(self.centerView.frame.origin.y == 0){
    duration = 0;
  }
  
  [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    if(self.centerView.frame.origin.y != 0){
      CGRect centerFrame = self.bounds;
      centerFrame.origin.y = 0;
      
      [self.centerView setFrame:centerFrame];
    }
  } completion:^(BOOL finished){    
    [UIView animateWithDuration:DURATION_OPEN delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      [self.leftViewController.view setHidden:NO];
      
      CGRect centerFrame = self.bounds;
      centerFrame.origin.x = self.bounds.size.width - self.ledge;
      
      [self.centerView setFrame:centerFrame];
    } completion:^(BOOL finished){
      [self centerWasHidden];
    }];
  }];
}

-(void)openRightView{
  NSTimeInterval duration = DURATION_CLOSE;
  
  if(self.centerView.frame.origin.y == 0){
    duration = 0;
  }
  
  [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    if(self.centerView.frame.origin.y != 0){
      CGRect centerFrame = self.bounds;
      centerFrame.origin.y = 0;
      
      [self.centerView setFrame:centerFrame];
    }
  } completion:^(BOOL finished){
    [UIView animateWithDuration:DURATION_OPEN delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      [self.rightViewController.view setHidden:NO];
      
      CGRect centerFrame = self.bounds;
      centerFrame.origin.x = self.ledge - self.bounds.size.width;
      
      [self.centerView setFrame:centerFrame];
    } completion:^(BOOL finished){
      [self centerWasHidden];
    }];
  }];
}

-(void)openTopView{  
  if(self.centerView.frame.origin.y == self.topLedge){ return; }
  
  NSTimeInterval duration = DURATION_CLOSE;
  
  if(self.centerView.frame.origin.x == 0){
    duration = 0;
  }
  
  [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    if(self.centerView.frame.origin.x != 0){
      CGRect centerFrame = self.bounds;
      centerFrame.origin.x = 0;
      
      [self.centerView setFrame:centerFrame];
    }
  } completion:^(BOOL finished){
      [UIView animateWithDuration:DURATION_OPEN delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.topViewController.view setHidden:NO];
        
        CGRect centerFrame = self.bounds;
        centerFrame.origin.y = self.topLedge + BOUNCE_DISTANCE;
        
        [self.centerView setFrame:centerFrame];
      } completion:^(BOOL finished){
        //Finished the bounce
        [UIView animateWithDuration:BOUNCE_DURATION animations:^{
          CGRect centerFrame = self.bounds;
          centerFrame.origin.y = self.topLedge;
          
          [self.centerView setFrame:centerFrame];
        
        } completion:^(BOOL finished){
          [self centerWasHidden];          
        }];

      }];
  }];
}

-(void)openBottomView{  
  NSTimeInterval duration = DURATION_CLOSE;
  
  if(self.centerView.frame.origin.x == 0){
    duration = 0;
  }
    
  [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    if(self.centerView.frame.origin.x != 0){
      CGRect centerFrame = self.bounds;
      centerFrame.origin.x = 0;
      
      [self.centerView setFrame:centerFrame];
    }
  } completion:^(BOOL finished){    
    [self.centerViewController viewWillDisappear:NO];
    
    [UIView animateWithDuration:DURATION_OPEN delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      [self.bottomViewController viewWillAppear:NO];
      [self.bottomViewController.view setHidden:NO];
      
      CGRect centerFrame = self.bounds;
      centerFrame.origin.y = -self.bottomLedge;
      
      [self.centerView setFrame:centerFrame];
    } completion:^(BOOL finished){
      [self centerWasHidden];
    }];
  }];
}

-(void)openCenterView{  
  //Left is open
  if(self.leftIsOpen){
    [self closeLeftView];
  }
  
  //Is the right open?
  if(self.rightIsOpen){
    [self closeRightView];
  }
  
  //Is the top open?
  if(self.topIsOpen){
    [self closeTopView];
  }

  //Is the bottom open?
  if(self.bottomIsOpen){
    [self closeBottomView];
  }

  if(self.centerDidDisappear){
    [self.centerViewController viewWillAppear:NO];
    [self.centerViewController.view.layer setCornerRadius:CORNER_RADIUS_DEFAULT];
    [self.centerCloseButton removeFromSuperview];
    
    [self setCenterDidDisappear:NO];
  }
}

#pragma mark - Closing
-(void)closeLeftView{
  [UIView animateWithDuration:DURATION_CLOSE delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
    CGRect centerFrame = self.bounds;
    centerFrame.origin.x = 0;
    
    [self.centerView setFrame:centerFrame];
    
  } completion:^(BOOL finished){
    [self.leftViewController.view setHidden:YES];
  }];
}

-(void)closeRightView{
  [UIView animateWithDuration:DURATION_CLOSE delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
    CGRect centerFrame = self.bounds;
    centerFrame.origin.x = 0;
    
    [self.centerView setFrame:centerFrame];
    
  } completion:^(BOOL finished){
    [self.rightViewController.view setHidden:YES];
  }];
}

-(void)closeTopView{
  [UIView animateWithDuration:DURATION_CLOSE delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
    CGRect centerFrame = self.bounds;
    centerFrame.origin.y = 0;
    
    [self.centerView setFrame:centerFrame];
    
  } completion:^(BOOL finished){
    [self.topViewController.view setHidden:YES];
  }];
}

-(void)closeBottomView{
  [UIView animateWithDuration:DURATION_CLOSE delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
    CGRect centerFrame = self.bounds;
    centerFrame.origin.y = 0;
    
    [self.centerView setFrame:centerFrame];
    
  } completion:^(BOOL finished){
    [self.bottomViewController viewWillDisappear:NO];
    [self.bottomViewController.view setHidden:YES];
  }];
}

#pragma mark - UIGestureRecognizerDelegate & Gestures
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
  self.panStartOrigin = self.centerView.frame.origin;
  self.panViewStartOrigin = self.bounds.origin;
  
  return YES;
}

#pragma mark - Panning
-(void)panning:(UIPanGestureRecognizer *)gesture{
  CGPoint currentPoint = [gesture translationInView:self.view];
  
  CGFloat x = currentPoint.x + self.panStartOrigin.x;
  CGFloat y = currentPoint.y + self.panStartOrigin.y;
  CGFloat width = self.bounds.size.width;
  CGFloat height = self.bounds.size.height;
  
  if (!self.leftViewController){ 
    x = MIN(0, x);
  }
  
  if (!self.rightViewController){ 
    x = MAX(0, x);
  }
  
  if (!self.topViewController){ 
    y = MIN(0, y);
  }

  if(!self.bottomViewController){
    y = MAX(0, y);
  }
  
  CGRect centerFrame = self.centerView.frame;
  
  if(
     (!self.leftIsOpen && !self.rightIsOpen) && 
     (self.panningDirection == Panning_Unknown || self.panningDirection == Panning_Vertical) && 
     (self.panViewStartOrigin.y > currentPoint.y || self.panViewStartOrigin.y < currentPoint.y) &&
     (ABS(self.panViewStartOrigin.y - currentPoint.y) > SLIDE_DISTANCE)
  ){
    centerFrame.origin.y = MAX(MIN(y, self.topLedge), -self.bottomLedge);
    
    self.panningDirection = Panning_Vertical;
    
    //Show hide top/bottom views
    [self.topViewController.view setHidden:(y <= 0)];
    [self.bottomViewController.view setHidden:(y >= 0)];
  }
  
  if(
     (!self.topIsOpen && !self.bottomIsOpen) && 
     (self.panningDirection == Panning_Unknown || self.panningDirection == Panning_Horizontal) && 
     (self.panViewStartOrigin.x > currentPoint.x || self.panViewStartOrigin.x < currentPoint.x) &&
     (ABS(self.panViewStartOrigin.x - currentPoint.x) > SLIDE_DISTANCE)
  ){
    CGFloat lx = MAX(MIN(x, width - self.ledge), -width + self.ledge);
    
    centerFrame.origin.x = lx;
    
    self.panningDirection = Panning_Horizontal;
    
    //Show hide left/right views
    [self.leftViewController.view setHidden:(x <= 0)];
    [self.rightViewController.view setHidden:(x >= 0)];
  }
  
  [self.centerViewController.view.layer setCornerRadius:CORNER_RADIUS];
  
  [self.centerView setFrame:centerFrame];
  
  if(gesture.state == UIGestureRecognizerStateEnded){
    if(self.panningDirection == Panning_Horizontal){
      CGFloat lw3 = (width - self.ledge) / 3.0;
      CGFloat rw3 = (width - self.ledge) / 3.0;
      
      CGFloat velocity = [gesture velocityInView:self.view].x;
      
      if (ABS(velocity) < 500) {
        // small velocity, no movement
        if (x >= width - self.ledge - lw3) {
          [self openLeftView];
        }
        else if (x <= self.ledge + rw3 - width) {
          [self openRightView];
        }
        else{
          [self openCenterView];
        }
      }
      else if (velocity < 0) {
        // swipe to the left
        if (x < 0) {
          [self openRightView];
        }
        else {
          [self openCenterView];
        }
      }
      else if (velocity > 0) {
        // swipe to the right
        if (x > 0) {
          [self openLeftView];
        }
        else {
          [self openCenterView];
        }
      }
    }
    else if(self.panningDirection == Panning_Vertical){
      CGFloat topHeight3 = (height - self.topLedge) / 3.0;
      CGFloat bottomHeight3 = (height - self.bottomLedge) / 3.0;
      
      CGFloat velocity = [gesture velocityInView:self.view].y;
      
      if (ABS(velocity) < 500) {
        // small velocity, no movement
        if (y >= height - self.topLedge - topHeight3) {
          [self openTopView];
        }
        else if (y <= self.bottomLedge + bottomHeight3 - height) {
          [self openBottomView];
        }
        else{
          [self openCenterView];
        }
      }
      else if (velocity < 0) {
        // swipe bottom
        if (y < 0) {
          [self openBottomView];
        }
        else {
          [self openCenterView];
        }
      }
      else if (velocity > 0) {
        // swipe down
        if (y > 0) {
          [self openTopView];
        }
        else {
          [self openCenterView];
        }
      }
    }
    
    //Reset panning direction
    self.panningDirection = Panning_Unknown;
  }
}

#pragma mark - Private
-(void)addPanner{
  UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning:)];
  [panGesture setCancelsTouchesInView:YES];
  [panGesture setDelegate:self];

  [self.centerView addGestureRecognizer:panGesture];
}

-(BOOL)isOpen:(UIViewController *)controller{
  return ((controller) && !controller.view.hidden);
}

-(void)addViewController:(UIViewController *)controller{  
  [controller.view setHidden:YES];
  
  [self.view insertSubview:controller.view belowSubview:self.centerView];
}

-(void)centerWasHidden{
  [self setCenterDidDisappear:YES];
  
  //Close button
  [self.centerCloseButton setFrame:self.centerView.bounds];
  [self.centerView addSubview:self.centerCloseButton];
}
@end
