//
//  TBSwitch.h
//  TunnelBear
//
//  Created by Rod H on 2014-05-27.
//  Most of this code comes from https://github.com/mattlawer/MBSwitch but added the label and did a few design tweaks
//
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, TBSwitchState)
{
  TBSwitchStateNormal = 0,
  TBSwitchStateInProgressIndefinite,
};

@interface TBSwitch : UIControl

@property(nonatomic, retain) UIColor *onTintColor UI_APPEARANCE_SELECTOR;
@property(nonatomic, retain) UIColor *offTintColor UI_APPEARANCE_SELECTOR;
@property(nonatomic, retain) UIColor *thumbTintColor UI_APPEARANCE_SELECTOR;

@property(nonatomic,getter=isOn) BOOL on;
@property (nonatomic) TBSwitchState switchState;
@property (nonatomic) double progress;

- (id)initWithFrame:(CGRect)frame;

- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (void)setOn:(BOOL)on animated:(BOOL)animated action: (BOOL)action;
- (void)setBackgroundForConnected:(BOOL)isConnected;
- (void)setOn: (BOOL)on animated: (BOOL)animated action: (BOOL)action userInteraction: (BOOL)userInteraction;

@end

