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
- (id) valueForKey: (NSString *)key;
- (void) setValue: (id)value forKey: (NSString *)key;

@property (assign) CFTimeInterval animationDuration;
@property (retain) CAMediaTimingFunction *animationTimingFunction;
@property (retain) NSMutableArray *implicitAnimations;
@end

@implementation CATransaction
@synthesize  implicitAnimations = _implicitAnimations;

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
  return [transactionStack lastObject];
}

/* ***** Instance methods ****** */
/* Note: All are private */

- (id) init
{
  self = [super init];
  if (!self)
    return nil;

  _implicitAnimations = [[NSMutableArray alloc] init];
  _animationDuration = 0.25;
  _animationTimingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionDefault];

  return self;
}

- (void) dealloc
{
  [_implicitAnimations release];
  
  [super dealloc];
}

- (void) commit
{
  for(NSDictionary * animationDescription in _implicitAnimations)
    {
      /* TODO: we currently don't use CAAnimation */
      NSLog(@"Ani desc %@", animationDescription);
      /* note that we don't really use the "from" value, since we're
         actually interested in animated object's presentationLayer value
         for the specified keypath. */
         
      id object = [animationDescription valueForKey: @"object"]; /* probably a CALayer */
      NSString * keyPath = [animationDescription valueForKey: @"keyPath"];
      id from = [animationDescription valueForKey: @"from"];
      id to = [animationDescription valueForKey: @"to"];
      
      /* as described, 'from' value is ignored since it derives from model
         layer. */
      /* actual 'from' value is collected from the presentation layer */
      if (([object respondsToSelector: @selector(isPresentationLayer)] &&
           [object isPresentationLayer]) ||
          ![object respondsToSelector: @selector(presentationLayer)])
        {
          from = [object valueForKeyPath: keyPath];
        }
      else if ([object respondsToSelector: @selector(presentationLayer)])
        {
          from = [[object presentationLayer] valueForKeyPath: keyPath];
        }
      
      /* construct new animation */
      CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath: keyPath];
      [animation setDuration: [self animationDuration]];
      [animation setTimingFunction: [self animationTimingFunction]];
      [animation setFromValue: from];
      [animation setToValue: to];
      
      /* add the animation to animations list into the object */
      NSString *sanitizedKeyPath = [keyPath stringByReplacingOccurrencesOfString:@"." withString:@"__"];
      NSString *implicitAnimationKey = [NSString stringWithFormat:@"%@", sanitizedKeyPath];
      
      [object addAnimation: animation forKey: implicitAnimationKey];
    }
    
    [_implicitAnimations removeAllObjects];
}

- (void)registerImplicitAnimationOnObject: (id)object
                                  keyPath: (NSString *)keyPath
                                     from: (id)from
                                       to: (id)to
{
  /* eliminate any earlier implicit animations with same object and keypath */
  NSPredicate * sameAnimationsPredicate = [NSPredicate predicateWithFormat: @"object = %@ and keyPath = %@", object, keyPath];
  NSArray * duplicates = [_implicitAnimations filteredArrayUsingPredicate: sameAnimationsPredicate];
  [_implicitAnimations removeObjectsInArray: duplicates];
  
  /* now add the new animation */
  NSDictionary * animationDescription = [NSDictionary dictionaryWithObjectsAndKeys:
    object, @"object",
    keyPath, @"keyPath",
    from, @"from",
    to, @"to",
    nil];
  [_implicitAnimations addObject: animationDescription];
}

@synthesize animationDuration=_animationDuration;
@synthesize animationTimingFunction=_animationTimingFunction;
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
