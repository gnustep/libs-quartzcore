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

NSString *kCATransactionAnimationDuration = @"animationDuration";
NSString *kCATransactionAnimationTimingFunction= @"animationTimingFunction";
NSString *kCATransactionDisableActions = @"disableActions";

static NSMutableArray *transactionStack = nil;

@interface CATransaction ()

- (void) commit;

/* The three keys a transaction defines itself, as typed accessors over
   -values.  Any other key a caller sets is carried in -values alone. */
@property (assign) CFTimeInterval animationDuration;
@property (retain) CAMediaTimingFunction *animationTimingFunction;
@property (assign) BOOL disableActions;

@property (retain) NSMutableDictionary *values;
@property (retain) NSMutableArray *actions;
@property (assign, getter=isImplicit) BOOL implicit;
@end

@implementation CATransaction
@synthesize values=_values;
@synthesize actions=_actions;
@synthesize implicit=_implicit;

+ (void) begin
{
  CATransaction *enclosingTransaction;
  CATransaction *newTransaction;

  if (!transactionStack)
    {
      transactionStack = [NSMutableArray new];
    }

  /* A transaction starts out with the values of the one it is nested in;
     changing them affects only the new transaction. */
  enclosingTransaction = [transactionStack lastObject];
  newTransaction = [CATransaction new];
  if (enclosingTransaction)
    {
      [[newTransaction values] removeAllObjects];
      [[newTransaction values] addEntriesFromDictionary:
        [enclosingTransaction values]];
    }

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

+ (BOOL) disableActions
{
  return [[self topTransaction] disableActions];
}

+ (void) setDisableActions: (BOOL)disableActions
{
  [[self topTransaction] setDisableActions: disableActions];
}

- (CFTimeInterval) animationDuration
{
  return [[self valueForKey: kCATransactionAnimationDuration] doubleValue];
}

- (void) setAnimationDuration: (CFTimeInterval)animationDuration
{
  [self setValue: [NSNumber numberWithDouble: animationDuration]
          forKey: kCATransactionAnimationDuration];
}

- (CAMediaTimingFunction *) animationTimingFunction
{
  return [self valueForKey: kCATransactionAnimationTimingFunction];
}

- (void) setAnimationTimingFunction: (CAMediaTimingFunction *)function
{
  [self setValue: function forKey: kCATransactionAnimationTimingFunction];
}

- (BOOL) disableActions
{
  return [[self valueForKey: kCATransactionDisableActions] boolValue];
}

- (void) setDisableActions: (BOOL)disableActions
{
  [self setValue: [NSNumber numberWithBool: disableActions]
          forKey: kCATransactionDisableActions];
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

  /* The values an outermost transaction starts with.  There is no timing
     function until one is set. */
  _values = [[NSMutableDictionary alloc] init];
  [_values setObject: [NSNumber numberWithDouble: 0.25]
              forKey: kCATransactionAnimationDuration];
  [_values setObject: [NSNumber numberWithBool: NO]
              forKey: kCATransactionDisableActions];

  return self;
}

- (void) dealloc
{
  [_values release];
  [_actions release];

  [super dealloc];
}

/* A transaction holds whatever keys are set on it, and reading one that was
   never set answers nil rather than raising. */
- (id) valueForKey: (NSString *)key
{
  return [_values objectForKey: key];
}

- (void) setValue: (id)value forKey: (NSString *)key
{
  if (value == nil)
    {
      [_values removeObjectForKey: key];
    }
  else
    {
      [_values setObject: value forKey: key];
    }
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
          if(![animation timingFunction] && [CATransaction animationTimingFunction])
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
