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

#import <Foundation/Foundation.h>
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CATransaction.h"
#import "QuartzCore/CAMediaTimingFunction.h"
#import "CATransaction+FrameworkPrivate.h"
#import "CALayer+FrameworkPrivate.h"

static NSMutableArray *transactionStack = nil;

@interface CATransaction ()

- (void) commit;

@property (assign) CFTimeInterval animationDuration;
@property (retain) CAMediaTimingFunction *animationTimingFunction;
@property (retain) NSMutableArray *actions;
@property (assign, getter=isImplicit) BOOL implicit;
@end

@implementation CATransaction
@synthesize animationDuration=_animationDuration;
@synthesize animationTimingFunction=_animationTimingFunction;
@synthesize actions=_actions;
@synthesize implicit=_implicit;

+ (void) begin
{
  if (!transactionStack)
    {
      transactionStack = [NSMutableArray new];
    }

  CATransaction *newTransaction = [CATransaction new];
  [transactionStack addObject: newTransaction];
  [newTransaction release];
}

+ (void) commit
{
  CATransaction *topTransaction = [self topTransaction];
  [topTransaction commit];

  [transactionStack removeObjectAtIndex: [transactionStack count]-1];
}

+ (void) flush
{
  /* TODO: flushing transaction means committing the implicit
     animation immediately after all nested explicit transaction
     are committed.
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
  if(![transactionStack lastObject])
    {
      [CATransaction begin];
      [[transactionStack lastObject] setImplicit: YES];
    }

  return [transactionStack lastObject];
}

/* ***** Instance methods ****** */
/* Note: All are private */

- (id) init
{
  self = [super init];
  if (!self)
    return nil;

  _actions = [[NSMutableArray alloc] init];
  _animationDuration = 0.25;
  _animationTimingFunction = [[CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionDefault] retain];

  return self;
}

- (void) dealloc
{
  [_animationTimingFunction release];
  [_actions release];
  
  [super dealloc];
}

- (void) commit
{ 
  for (NSDictionary* actionDescription in _actions)
    {
      NSObject<CAAction> * action = [actionDescription objectForKey: @"action"];
      id object = [actionDescription objectForKey: @"object"];
      NSString * keyPath = [actionDescription objectForKey: @"keyPath"];
      NSDictionary * arguments = nil;
      
      if ([object respondsToSelector: @selector(isPresentationLayer)] &&
          [object isPresentationLayer])
        {
          NSLog(@"Attempt at adding action to a presentation layer");
          continue;
        }
      
      if ([action conformsToProtocol:@protocol(CAMediaTiming)])
        {
          NSObject<CAAction, CAMediaTiming>* timedAction = (id)action;
          if(![timedAction duration])
            [timedAction setDuration: [CATransaction animationDuration]];
        }
      if ([action isKindOfClass: [CAAnimation class]])
        {
          CAAnimation * animation = (id)action;
          if(![animation timingFunction])
            [animation setTimingFunction: [CATransaction animationTimingFunction]];
        }
      
      [action runActionForKey: keyPath
                       object: object
                    arguments: arguments];
    }
  [_actions removeAllObjects];
}

- (void)registerAction: (NSObject<CAAction> *)action
              onObject: (id)object
               keyPath: (NSString *)keyPath
{
  /* eliminate any earlier actions with same object and keypath */
  NSPredicate * sameActionsPredicate = [NSPredicate predicateWithFormat: @"object = %@ and keyPath = %@", object, keyPath];
  NSArray * duplicates = [_actions filteredArrayUsingPredicate: sameActionsPredicate];
  [_actions removeObjectsInArray: duplicates];

  /* now add the new action */
  NSDictionary * actionDescription = [NSDictionary dictionaryWithObjectsAndKeys:
    action, @"action",
    object, @"object",
    keyPath, @"keyPath",
    nil];
  
  [_actions addObject: actionDescription];
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
