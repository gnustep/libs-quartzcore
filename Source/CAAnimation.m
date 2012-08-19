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
    
    CGFloat dotproduct = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
	CGFloat theta, st, sut, sout, coeff1, coeff2;

	theta = acos(dotproduct);
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
    Currently supporting scenarios with:
     - fromValue != nil
     - toValue != nil
     - byValue == nil
    and
     - fromValue != nil
     - toValue == nil
     - byValue == nil
    and
     - fromValue == nil
     - toValue == nil
     - byValue == nil
    and
     - fromValue == nil
     - toValue != nil
     - byValue == nil
     
    All supplied values need to be of same data type.
   */
  
  float fraction = theTime / _duration;

  /* apply media timing function, if set */
  if ([self timingFunction])
    {
      fraction = [[self timingFunction] evaluateYAtX: fraction];
    }
  
  /* Calculate what will our actual from and to values be */
  id fromValue = _fromValue;
  id toValue = _toValue;
  
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
          
          from = [NSValue valueWithBytes:&fromPt objCType:@encode(CGPoint)];
          to = [NSValue valueWithBytes:&toPt objCType:@encode(CGPoint)];
        }
        
      if (!strcmp([from objCType], @encode(CGPoint)))
        {
          /* NSValue doesn't come with CGPoint support.
             Opal and Core Graphics don't provide it either.
             This support is an extension provided by UIKit. */
          /* Note: this branch CASCADES from NSPoint branch and
             should come immediately after it. */
          CGPoint fromPt; [from getValue:&fromPt];
          CGPoint toPt; [to getValue:&toPt];
          
          CGPoint valuePt = CGPointMake(linearInterpolation(fromPt.x, toPt.x, fraction),
                                      linearInterpolation(fromPt.y, toPt.y, fraction));
          return [NSValue valueWithBytes:&valuePt objCType:@encode(CGPoint)];
        }
        
      //////////////////////////////////
      if (!strcmp([from objCType], @encode(NSRect)))
        {
          /* Just convert to CGPoint. Core Animation doesn't deal with NSPoints! */
          /* After that, don't return; instead let the CGPoint branch deal with the values. */
          
          CGRect fromRect = CGRectMake([from rectValue].origin.x, [from rectValue].origin.y,
                                       [from rectValue].size.width, [from rectValue].size.height);
          CGRect toRect = CGRectMake([to rectValue].origin.x, [to rectValue].origin.y,
                                     [to rectValue].size.width, [to rectValue].size.height);
          
          from = [NSValue valueWithBytes:&fromRect objCType:@encode(CGRect)];
          to = [NSValue valueWithBytes:&toRect objCType:@encode(CGRect)];
        }
        
      if (!strcmp([from objCType], @encode(CGRect)))
        {
          /* NSValue doesn't come with CGRect support.
             Opal and Core Graphics don't provide it either.
             This support is an extension provided by UIKit. */
          /* Note: this branch CASCADES from NSPoint branch and
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
          CGFloat valueComponents[numberOfComponents];
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

@implementation CAKeyframeAnimation
@synthesize calculationMode=_calculationMode;
@synthesize values=_values;

@end

@implementation CATransition
@synthesize type=_type;
@synthesize subtype=_subtype;

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
