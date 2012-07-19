//
//  PanningViewController.h
//
//  Created by Frankie Laguna on 3/13/12.
//  Copyright (c) 2012 Frankie Laguna. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PanningViewController : UIViewController<UIGestureRecognizerDelegate>

@property(nonatomic, strong) UIViewController *centerViewController;
@property(nonatomic, strong) UIViewController *topViewController;
@property(nonatomic, strong) UIViewController *bottomViewController;
@property(nonatomic, strong) UIViewController *leftViewController;
@property(nonatomic, strong) UIViewController *rightViewController;

@property(nonatomic) CGFloat ledge;
@end
