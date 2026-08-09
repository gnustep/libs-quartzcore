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

#import <Foundation/Foundation.h>
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CALayer.h"
#import "CAAnimation+FrameworkPrivate.h"
#import "QuartzCore/CATransform3D.h"
#import "QuartzCore/CAMediaTimingFunction.h"
#import "CAMediaTimingFunction+FrameworkPrivate.h"
#import "CALayer+FrameworkPrivate.h"

NSString *const kCAAnimationLinear = @"linear";
NSString *const kCAAnimationDiscrete = @"discrete";
NSString *const kCAAnimationPaced = @"paced";
NSString *const kCAAnimationCubic = @"cubic";
NSString *const kCAAnimationCubicPaced = @"cubicPaced";

NSString *const kCATransitionFade = @"fade";
NSString *const kCATransitionMoveIn = @"moveIn";
NSString *const kCATransitionPush = @"push";
NSString *const kCATransitionReveal = @"reveal";
NSString *const kCATransitionFromTop = @"fromTop";
NSString *const kCATransitionFromBottom = @"fromBottom";
NSString *const kCATransitionFromLeft = @"fromLeft";
NSString *const kCATransitionFromRight = @"fromRight";

@interface CAAnimation ()
@property (retain) NSPointerArray *layers;
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
@synthesize layers=_layers;

- (void) setBeginTime: (CFTimeInterval)beginTime
{
  _beginTime = beginTime;
  [self takeNoteThatNextFrameTimeChanged];
}

- (void) handleAddedToLayer: (CALayer *)layer
{
  for (int index = 0, len = [_layers count]; index < len; index++)
    {
      if(layer == [_layers pointerAtIndex: index])
        [NSException raise:NSGenericException
                    format:@"Animation already added to this layer"];
    }

  [_layers addPointer:layer];
  [self takeNoteThatNextFrameTimeChanged];
}

- (void) handleRemovedFromLayer: (CALayer *)layer
{
  for (int index = 0, len = [_layers count]; index < len; index++)
    {
      if(layer == [_layers pointerAtIndex: index])
        [_layers removePointerAtIndex: index];
    }

  [self takeNoteThatNextFrameTimeChanged];
}

- (void) takeNoteThatNextFrameTimeChanged
{
  for (int index = 0, len = [_layers count]; index < len; index++)
    {
      CALayer *layer = [_layers pointerAtIndex: index];
      [layer takeNoteThatNextFrameTimeChanged];
    }
}

