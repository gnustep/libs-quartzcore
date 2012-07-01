/* CAAnimation.m

   Copyright (C) 2012 Free Software Foundation, Inc.
   
   Author: Ivan Vučica <ivan@vucica.net>
   Date: June 2012
   
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

#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CALayer.h"
#import "CAAnimation+FrameworkPrivate.h"

NSString *const kCAAnimationDiscrete = @"CAAnimationDiscrete";

@interface CAAnimation ()
- (id) init;
@end

@implementation CAAnimation
@synthesize delegate=_delegate;
@synthesize timingFunction=_timingFunction;
@synthesize removedOnCompletion=_removedOnCompletion;

@synthesize beginTime=_beginTime;
@synthesize timeOffset=_timeOffset;
@synthesize repeatCount=_repeatCount;
@synthesize repeatDuration=_repeatDuration;
@synthesize autoreverses=_autoreverses;
@synthesize fillMode=_fillMode;
@synthesize duration=_duration;
@synthesize speed=_speed;

+ (id) animation
{
  return [[[self alloc] init] autorelease];
}

- (id) init
{
  self = [super init];
  if (!self)
    return nil;
  
  static NSString * keys[] = {
    @"delegate", @"removedOnCompletion", @"timingFunction", 
    @"duration", @"speed", @"autoreverses", @"repeatCount"};
  for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
    {
      id defaultValue = [[self class] defaultValueForKey: keys[i]];
      if (defaultValue)
        {
          [self setValue:defaultValue
                  forKey:keys[i]];
        }
    }
  
  return self;
}

+ (id) defaultValueForKey: (NSString *)key
{
  if ([key isEqualToString:@"delegate"])
    {
      return nil;
    }
  if ([key isEqualToString:@"removedOnCompletion"])
    {
      return [NSNumber numberWithBool: YES];
    }
  if ([key isEqualToString:@"timingFunction"])
    {
      return nil; /* indicates linear pacing */
    }
    
  /* CAMediaTiming */
  /* FIXME: some of these should be picked up from nearest CATransaction */
  if ([key isEqualToString:@"duration"])
    {
      return [NSNumber numberWithFloat: 0.25];
    }
  if ([key isEqualToString:@"speed"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString:@"autoreverses"])
    {
      return [NSNumber numberWithBool: NO];
    }
  if ([key isEqualToString:@"repeatCount"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  return nil;
}

+ (BOOL) shouldArchiveValueForKey: (NSString *)key
{
  /* default implementation returns YES */
  return YES;
}

- (CFTimeInterval) activeTimeWithTimeAuthorityLocalTime: (CFTimeInterval)timeAuthorityLocalTime
{
  /* Slides */
  CFTimeInterval activeTime = (timeAuthorityLocalTime - [self beginTime]) * [self speed] + [self timeOffset];

  return activeTime;
}

- (CFTimeInterval) localTimeWithTimeAuthority: (id<CAMediaTiming>)timeAuthority
{
  /* Slides */
  CFTimeInterval timeAuthorityLocalTime = [timeAuthority localTime];
  CFTimeInterval activeTime = [self activeTimeWithTimeAuthorityLocalTime: timeAuthorityLocalTime];
  if (isinf([self duration]))
    return activeTime;
  
  NSInteger k = floor(activeTime / [self duration]);
  CFTimeInterval localTime = activeTime - k * [self duration];
  if ([self autoreverses] && k % 2 == 1)
    {
      localTime = [self duration] - localTime;
    }
    
  return localTime;
}

@end

/* ********************************* */
@interface CAPropertyAnimation ()
- (id) initWithKeyPath: (NSString*)keyPath;
- (id) calculatedAnimationValueAtTime: (CFTimeInterval)time;
@end

@implementation CAPropertyAnimation
@synthesize additive=_additive;
@synthesize cumulative=_cumulative;
@synthesize keyPath=_keyPath;
@synthesize valueFunction=_valueFunction;

+ (id) animationWithKeyPath: (NSString *)path
{
  return [[[self alloc] initWithKeyPath: (NSString *)path] autorelease];
}

- (id)initWithKeyPath:(NSString *)keyPath
{
  self = [super init];
  if (!self)
    return nil;
  
  [self setKeyPath: keyPath];
  
  static NSString * keys[] = {@"additive", @"cumulative", @"valueFunction"};
  for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
    {
      id defaultValue = [[self class] defaultValueForKey: keys[i]];
      if (defaultValue)
        {
          [self setValue:defaultValue
                  forKey:keys[i]];
        }
    }
  
  return self;
}

+ (id)defaultValueForKey: (NSString *)key
{
  if ([key isEqualToString:@"additive"])
    {
      return NO;
    }
  if ([key isEqualToString:@"cumulative"])
    {
      return NO;
    }
  if ([key isEqualToString:@"keyPath"])
    {
      return nil;
    }
  if ([key isEqualToString:@"valueFunction"])
    {
      return nil;
    }
  
  return [super defaultValueForKey: key];
}

- (void) applyToLayer: (CALayer *)layer
{
  CFTimeInterval theTime = [self localTimeWithTimeAuthority: [layer modelLayer]];

  id modelValue = [[layer modelLayer] valueForKeyPath: [self keyPath]];
  id calculatedValue = [self calculatedAnimationValueAtTime: theTime];

  /* TODO: support additive and cumulative modes using modelValue */
  [layer setValue: calculatedValue forKeyPath: [self keyPath]];
}

- (id) calculatedAnimationValueAtTime: (CFTimeInterval)time
{
  /* noop. */
  return nil;
}

@end

@implementation CABasicAnimation
@synthesize fromValue=_fromValue;
@synthesize byValue=_byValue;
@synthesize toValue=_toValue;

- (id) calculatedAnimationValueAtTime: (CFTimeInterval)theTime
{
  /*
    Currently supporting only the scenario with:
     - fromValue != nil
     - toValue != nil
     - byValue == nil
     
    All supplied values need to be of same data type.
   */
  
  float fraction = theTime / _duration;

  if ([_fromValue isKindOfClass: [NSNumber class]] &&
      [_toValue isKindOfClass: [NSNumber class]])
    {
      /* It should be safe to presume that values can be
         represented as floats. */
      float from = [_fromValue floatValue];
      float to = [_toValue floatValue];
      
      float value = from + (to-from)*fraction;
      
      return [NSNumber numberWithFloat: value];
    }
    
  if ([_fromValue isKindOfClass: [NSValue class]] &&
      [_toValue isKindOfClass: [NSValue class]] &&
      !strcmp([_fromValue objCType], [_toValue objCType]))
    {
      NSValue *from = _fromValue;
      NSValue *to = _toValue;

      if (!strcmp([from objCType], @encode(NSPoint)))
        {
          /* Just convert to CGPoint. Core Animation doesn't deal with NSPoints! */
          /* After that, don't return; instead let the CGPoint branch deal with the values. */
          
          CGPoint fromPt = CGPointMake([from pointValue].x, [from pointValue].y);
          CGPoint toPt = CGPointMake([to pointValue].x, [to pointValue].y);
          
          from = [NSValue valueWithBytes:&fromPt objCType:@encode(CGPoint)];
          to = [NSValue valueWithBytes:&toPt objCType:@encode(CGPoint)];
        }
        
      if (!strcmp([from objCType], @encode(CGPoint)))
        {
          /* NSValue doesn't come with CGPoint support.
             Opal and Core Graphics don't provide it either.
             This support is an extension provided by UIKit. */
          CGPoint fromPt; [from getValue:&fromPt];
          CGPoint toPt; [to getValue:&toPt];
          
          CGPoint value = CGPointMake(fromPt.x + (toPt.x-fromPt.x)*fraction,
                                      fromPt.y + (toPt.y-fromPt.y)*fraction);
          
          return [NSValue valueWithBytes:&value objCType:@encode(CGPoint)];
        }
    }
  return nil;
}

@end

@implementation CAKeyframeAnimation
@synthesize calculationMode=_calculationMode;
@synthesize values=_values;

@end

@implementation CATransition
@synthesize type=_type;
@synthesize subtype=_subtype;

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
