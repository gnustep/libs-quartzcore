
/* CAMediaTiming.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>
   Date: January 2012

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

#import "QuartzCore/CABase.h"

@protocol CAMediaTiming

@property CFTimeInterval beginTime;
@property CFTimeInterval timeOffset;
@property float repeatCount;
@property float repeatDuration;
@property BOOL autoreverses;
@property(copy) NSString* fillMode;
@property CFTimeInterval duration;
@property float speed;


/* GNUstep private extensions */
@optional
- (CFTimeInterval) activeTime;
- (CFTimeInterval) localTime;

- (CFTimeInterval) activeTimeWithTimeAuthorityLocalTime: (CFTimeInterval)timeAuthorityLocalTime;
- (CFTimeInterval) localTimeWithTimeAuthority: (id<CAMediaTiming>)timeAuthority;


@end 

extern NSString *const kCAFillModeRemoved;
extern NSString *const kCAFillModeForwards;
extern NSString *const kCAFillModeBackwards;
extern NSString *const kCAFillModeBoth;
extern NSString *const kCAFillModeFrozen;

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */