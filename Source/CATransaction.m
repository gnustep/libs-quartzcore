/* CATransaction.m

   Copyright (C) 2012 Free Software Foundation, Inc.

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

#import "QuartzCore/CATransaction.h"
#import "QuartzCore/CAMediaTimingFunction.h"
#import <Foundation/Foundation.h>
static NSMutableArray *transactionStack = nil;

@interface CATransaction ()

+ (CATransaction *) topTransaction;

- (void) commit;
- (id) valueForKey: (NSString *)key;
- (void) setValue: (id)value forKey: (NSString *)key;

@property (assign) CFTimeInterval animationDuration;
@property (retain) CAMediaTimingFunction *animationTimingFunction;
@end

@implementation CATransaction

+ (void) begin
{
  if (!transactionStack)
    {
      transactionStack = [NSMutableArray new];
    }

  CATransaction *newTransaction = [CATransaction new];
  [transactionStack addObject: newTransaction];
}

+ (void) commit
{
  CATransaction *topTransaction = [self topTransaction];
  [topTransaction commit];

  [transactionStack removeObjectAtIndex: [transactionStack count]-1];
}

+ (void) flush
{
  /* TODO: should flush an implicit transaction, if it exists.
     this means committing it, but apparently not until nested explicit
     transactions have completed.
     */

}

+ (void) lock
{
  NSLog(@"+[CATransaction lock] unimplemented");
}

+ (void) unlock
{
  NSLog(@"+[CATransaction unlock] unimplemented");
}

+ (CFTimeInterval) animationDuration
{
  return [[self topTransaction] animationDuration];
}

+ (void) setAnimationDuration: (CFTimeInterval)animationDuration
{
  [[self topTransaction] setAnimationDuration: animationDuration];
}

+ (CAMediaTimingFunction *) animationTimingFunction
{
  return [[self topTransaction] animationTimingFunction];
}

+ (void) setAnimationTimingFunction: (CAMediaTimingFunction *)function
{
  [[self topTransaction] setAnimationTimingFunction: function];
}

+ (id) valueForKey: (NSString *)key
{
  return [[self topTransaction] valueForKey: key];
}

+ (void) setValue: (id)value forKey: (NSString *)key
{
  [[self topTransaction] setValue: value forKey: key];
}

/* ***** Private class methods ******* */
+ (CATransaction *) topTransaction
{
  return [transactionStack lastObject];
}

/* ***** Instance methods ****** */
/* Note: All are private */

- (id) init
{
  self = [super init];
  if (!self)
    return nil;

  // TODO

  return self;
}

- (void) commit
{
  // TODO
}

- (id) valueForKey: (NSString *)key
{
  // TODO
  return nil;
}

- (void) setValue: (id)value forKey: (NSString *)key
{
  // TODO
}

@synthesize animationDuration=_animationDuration;
@synthesize animationTimingFunction=_animationTimingFunction;
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
