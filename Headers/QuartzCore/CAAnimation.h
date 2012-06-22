
/* 
   CAAnimation.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>
   Date: January 2011

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

@class CAMediaTimingFunction;

@interface CAAnimation : NSObject <CAMediaTiming>
{
}

+ (id)animation;

@property (retain) id delegate;
@property (retain) CAMediaTimingFunction *timingFunction;
@property BOOL removedOnCompletion;

@end

@interface CAPropertyAnimation : CAAnimation

+ (id)animationWithKeyPath:(NSString *)path;

@end

@interface CABasicAnimation : CAPropertyAnimation

@property(retain) id fromValue, toValue, byValue;

@end

@interface CAKeyframeAnimation : CAPropertyAnimation

@property(copy) NSString* calculationMode;
@property(copy) NSArray* values;

@end

/* calculationMode constants */

NSString *const kCAAnimationDiscrete;

@interface CATransition : CAAnimation

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

