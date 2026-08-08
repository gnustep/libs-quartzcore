/* CAGradientLayer.m

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

#import <Foundation/Foundation.h>
#import "QuartzCore/CAGradientLayer.h"
#import "CALayer+FrameworkPrivate.h"

#include <math.h>
#include <stdlib.h>

NSString *const kCAGradientLayerAxial = @"axial";
NSString *const kCAGradientLayerRadial = @"radial";
NSString *const kCAGradientLayerConic = @"conic";

@implementation CAGradientLayer

@synthesize colors = _colors;
@synthesize locations = _locations;
@synthesize startPoint = _startPoint;
@synthesize endPoint = _endPoint;
@synthesize type = _type;

- (id) init
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  _startPoint = CGPointMake(0.5, 0.0);
  _endPoint = CGPointMake(0.5, 1.0);
  _type = [kCAGradientLayerAxial copy];

  return self;
}

- (void) dealloc
{
  [_colors release];
  [_locations release];
  [_type release];

  [super dealloc];
}

/* The gradient is drawn under the layer's contents, in the layer's own
   bounds, with startPoint and endPoint as unit points in those bounds.  A
   corner radius rounds it whether or not the layer masks to its bounds. */
- (void) drawBackgroundInContext: (CGContextRef)context
{
  CGRect bounds = [self bounds];
  NSUInteger count = [_colors count];
  CGColorSpaceRef space;
  CGGradientRef gradient;
  CGFloat *stops;
  CGPoint from, to;
  NSUInteger i;

  /* Two colours are the least that makes a gradient, and a location list,
     where there is one, has an entry for each colour. */
  if (count < 2)
    return;
  if (_locations != nil && [_locations count] != count)
    return;
  if (![_type isEqualToString: kCAGradientLayerAxial]
      && ![_type isEqualToString: kCAGradientLayerRadial])
    return;

  stops = malloc(count * sizeof(CGFloat));
  for (i = 0; i < count; i++)
    {
      if (_locations != nil)
        stops[i] = [[_locations objectAtIndex: i] floatValue];
      else
        stops[i] = (CGFloat)i / (CGFloat)(count - 1);
    }

  /* Opal draws a gradient only in device RGB, and copies the locations
     without checking for the NULL the documentation allows. */
  space = CGColorSpaceCreateDeviceRGB();
  gradient = CGGradientCreateWithColors(space, (CFArrayRef)_colors, stops);
  CGColorSpaceRelease(space);
  free(stops);
  if (gradient == NULL)
    return;

  from = CGPointMake(CGRectGetMinX(bounds) + _startPoint.x * bounds.size.width,
                     CGRectGetMinY(bounds)
                       + _startPoint.y * bounds.size.height);
  to = CGPointMake(CGRectGetMinX(bounds) + _endPoint.x * bounds.size.width,
                   CGRectGetMinY(bounds) + _endPoint.y * bounds.size.height);

  CGContextSaveGState(context);
  CALayerAddRoundedRect(context, bounds, [self cornerRadius]);
  CGContextClip(context);
  if ([_type isEqualToString: kCAGradientLayerRadial])
    {
      /* Radial is an ellipse centred on startPoint, its radii the distance to
         endPoint in each axis.  Apple draws nothing where either radius is 0,
         so neither does this.  The ellipse is a unit circle under a scaled
         coordinate system, which is what CGContextDrawRadialGradient takes. */
      CGFloat rx = fabs(to.x - from.x);
      CGFloat ry = fabs(to.y - from.y);

      if (rx > 0.0 && ry > 0.0)
        {
          CGContextTranslateCTM(context, from.x, from.y);
          CGContextScaleCTM(context, rx, ry);
          CGContextDrawRadialGradient(context, gradient, CGPointZero, 0.0,
                                      CGPointZero, 1.0,
                                      kCGGradientDrawsBeforeStartLocation
                                      | kCGGradientDrawsAfterEndLocation);
        }
    }
  else
    {
      CGContextDrawLinearGradient(context, gradient, from, to,
                                  kCGGradientDrawsBeforeStartLocation
                                  | kCGGradientDrawsAfterEndLocation);
    }
  CGContextRestoreGState(context);
  CGGradientRelease(gradient);
}

@end