+ (id) animation
{
  return [[[self alloc] init] autorelease];
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

- (id) init
{
  self = [super init];
  if (!self)
    return nil;

  static NSString * keys[] = {
    @"delegate", @"removedOnCompletion", @"timingFunction",
    /*@"duration", */@"speed", @"autoreverses", @"repeatCount"};
    /* Duration intentionally skipped so it gets picked up from transaction */
  for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
    {
      id defaultValue = [[self class] defaultValueForKey: keys[i]];
      if (defaultValue)
        {
          [self setValue:defaultValue
                  forKey:keys[i]];
        }
    }

  _layers = [[NSPointerArray weakObjectsPointerArray] retain];

  return self;
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  self = [self init];
  if (!self)
    return nil;

  static NSString * keys[] = {
    @"delegate", @"removedOnCompletion", @"timingFunction",
    @"duration", @"speed", @"autoreverses", @"repeatCount"};
  for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
    {
      if ([aDecoder containsValueForKey: keys[i]])
        {
          [self setValue: [aDecoder decodeObjectForKey: keys[i]]
                  forKey: keys[i]];
        }
    }

  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  static NSString * keys[] = {
    @"delegate", @"removedOnCompletion", @"timingFunction",
    @"duration", @"speed", @"autoreverses", @"repeatCount"};
  for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
    {
      if ([[self class] shouldArchiveValueForKey: keys[i]])
        {
          [self encodeWithCoder: aCoder];
        }
    }
}

- (id) copyWithZone: (NSZone *)zone
{
  id theCopy = [[self class] allocWithZone: zone];
  if (!theCopy)
    return nil;

  static NSString * keys[] = {
    @"delegate", @"removedOnCompletion", @"timingFunction",
    @"duration", @"speed", @"autoreverses", @"repeatCount"};
  for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
    {
      id value = [self valueForKey: keys[i]];
      if (value)
        {
          [theCopy setValue: value
                     forKey: keys[i]];
        }
    }

  return theCopy;
}

- (void) dealloc
{
  [_timingFunction release];
  [_fillMode release];
  [_layers release];

  [super dealloc];
}

- (CFTimeInterval) activeTimeWithTimeAuthorityLocalTime: (CFTimeInterval)timeAuthorityLocalTime
{
  /* Slides */
  CFTimeInterval activeTime = (timeAuthorityLocalTime - [self beginTime]) * [self speed] + [self timeOffset];

  /* FIXME: should not be necessary */
  if (activeTime < 0)
    activeTime = 0;

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

- (void)runActionForKey: (NSString *)key
                 object: (id)anObject
              arguments: (NSDictionary *)dict
{
  [(CALayer *)anObject addAnimation: self forKey: key];
}

@end

/* ********************************* */
@interface CAPropertyAnimation ()
- (id) initWithKeyPath: (NSString*)keyPath;
- (id) calculatedAnimationValueAtTime: (CFTimeInterval)theTime
                              onLayer: (CALayer *)layer;
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

- (id) initWithCoder:(NSCoder *)aDecoder
{
  self = [self init];
  if (!self)
    return nil;

  static NSString * keys[] = {@"additive", @"cumulative", @"valueFunction"};
  for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
    {
      if ([aDecoder containsValueForKey: keys[i]])
        {
          [self setValue: [aDecoder decodeObjectForKey: keys[i]]
                  forKey: keys[i]];
        }
    }

  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  static NSString * keys[] = {@"additive", @"cumulative", @"valueFunction"};
  for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
    {
      if ([[self class] shouldArchiveValueForKey: keys[i]])
        {
          [self encodeWithCoder: aCoder];
        }
    }
}

- (id) copyWithZone: (NSZone *)zone
{
  id theCopy = [super copyWithZone: zone];
  if (!theCopy)
    return nil;

  static NSString * keys[] = {@"additive", @"cumulative", @"valueFunction"};
  for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
    {
      id value = [self valueForKey: keys[i]];
      if (value)
        {
          [theCopy setValue: value
                     forKey: keys[i]];
        }
    }

  return theCopy;
}

- (void) dealloc
{
  [_keyPath release];
  [_valueFunction release];
  [super dealloc];
}

- (void) applyToLayer: (CALayer *)layer
{
  CFTimeInterval theTime = [self localTimeWithTimeAuthority: [layer modelLayer]];

  /* FIXME: temporary check until we have fillMode implementation */
  /* Also, why do we get theTime < 0? */
  if (theTime < 0)
    {
      return;
    }

  id modelValue = [[layer modelLayer] valueForKeyPath: [self keyPath]];
  id calculatedValue = [self calculatedAnimationValueAtTime: theTime
                                                    onLayer: layer];
  if (!calculatedValue)
    {
      /* We can't apply nil value! */
      return;
    }

  /* TODO: support additive and cumulative modes using modelValue */
  [layer setValue: calculatedValue forKeyPath: [self keyPath]];
}

- (id) calculatedAnimationValueAtTime: (CFTimeInterval)time
                              onLayer: (CALayer *)layer
{
  /* noop. */
  return nil;
}

@end

/********************************/
/** Some helper math functions **/

/* TODO: we will want to move these into a private header and impl. */

typedef struct _GSQuartzCoreQuaternion
{
  CGFloat x, y, z, w;
} GSQuartzCoreQuaternion;

static CGFloat linearInterpolation(CGFloat from, CGFloat to, CGFloat fraction)
{
  return from + (to-from)*fraction;
}

static CATransform3D transpose(CATransform3D m)
{
  CATransform3D r;
  CGFloat *mF = (CGFloat *)&m;
  CGFloat *rF = (CGFloat *)&r;
  for(int i = 0; i < 16; i++)
    {
      int col = i % 4;
      int row = i / 4;
      int j = col * 4 + row;
      rF[j] = mF[i];
    }

  return r;
}
/* Following two functions based on paper: */
/*   J.M.P. Warren: From Quaternion to Matrix and Back
     id Software, 2005 */
/* We use them to interpolate CATransform3Ds. Quaternions are
   easier to interpolate. */
static CATransform3D quaternionToMatrix(GSQuartzCoreQuaternion q)
{
  CATransform3D m;
  CGFloat x=q.x, y=q.y, z=q.z, w=q.w;

  m.m11 = 1 - 2*y*y - 2*z*z;
  m.m12 = 2*x*y + 2*w*z;
  m.m13 = 2*x*z - 2*w*y;
  m.m14 = 0;

  m.m21 = 2*x*y - 2*w*z;
  m.m22 = 1 - 2*x*x - 2*z*z;
  m.m23 = 2*y*z + 2*w*x;
  m.m24 = 0;

  m.m31 = 2*x*z + 2*w*y;
  m.m32 = 2*y*z - 2*w*x;
  m.m33 = 1 - 2*x*x - 2*y*y;
  m.m34 = 0;

  m.m41 = 0;
  m.m42 = 0;
  m.m43 = 0;
  m.m44 = 1;

  return m;
}

static GSQuartzCoreQuaternion matrixToQuaternion(CATransform3D m)
{
  /* note: how about we use reciprocal square root, too? */
  /* see:
   http://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Reciprocal_of_the_square_root
   http://en.wikipedia.org/wiki/Fast_inverse_square_root
   */

  GSQuartzCoreQuaternion q;

  m = m;
  if (m.m11 + m.m22 + m.m33 > 0)
    {
      CGFloat t = m.m11 + m.m22 + m.m33 + 1.;
      CGFloat s = 0.5/sqrt(t);

      q.w = s*t;
      q.z = (m.m12 - m.m21)*s;
      q.y = (m.m31 - m.m13)*s;
      q.x = (m.m23 - m.m32)*s;
    }
  else if (m.m11 > m.m22 && m.m11 > m.m33)
    {
      CGFloat t = m.m11 - m.m22 - m.m33 + 1;
      CGFloat s = 0.5/sqrt(t);

      q.x = s*t;
      q.y = (m.m12 + m.m21)*s;
      q.z = (m.m31 + m.m13)*s;
      q.w = (m.m23 - m.m32)*s;
    }
  else if (m.m22 > m.m33)
    {
      CGFloat t = -m.m11 + m.m22 - m.m33 + 1;
      CGFloat s = 0.5/sqrt(t);

      q.y = s*t;
      q.x = (m.m12 + m.m21)*s;
      q.w = (m.m31 - m.m13)*s;
      q.z = (m.m23 + m.m32)*s;
    }
  else
    {
      CGFloat t = -m.m11 - m.m22 + m.m33 + 1;
      CGFloat s = 0.5/sqrt(t);

      q.z = s*t;
      q.w = (m.m12 - m.m21)*s;
      q.x = (m.m31 + m.m13)*s;
      q.y = (m.m23 + m.m32)*s;
    }

  return q;
}

static GSQuartzCoreQuaternion linearInterpolationQuaternion(GSQuartzCoreQuaternion a, GSQuartzCoreQuaternion b, CGFloat fraction)
{
    // slerp
    GSQuartzCoreQuaternion qr;

    /* reduction of calculations */
    if (!memcmp(&a, &b, sizeof(a)))
      {
        /* aside from making less calculations, this will also
           fix NaNs that would be returned if quaternions are equal */
        return a;
      }
    if (fraction == 0.)
      {
        return a;
      }
    if (fraction == 1.)
      {
        return b;
      }

    CGFloat dotproduct = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
    CGFloat theta, st, sut, sout, coeff1, coeff2;

    theta = acos(dotproduct);
    if (theta == 0.0)
      {
        /* shouldn't happen, since we already checked for equality of
           inbound quaternions */
        /* if we didn't make this check, we'd get a lot of NaNs. */
        return a;
      }

    if (theta<0.0)
      theta=-theta;

    st = sin(theta);
    sut = sin(fraction*theta);
    sout = sin((1-fraction)*theta);
    coeff1 = sout/st;
    coeff2 = sut/st;

    qr.x = coeff1*a.x + coeff2*b.x;
    qr.y = coeff1*a.y + coeff2*b.y;
    qr.z = coeff1*a.z + coeff2*b.z;
    qr.w = coeff1*a.w + coeff2*b.w;

    // normalize
    CGFloat qrLen = sqrt(qr.x*qr.x + qr.y*qr.y + qr.z*qr.z + qr.w*qr.w);
    qr.x /= qrLen;
    qr.y /= qrLen;
    qr.z /= qrLen;
    qr.w /= qrLen;

    return qr;

}
/* VALUE plus BYVALUE, or minus it where SIGN is -1.  Answers nil for a pair
   of values a by value cannot be added to, which leaves the animation to
   settle its ends some other way. */
static id addValues(id value, id byValue, CGFloat sign)
{
  const char *type;

  if ([value isKindOfClass: [NSNumber class]]
      && [byValue isKindOfClass: [NSNumber class]])
    {
      return [NSNumber numberWithFloat:
        [value floatValue] + sign * [byValue floatValue]];
    }

  if (![value isKindOfClass: [NSValue class]]
      || ![byValue isKindOfClass: [NSValue class]])
    {
      return nil;
    }

  type = [value objCType];
  if (strcmp(type, [byValue objCType]))
    {
      return nil;
    }

  if (!strcmp(type, @encode(CGPoint)))
    {
      CGPoint a = { 0 }; [value getValue: &a];
      CGPoint b = { 0 }; [byValue getValue: &b];
      CGPoint r = CGPointMake(a.x + sign * b.x, a.y + sign * b.y);

      return [NSValue valueWithBytes: &r objCType: @encode(CGPoint)];
    }

  if (!strcmp(type, @encode(CGSize)))
    {
      CGSize a = { 0 }; [value getValue: &a];
      CGSize b = { 0 }; [byValue getValue: &b];
      CGSize r = CGSizeMake(a.width + sign * b.width,
                            a.height + sign * b.height);

      return [NSValue valueWithBytes: &r objCType: @encode(CGSize)];
    }

  if (!strcmp(type, @encode(CGRect)))
    {
      CGRect a = { { 0 } }; [value getValue: &a];
      CGRect b = { { 0 } }; [byValue getValue: &b];
      CGRect r = CGRectMake(a.origin.x + sign * b.origin.x,
                            a.origin.y + sign * b.origin.y,
                            a.size.width + sign * b.size.width,
                            a.size.height + sign * b.size.height);

      return [NSValue valueWithBytes: &r objCType: @encode(CGRect)];
    }

  return nil;
}

/** End helper math functions **/
/*******************************/


@implementation CABasicAnimation
@synthesize fromValue=_fromValue;
@synthesize byValue=_byValue;
@synthesize toValue=_toValue;

- (void) dealloc
{
  [_fromValue release];
  [_byValue release];
  [_toValue release];

  [super dealloc];
}

- (id) calculatedAnimationValueAtTime: (CFTimeInterval)theTime
                              onLayer: (CALayer *)layer
{
  /*
    A from value and a to value are interpolated between.  A by value
    stands in for whichever end was not given: with a from value the
    animation runs to that value plus the by value, with a to value it
    starts at that value minus the by value, and on its own it works from
    the value the layer already has.  A by value has no effect on a type it
    cannot be added to, which is every type but a number, a point, a size
    and a rectangle.

    All supplied values need to be of same data type.
   */

  /* An animation with no duration has no extent to be part way through: it
     is at its end from the moment it begins. */
  float fraction = _duration > 0.0 ? theTime / _duration : 1.0;

  /* apply media timing function, if set */
  if ([self timingFunction])
    {
      fraction = [[self timingFunction] evaluateYAtX: fraction];
    }

  /* Calculate what will our actual from and to values be */
  id fromValue = _fromValue;
  id toValue = _toValue;

  if (_byValue)
    {
      if (fromValue && !toValue)
        {
          toValue = addValues(fromValue, _byValue, 1.0);
        }
      else if (!fromValue && toValue)
        {
          fromValue = addValues(toValue, _byValue, -1.0);
        }
      else if (!fromValue && !toValue && _keyPath)
        {
          fromValue = [[layer modelLayer] valueForKeyPath: _keyPath];
          toValue = addValues(fromValue, _byValue, 1.0);
        }
    }

  if (!toValue)
    toValue = [[layer modelLayer] valueForKeyPath: _keyPath];

  if ([fromValue isKindOfClass: [NSNumber class]] &&
      [toValue isKindOfClass: [NSNumber class]])
    {
      /* It should be safe to presume that values can be
         represented as floats. */
      float from = [fromValue floatValue];
      float to = [toValue floatValue];

      float value = linearInterpolation(from, to, fraction);

      return [NSNumber numberWithFloat: value];
    }

  if ([fromValue isKindOfClass: [NSValue class]] &&
      [toValue isKindOfClass: [NSValue class]] &&
      !strcmp([fromValue objCType], [toValue objCType]))
    {
      NSValue *from = fromValue;
      NSValue *to = toValue;

      if (!strcmp([from objCType], @encode(NSPoint)))
        {
          /* Just convert to CGPoint. Core Animation doesn't deal with NSPoints! */
          /* After that, don't return; instead let the CGPoint branch deal with the values. */

          CGPoint fromPt = CGPointMake([from pointValue].x, [from pointValue].y);
          CGPoint toPt = CGPointMake([to pointValue].x, [to pointValue].y);

          from = [NSValue valueWithBytes: &fromPt objCType: @encode(CGPoint)];
          to = [NSValue valueWithBytes: &toPt objCType: @encode(CGPoint)];
        }
#if GNUSTEP
      if (!strcmp([from objCType], @encode(NSPoint)))
        {
          static BOOL warned = NO;
          if (!warned)
            {
              NSLog(@"CAAnimation: one time warning: bug in gnustep-base: despite storing cgpoint, we ended up with a nspoint.");
              if (sizeof(NSPoint) != sizeof(CGPoint))
                NSLog(@"(that's even more problematic since currently sizeof(NSPoint)==%d and sizeof(CGPoint)==%d.", sizeof(NSPoint), sizeof(CGPoint));
            }
          warned = YES;

          NSPoint fromPt = [from pointValue];
          NSPoint toPt = [to pointValue];
          NSPoint valuePt = NSMakePoint(linearInterpolation(fromPt.x, toPt.x, fraction),
                                        linearInterpolation(fromPt.y, toPt.y, fraction));
          return [NSValue valueWithPoint: valuePt];
        }
#endif
      if (!strcmp([from objCType], @encode(CGPoint)))
        {

          /* NSValue in GNUstep and Cocoa doesn't come with CGPoint support.
             Opal and Core Graphics don't provide it either.
             Support for it is an extension provided by UIKit. */
          /* Note: this branch CASCADES from NSPoint branch and
             should come immediately after it. */
          CGPoint fromPt = { 0 }; [from getValue:&fromPt];
          CGPoint toPt = { 0 }; [to getValue:&toPt];

          CGPoint valuePt = CGPointMake(linearInterpolation(fromPt.x, toPt.x, fraction),
                                      linearInterpolation(fromPt.y, toPt.y, fraction));
          return [NSValue valueWithBytes:&valuePt objCType:@encode(CGPoint)];
        }

      //////////////////////////////////
      if (!strcmp([from objCType], @encode(NSSize)))
        {
          /* Just convert to CGSize. Core Animation doesn't deal with NSSizes! */
          /* After that, don't return; instead let the CGSize branch deal with the values. */

          CGSize fromSz = CGSizeMake([from sizeValue].width, [from sizeValue].height);
          CGSize toSz = CGSizeMake([to sizeValue].width, [to sizeValue].height);

          from = [NSValue valueWithBytes: &fromSz objCType: @encode(CGSize)];
          to = [NSValue valueWithBytes: &toSz objCType: @encode(CGSize)];

        }
#if GNUSTEP
      if (!strcmp([from objCType], @encode(NSSize)))
        {
          static BOOL warned = NO;
          if (!warned)
            {
              NSLog(@"CAAnimation: one time warning: bug in gnustep-base: despite storing cgsize, we ended up with a nssize.");
              if (sizeof(NSSize) != sizeof(CGSize))
                NSLog(@"(that's even more problematic since currently sizeof(NSSize)==%d and sizeof(CGSize)==%d.", sizeof(NSSize), sizeof(CGSize));
            }
          warned = YES;

          NSSize fromSz = [from sizeValue];
          NSSize toSz = [to sizeValue];
          NSSize valueSz = NSMakeSize(linearInterpolation(fromSz.width, toSz.height, fraction),
                                      linearInterpolation(fromSz.width, toSz.height, fraction));
          return [NSValue valueWithSize: valueSz];
        }
#endif
      if (!strcmp([from objCType], @encode(CGSize)))
        {

          /* NSValue in GNUstep and Cocoa doesn't come with CGSize support.
             Opal and Core Graphics don't provide it either.
             Support for it is an extension provided by UIKit. */
          /* Note: this branch CASCADES from NSSize branch and
             should come immediately after it. */
          CGSize fromSz = { 0 }; [from getValue:&fromSz];
          CGSize toSz = { 0 }; [to getValue:&toSz];

          CGSize valueSz = CGSizeMake(linearInterpolation(fromSz.width, toSz.width, fraction),
                                      linearInterpolation(fromSz.height, toSz.height, fraction));
          return [NSValue valueWithBytes:&valueSz objCType:@encode(CGSize)];
        }

      //////////////////////////////////
      if (!strcmp([from objCType], @encode(NSRect)))
        {
          /* Just convert to CGRect. Core Animation doesn't deal with NSRects! */
          /* After that, don't return; instead let the CGPoint branch deal with the values. */

          CGRect fromRect = CGRectMake([from rectValue].origin.x, [from rectValue].origin.y,
                                       [from rectValue].size.width, [from rectValue].size.height);
          CGRect toRect = CGRectMake([to rectValue].origin.x, [to rectValue].origin.y,
                                     [to rectValue].size.width, [to rectValue].size.height);

          from = [NSValue valueWithBytes:&fromRect objCType:@encode(CGRect)];
          to = [NSValue valueWithBytes:&toRect objCType:@encode(CGRect)];
        }
#if GNUSTEP
      if (!strcmp([from objCType], @encode(NSRect)))
        {
          static BOOL warned = NO;
          if (!warned)
            {
              NSLog(@"CAAnimation: one time warning: bug in gnustep-base: despite storing cgrect, we ended up with a nsrect.");
              if (sizeof(NSRect) != sizeof(CGRect))
                NSLog(@"(that's even more problematic since currently sizeof(NSRect)==%d and sizeof(CGRect)==%d.", sizeof(NSRect), sizeof(CGRect));
            }
          warned = YES;

          NSRect fromRect = [from rectValue];
          NSRect toRect = [to rectValue];
          NSRect valueRect = NSMakeRect(linearInterpolation(fromRect.origin.x, toRect.origin.x, fraction),
                                        linearInterpolation(fromRect.origin.y, toRect.origin.y, fraction),
                                        linearInterpolation(fromRect.size.width, toRect.size.width, fraction),
                                        linearInterpolation(fromRect.size.height, toRect.size.height, fraction));
          return [NSValue valueWithRect: valueRect];
        }
#endif

      if (!strcmp([from objCType], @encode(CGRect)))
        {
          /* NSValue doesn't come with CGRect support.
             Opal and Core Graphics don't provide it either.
             This support is an extension provided by UIKit. */
          /* Note: this branch CASCADES from NSRect branch and
             should come immediately after it. */
          CGRect fromRect; [from getValue:&fromRect];
          CGRect toRect; [to getValue:&toRect];

          CGRect valueRect = CGRectMake(linearInterpolation(fromRect.origin.x, toRect.origin.x, fraction),
                                        linearInterpolation(fromRect.origin.y, toRect.origin.y, fraction),
                                        linearInterpolation(fromRect.size.width, toRect.size.width, fraction),
                                        linearInterpolation(fromRect.size.height, toRect.size.height, fraction));

          return [NSValue valueWithBytes:&valueRect objCType:@encode(CGRect)];
        }


      //////////////////////////////////

      if (!strcmp([from objCType], @encode(CATransform3D)))
        {
          CATransform3D fromTf = [from CATransform3DValue];
          CATransform3D toTf = [to CATransform3DValue];
          CATransform3D valueTf;
          memcpy(&valueTf, &CATransform3DIdentity, sizeof(valueTf));

          /* A simple implementation of matrix decomposition based on:
             http://www.gamedev.net/topic/441695-transform-matrix-decomposition/
             Also incorrect; on the other hand, it's simple, and can later be
             replaced by something "smarter" and more complex

             Decomposition will be useful in implementing valueForKeypath: for
             transform "subproperties" such as .translation, .translation.x,
             .rotation, etc.
             */

          /* FIXME! Adjust the code below as well as quaternion<->matrix conversion
             to avoid calls to transpose(). */
          fromTf = transpose(fromTf);
          toTf = transpose(toTf);
          /* FIXME! */

          /* translation */
          CGFloat fromTX = fromTf.m14, fromTY = fromTf.m24, fromTZ = fromTf.m34;
          CGFloat   toTX =   toTf.m14,   toTY =   toTf.m24,   toTZ =   toTf.m34;

          CGFloat valueTX = linearInterpolation(fromTX, toTX, fraction);
          CGFloat valueTY = linearInterpolation(fromTY, toTY, fraction);
          CGFloat valueTZ = linearInterpolation(fromTZ, toTZ, fraction);

          /* scale */
          #define GSQC_POW2(x) ((x)*(x))
          CGFloat fromSX = sqrt(GSQC_POW2(fromTf.m11) + GSQC_POW2(fromTf.m12) + GSQC_POW2(fromTf.m13));
          CGFloat fromSY = sqrt(GSQC_POW2(fromTf.m21) + GSQC_POW2(fromTf.m22) + GSQC_POW2(fromTf.m23));
          CGFloat fromSZ = sqrt(GSQC_POW2(fromTf.m31) + GSQC_POW2(fromTf.m32) + GSQC_POW2(fromTf.m33));

          CGFloat toSX = sqrt(GSQC_POW2(toTf.m11) + GSQC_POW2(toTf.m12) + GSQC_POW2(toTf.m13));
          CGFloat toSY = sqrt(GSQC_POW2(toTf.m21) + GSQC_POW2(toTf.m22) + GSQC_POW2(toTf.m23));
          CGFloat toSZ = sqrt(GSQC_POW2(toTf.m31) + GSQC_POW2(toTf.m32) + GSQC_POW2(toTf.m33));
          #undef GSQC_POW2

          CGFloat valueSX = linearInterpolation(fromSX, toSX, fraction);
          CGFloat valueSY = linearInterpolation(fromSY, toSY, fraction);
          CGFloat valueSZ = linearInterpolation(fromSZ, toSZ, fraction);


          /* rotation */
          CATransform3D fromRotation;
          fromRotation.m11 = fromTf.m11 / fromSX;
          fromRotation.m12 = fromTf.m12 / fromSX;
          fromRotation.m13 = fromTf.m13 / fromSX;
          fromRotation.m14 = 0;

          fromRotation.m21 = fromTf.m21 / fromSY;
          fromRotation.m22 = fromTf.m22 / fromSY;
          fromRotation.m23 = fromTf.m23 / fromSY;
          fromRotation.m24 = 0;

          fromRotation.m31 = fromTf.m31 / fromSZ;
          fromRotation.m32 = fromTf.m32 / fromSZ;
          fromRotation.m33 = fromTf.m33 / fromSZ;
          fromRotation.m34 = 0;

          fromRotation.m41 = 0;
          fromRotation.m42 = 0;
          fromRotation.m43 = 0;
          fromRotation.m44 = 1;

          CATransform3D toRotation;
          toRotation.m11 = toTf.m11 / toSX;
          toRotation.m12 = toTf.m12 / toSX;
          toRotation.m13 = toTf.m13 / toSX;
          toRotation.m14 = 0;

          toRotation.m21 = toTf.m21 / toSY;
          toRotation.m22 = toTf.m22 / toSY;
          toRotation.m23 = toTf.m23 / toSY;
          toRotation.m24 = 0;

          toRotation.m31 = toTf.m31 / toSZ;
          toRotation.m32 = toTf.m32 / toSZ;
          toRotation.m33 = toTf.m33 / toSZ;
          toRotation.m34 = 0;

          toRotation.m41 = 0;
          toRotation.m42 = 0;
          toRotation.m43 = 0;
          toRotation.m44 = 1;

          GSQuartzCoreQuaternion fromQuat = matrixToQuaternion(fromRotation);
          GSQuartzCoreQuaternion toQuat = matrixToQuaternion(toRotation);

          CGFloat fromQuatLen = sqrt(fromQuat.x*fromQuat.x + fromQuat.y*fromQuat.y + fromQuat.z*fromQuat.z + fromQuat.w*fromQuat.w);
          fromQuat.x /= fromQuatLen;
          fromQuat.y /= fromQuatLen;
          fromQuat.z /= fromQuatLen;
          fromQuat.w /= fromQuatLen;
          CGFloat toQuatLen = sqrt(toQuat.x*toQuat.x + toQuat.y*toQuat.y + toQuat.z*toQuat.z + toQuat.w*toQuat.w);
          toQuat.x /= toQuatLen;
          toQuat.y /= toQuatLen;
          toQuat.z /= toQuatLen;
          toQuat.w /= toQuatLen;

          GSQuartzCoreQuaternion valueQuat;
          valueQuat = linearInterpolationQuaternion(fromQuat, toQuat, fraction);

          valueTf = quaternionToMatrix(valueQuat);

          /* apply scale */
          valueTf.m11 *= valueSX;
          valueTf.m12 *= valueSX;
          valueTf.m13 *= valueSX;

          valueTf.m21 *= valueSY;
          valueTf.m22 *= valueSY;
          valueTf.m23 *= valueSY;

          valueTf.m31 *= valueSZ;
          valueTf.m32 *= valueSZ;
          valueTf.m33 *= valueSZ;

          /* apply translation */
          valueTf.m14 = valueTX;
          valueTf.m24 = valueTY;
          valueTf.m34 = valueTZ;


          valueTf = transpose(valueTf);

          return [NSValue valueWithCATransform3D: valueTf];
        }

    }

  #if !GNUSTEP
  // Core Graphics uses Core Foundation types internally
  if ([fromValue isKindOfClass: NSClassFromString(@"__NSCFType")] &&
      [toValue isKindOfClass: NSClassFromString(@"__NSCFType")] &&
      CFGetTypeID(fromValue) == CGColorGetTypeID() &&
      CFGetTypeID(toValue) == CGColorGetTypeID())
  #else
  // Opal uses Objective-C classes internally
  if ([fromValue isKindOfClass: NSClassFromString(@"CGColor")] &&
      [toValue isKindOfClass: NSClassFromString(@"CGColor")])
  #endif
    {
      CGColorRef from = (CGColorRef)fromValue;
      CGColorRef to = (CGColorRef)toValue;

      if (CGColorGetNumberOfComponents(from) == CGColorGetNumberOfComponents(to) &&
          CGColorGetColorSpace(from) == CGColorGetColorSpace(to))
        {
          const CGFloat * fromComponents = CGColorGetComponents(from);
          const CGFloat * toComponents = CGColorGetComponents(to);

          size_t numberOfComponents = CGColorGetNumberOfComponents(from);

          CGFloat valueComponents[4] = { 0, 0, 0, 1 }; //numberOfComponents];
          for (int i = 0; i < numberOfComponents; i++)
            {
              valueComponents[i] = linearInterpolation(fromComponents[i], toComponents[i], fraction);
            }

          return [(id)CGColorCreate(CGColorGetColorSpace(from), valueComponents) autorelease];
        }
    }
  return nil;
}

@end

/* Which of the SEGMENTS the fraction falls in, and how far along that one it
   is.  KEYTIMES says where each segment ends; without it they are evenly
   spaced. */
static NSUInteger segmentForFraction(NSArray *keyTimes, NSUInteger segments,
                                     float fraction, float *within)
{
  NSUInteger index;

  *within = 0.0;
  if (segments == 0)
    {
      return 0;
    }

  if ([keyTimes count] >= 2)
    {
      NSUInteger last = [keyTimes count] - 1;

      for (index = 0; index < last; index++)
        {
          float start = [[keyTimes objectAtIndex: index] floatValue];
          float end = [[keyTimes objectAtIndex: index + 1] floatValue];

          if (fraction <= end || index + 1 == last)
            {
              if (end > start)
                {
                  *within = (fraction - start) / (end - start);
                  if (*within < 0.0)
                    *within = 0.0;
                  if (*within > 1.0)
                    *within = 1.0;
                }
              return index < segments ? index : segments - 1;
            }
        }
    }

  {
    float scaled = fraction * segments;

    index = (NSUInteger)scaled;
    if (index >= segments)
      {
        index = segments - 1;
        *within = 1.0;
      }
    else
      {
        *within = scaled - index;
      }
  }

  return index;
}

@implementation CAKeyframeAnimation
@synthesize calculationMode=_calculationMode;
@synthesize values=_values;
@synthesize keyTimes=_keyTimes;
@synthesize timingFunctions=_timingFunctions;

+ (id) defaultValueForKey: (NSString *)key
{
  if ([key isEqualToString: @"calculationMode"])
    {
      return kCAAnimationLinear;
    }

  return [super defaultValueForKey: key];
}

- (id) init
{
  return [self initWithKeyPath: nil];
}

- (id) initWithKeyPath: (NSString *)keyPath
{
  self = [super initWithKeyPath: keyPath];
  if (!self)
    return nil;

  _calculationMode = [kCAAnimationLinear copy];

  return self;
}

- (void) dealloc
{
  [_calculationMode release];
  [_values release];
  [_keyTimes release];
  [_timingFunctions release];

  [super dealloc];
}

- (id) calculatedAnimationValueAtTime: (CFTimeInterval)theTime
                              onLayer: (CALayer *)layer
{
  /*
    The values are run through in order.  keyTimes says where each of them
    falls between 0 and 1, and without it they are evenly spaced.  A discrete
    animation steps from one value to the next without interpolating; every
    other mode interpolates between the two values the time falls between,
    which is what a basic animation does with a from value and a to value.

    Only the linear and discrete modes are calculated.  The paced modes are
    taken as linear, and an animation along a path is not supported.
   */

  NSUInteger count = [_values count];
  NSUInteger index;
  float fraction;
  float within = 0.0;
  CABasicAnimation *segment;

  if (count == 0)
    {
      return nil;
    }
  if (count == 1)
    {
      return [_values objectAtIndex: 0];
    }

  fraction = _duration > 0.0 ? theTime / _duration : 1.0;
  if ([self timingFunction])
    {
      fraction = [[self timingFunction] evaluateYAtX: fraction];
    }

  /* Asking outside the duration would run off the end of the values. */
  if (fraction < 0.0)
    fraction = 0.0;
  if (fraction > 1.0)
    fraction = 1.0;

  if ([_calculationMode isEqualToString: kCAAnimationDiscrete])
    {
      index = segmentForFraction(_keyTimes, count, fraction, &within);

      return [_values objectAtIndex: index];
    }

  index = segmentForFraction(_keyTimes, count - 1, fraction, &within);

  segment = [CABasicAnimation animationWithKeyPath: [self keyPath]];
  [segment setDuration: 1.0];
  [segment setFromValue: [_values objectAtIndex: index]];
  [segment setToValue: [_values objectAtIndex: index + 1]];
  if ([_timingFunctions count] > index)
    {
      [segment setTimingFunction: [_timingFunctions objectAtIndex: index]];
    }

  return [segment calculatedAnimationValueAtTime: within onLayer: layer];
}

@end

@implementation CASpringAnimation
@synthesize mass = _mass;
@synthesize stiffness = _stiffness;
@synthesize damping = _damping;
@synthesize initialVelocity = _initialVelocity;
@synthesize settlingDuration = _settlingDuration;
@end

@implementation CATransition
@synthesize type=_type;
@synthesize subtype=_subtype;

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
