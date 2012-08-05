/* 
   CAAnimation.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>
   Date: January 2011

   Author: Ivan Vucica <ivan@vucica.net>
   Date: June 2012

   This file is part of QuartzCore.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import "QuartzCore/CAMediaTiming.h"
#import "QuartzCore/CAAction.h"

@class CAMediaTimingFunction;
@class CAValueFunction;
@class CALayer;

/* *********************************** */

@interface CAAnimation : NSObject <NSCoding, NSCopying, CAAction, CAMediaTiming>
{
  /* property-backing ivars */
  id _delegate;
  CAMediaTimingFunction *_timingFunction;
  BOOL _removedOnCompletion;

  /* CAMediaTiming ivars */
  CFTimeInterval _beginTime;
  CFTimeInterval _timeOffset;
  float _repeatCount;
  float _repeatDuration;
  BOOL _autoreverses;
  NSString* _fillMode;
  CFTimeInterval _duration;
  float _speed;

}

+ (id) animation;
+ (id) defaultValueForKey: (NSString*)key;

@property (retain) id delegate; /* note: it's not a bug that the delegate is retained */
@property (retain) CAMediaTimingFunction *timingFunction;
@property BOOL removedOnCompletion;

@end

/* *********************************** */

@interface CAPropertyAnimation : CAAnimation
{
  /* property-backing ivars */
  BOOL _additive;
  BOOL _cumulative;
  NSString *_keyPath;
  CAValueFunction *_valueFunction;
}
+ (id)animationWithKeyPath:(NSString *)path;

@property (assign,getter=isAdditive) BOOL additive;
@property (assign,getter=isCumulative) BOOL cumulative;
@property (retain) NSString *keyPath;
@property (retain) CAValueFunction *valueFunction; // Currently unimplemented!
@end


/* *********************************** */

@interface CABasicAnimation : CAPropertyAnimation
{
  /* property-backing ivars */
  id _fromValue, _toValue, _byValue;
}

@property(retain) id fromValue, toValue, byValue;

@end

/* *********************************** */

@interface CAKeyframeAnimation : CAPropertyAnimation
{
  /* property-backing ivars */
  NSString * _calculationMode;
  NSArray * _values;
}
@property(copy) NSString* calculationMode;
@property(copy) NSArray* values;

@end

/* calculationMode constants */
NSString *const kCAAnimationDiscrete;

/* *********************************** */

@interface CATransition : CAAnimation
{
  NSString * _type;
  NSString * _subtype;
}
@property(copy) NSString* type;
@property(copy) NSString* subtype;

@end

/* transition types */
NSString *const kCATransitionMoveIn;

/* transition subtypes */
NSString *const kCATransitionFromTop;
NSString *const kCATransitionFromBottom;
NSString *const kCATransitionFromLeft;
NSString *const kCATransitionFromRight;

/* *********************************** */

/* delegate methods for CAAnimation */
/* a GNUstep extension */
@protocol GSCAAnimationDelegate <NSObject>
- (void) animationDidStart: (CAAnimation *)animation;
- (void) animationDidStop: (CAAnimation *)animation finished: (BOOL)finished;

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
