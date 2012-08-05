/* 
   CAImplicitAnimationObserver.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: July 2012

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

#import <Foundation/Foundation.h>
#import "CAImplicitAnimationObserver.h"
#import "CALayer+FrameworkPrivate.h"
#import "CATransaction+FrameworkPrivate.h"
#import "QuartzCore/CATransaction.h"

static CAImplicitAnimationObserver * sharedObserver;

@implementation CAImplicitAnimationObserver
+ (CAImplicitAnimationObserver *)sharedObserver
{
  if(!sharedObserver)
    {
      sharedObserver = [CAImplicitAnimationObserver new];
    }

  return sharedObserver;
}

- (id) init
{
  self = [super init];
  if (!self)
    {
      return nil;
    }
  
  return self;
}

- (void) observeValueForKeyPath: (NSString *)keyPath 
                       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context
{
  if ([object isPresentationLayer])
    {
      return;
    }
  
  id from = [change valueForKey: NSKeyValueChangeOldKey];
  id to = [change valueForKey: NSKeyValueChangeNewKey];
  
  if (!from)
    from = [object valueForKeyPath: keyPath];
  if (!to)
    to = [object valueForKeyPath: keyPath];
  
  /* Implicit animation must not be launched if model tree value
     is equal to the new value, even if the presentation tree value
     is not equal. */
  if ([to isEqualTo: from])
    return;
  
  NSObject<CAAction>* action = (id)[object actionForKey: keyPath];
  [[CATransaction topTransaction] registerAction: action
                                        onObject: object
                                         keyPath: keyPath];
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
