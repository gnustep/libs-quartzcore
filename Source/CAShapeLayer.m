/* CAShapeLayer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>

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

#import "QuartzCore/CAShapeLayer.h"

NSString *const kCAFillRuleNonZero = @"non-zero";
NSString *const kCAFillRuleEvenOdd = @"even-odd";
                                    
NSString *const kCALineJoinMiter = @"miter";
NSString *const kCALineJoinRound = @"round";
NSString *const kCALineJoinBevel = @"bevel";
                                    
NSString *const kCALineCapButt = @"butt";
NSString *const kCALineCapRound = @"round";
NSString *const kCALineCapSquare = @"square";

@implementation CAShapeLayer
@synthesize path = _path;
@synthesize fillColor = _fillColor;
@synthesize fillRule = _fillRule;
@synthesize strokeColor = _strokeColor;
@synthesize strokeStart = _strokeStart;
@synthesize strokeEnd = _strokeEnd;
@synthesize lineWidth = _lineWidth;
@synthesize miterLimit = _miterLimit;
@synthesize lineCap = _lineCap;
@synthesize lineJoin = _lineJoin;
@synthesize lineDashPhase = _lineDashPhase;
@synthesize lineDashPattern = _lineDashPattern;

/* The three setters below notify by hand, as CALayer's colour setters do. */
+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *)key
{
  if ([key isEqualToString: @"path"]
      || [key isEqualToString: @"fillColor"]
      || [key isEqualToString: @"strokeColor"])
    {
      return NO;
    }

  return [super automaticallyNotifiesObserversForKey: key];
}

+ (id) defaultValueForKey: (NSString *)key
{
  if ([key isEqualToString: @"fillColor"])
    {
      /* opaque black, as for the colours CALayer hands out */
      return [(id)CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0) autorelease];
    }
  if ([key isEqualToString: @"fillRule"])
    {
      return kCAFillRuleNonZero;
    }
  if ([key isEqualToString: @"strokeEnd"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString: @"lineWidth"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString: @"miterLimit"])
    {
      return [NSNumber numberWithFloat: 10.0];
    }
  if ([key isEqualToString: @"lineCap"])
    {
      return kCALineCapButt;
    }
  if ([key isEqualToString: @"lineJoin"])
    {
      return kCALineJoinMiter;
    }

  return [super defaultValueForKey: key];
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      Class cls = [self class];

      [self setFillColor: (CGColorRef)[cls defaultValueForKey: @"fillColor"]];
      [self setFillRule: [cls defaultValueForKey: @"fillRule"]];
      [self setStrokeEnd:
        [[cls defaultValueForKey: @"strokeEnd"] floatValue]];
      [self setLineWidth:
        [[cls defaultValueForKey: @"lineWidth"] floatValue]];
      [self setMiterLimit:
        [[cls defaultValueForKey: @"miterLimit"] floatValue]];
      [self setLineCap: [cls defaultValueForKey: @"lineCap"]];
      [self setLineJoin: [cls defaultValueForKey: @"lineJoin"]];
    }
  return self;
}

/* Core Graphics types are not KVC-compliant, so the three below are reached
   by key the same way CALayer reaches its own colours. */
- (id) valueForUndefinedKey: (NSString *)key
{
  if ([key isEqualToString: @"path"])
    {
      return (id)[self path];
    }
  if ([key isEqualToString: @"fillColor"])
    {
      return (id)[self fillColor];
    }
  if ([key isEqualToString: @"strokeColor"])
    {
      return (id)[self strokeColor];
    }

  return [super valueForUndefinedKey: key];
}

- (void) setValue: (id)value forUndefinedKey: (NSString *)key
{
  if ([key isEqualToString: @"path"])
    {
      [self setPath: (CGPathRef)value];
      return;
    }
  if ([key isEqualToString: @"fillColor"])
    {
      [self setFillColor: (CGColorRef)value];
      return;
    }
  if ([key isEqualToString: @"strokeColor"])
    {
      [self setStrokeColor: (CGColorRef)value];
      return;
    }

  [super setValue: value forUndefinedKey: key];
}

- (void) dealloc
{
  CGPathRelease(_path);
  CGColorRelease(_fillColor);
  CGColorRelease(_strokeColor);
  [_fillRule release];
  [_lineCap release];
  [_lineJoin release];
  [_lineDashPattern release];

  [super dealloc];
}

/* The two colours and the path are owned by the layer, as they are on
   CALayer, so the caller may release its own reference. */
- (void) setPath: (CGPathRef)path
{
  if (path == _path)
    return;

  [self willChangeValueForKey: @"path"];
  CGPathRetain(path);
  CGPathRelease(_path);
  _path = path;
  [self didChangeValueForKey: @"path"];
}

- (void) setFillColor: (CGColorRef)fillColor
{
  if (fillColor == _fillColor)
    return;

  [self willChangeValueForKey: @"fillColor"];
  CGColorRetain(fillColor);
  CGColorRelease(_fillColor);
  _fillColor = fillColor;
  [self didChangeValueForKey: @"fillColor"];
}

- (void) setStrokeColor: (CGColorRef)strokeColor
{
  if (strokeColor == _strokeColor)
    return;

  [self willChangeValueForKey: @"strokeColor"];
  CGColorRetain(strokeColor);
  CGColorRelease(_strokeColor);
  _strokeColor = strokeColor;
  [self didChangeValueForKey: @"strokeColor"];
}

@end
