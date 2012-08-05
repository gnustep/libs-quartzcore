/* CAMediaTimingFunction.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: July 2012
   
   Author: Amr Aboelela <amraboelela@gmail.com>

   Additional credits:
   Bezier-related mathematics in this file is in part based on 
   implementation in NSAnimation.* from GNUstep GUI, created by 
   Dr. H. Nikolaus Schaller, and authored by Xavier Glattard.

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
#import "QuartzCore/CAMediaTimingFunction.h"
#import "CAMediaTimingFunction+FrameworkPrivate.h"

NSString *const kCAMediaTimingFunctionDefault = @"kCAMediaTimingFunctionDefault";
NSString *const kCAMediaTimingFunctionEaseInEaseOut = @"kCAMediaTimingFunctionEaseInEaseOut";
NSString *const kCAMediaTimingFunctionEaseIn = @"kCAMediaTimingFunctionEaseIn";
NSString *const kCAMediaTimingFunctionEaseOut = @"kCAMediaTimingFunctionEaseOut";
NSString *const kCAMediaTimingFunctionLinear = @"kCAMediaTimingFunctionLinear";


// start and end point are implicitly (0.0, 0.0) and (1.0, 1.0)
static const float _c0x = 0.0;
static const float _c0y = 0.0;
static const float _c3x = 1.0;
static const float _c3y = 1.0;
  
@implementation CAMediaTimingFunction
+ (id) functionWithName:(NSString *)name
{
  /* None of these were documented except 'default'. */
  /* see: http://netcetera.org/camtf-playground.html */
  
  if ([name isEqualToString: kCAMediaTimingFunctionDefault])
    {
      /* netcetera.org source claims this one was misdocumented.
         So, we use their numbers. */
      return [self functionWithControlPoints: 0.25
                                            : 0.1
                                            : 0.25
                                            : 1.0];
    }
  if ([name isEqualToString: kCAMediaTimingFunctionEaseInEaseOut])
    {
      return [self functionWithControlPoints: 0.42
                                            : 0.0
                                            : 0.58
                                            : 1.0]; 
    }
  if ([name isEqualToString: kCAMediaTimingFunctionEaseIn])
    {
      return [self functionWithControlPoints: 0.42
                                            : 0.0
                                            : 1.0
                                            : 1.0];
    }
  if ([name isEqualToString: kCAMediaTimingFunctionEaseOut])
    {
      return [self functionWithControlPoints: 0.0
                                            : 0.0
                                            : 0.58
                                            : 1.0];
    }
  if ([name isEqualToString: kCAMediaTimingFunctionLinear])
    {
      return [self functionWithControlPoints: 0.0
                                            : 0.0
                                            : 1.0
                                            : 1.0];
    }
  return nil;
}

+ (id) functionWithControlPoints: (float)c1x
                                : (float)c1y
                                : (float)c2x
                                : (float)c2y
{
  return [[[self alloc] initWithControlPoints: c1x
                                             : c1y
                                             : c2x
                                             : c2y] autorelease];
}

- (id) initWithControlPoints: (float)c1x
                            : (float)c1y
                            : (float)c2x
                            : (float)c2y
{
  self = [super init];
  if(!self)
    return nil;
  
  _c1x = c1x;
  _c1y = c1y;
  _c2x = c2x;
  _c2y = c2y;

  // calculate coefficients
  _coefficientsX[0] = _c0x; // t^0
  _coefficientsX[1] = -3.0*_c0x + 3.0*_c1x; // t^1
  _coefficientsX[2] = 3.0*_c0x - 6.0*_c1x + 3.0*_c2x;  // t^2
  _coefficientsX[3] = -_c0x + 3.0*_c1x - 3.0*_c2x + _c3x; // t^3
  
  _coefficientsY[0] = _c0y; // t^0
  _coefficientsY[1] = -3.0*_c0y + 3.0*_c1y; // t^1
  _coefficientsY[2] = 3.0*_c0y - 6.0*_c1y + 3.0*_c2y;  // t^2
  _coefficientsY[3] = -_c0y + 3.0*_c1y - 3.0*_c2y + _c3y; // t^3
  
  return self;
}

- (void)getControlPointAtIndex: (size_t)index values: (float*)ptr
{
  switch (index)
    {
      case 0:
        ptr[0] = _c0x;
        ptr[1] = _c0y;
        break;
      case 1:
        ptr[0] = _c1x;
        ptr[1] = _c1y;
        break;
      case 2:
        ptr[0] = _c2x;
        ptr[1] = _c2y;
        break;
      case 3:
        ptr[0] = _c3x;
        ptr[1] = _c3y;
        break;
    }
}

static inline CGFloat evaluateAtParameterWithCoefficients(CGFloat t, CGFloat coefficients[])
{
  return coefficients[0] + t*coefficients[1] + t*t*coefficients[2] + t*t*t*coefficients[3];
}

static inline CGFloat evaluateDerivationAtParameterWithCoefficients(CGFloat t, CGFloat coefficients[])
{
  return coefficients[1] + 2*t*coefficients[2] + 3*t*t*coefficients[3];
}

static inline CGFloat calcParameterViaNewtonRaphsonUsingXAndCoefficientsForX(CGFloat x, CGFloat coefficientsX[])
{
  // see http://en.wikipedia.org/wiki/Newton's_method
    
  // start with X being the correct value
  CGFloat t = x;
    
  // iterate several times
  const CGFloat epsilon = 0.00001;
  for(int i = 0; i < 10; i++)
    {
      CGFloat x2 = evaluateAtParameterWithCoefficients(t, coefficientsX) - x;
      CGFloat d = evaluateDerivationAtParameterWithCoefficients(t, coefficientsX);
      
      CGFloat dt = x2/d;
      
      t = t - dt;      
    }
    
  return t;
}

static inline CGFloat calcParameterUsingXAndCoefficientsForX (CGFloat x, CGFloat coefficientsX[])
{
  // for the time being, we'll guess Newton-Raphson always
  // returns the correct value.
  
  // if we find it doesn't find the solution often enough,
  // we can add additional calculation methods.
    
  CGFloat t = calcParameterViaNewtonRaphsonUsingXAndCoefficientsForX(x, coefficientsX);
    
  return t;
}

- (CGFloat) evaluateYAtX: (CGFloat)x
{
  CGFloat t = calcParameterUsingXAndCoefficientsForX(x, _coefficientsX);
  CGFloat y = evaluateAtParameterWithCoefficients(t, _coefficientsY);
  
  return y;
}

- (float) _solveForInput: (float)x
{
  /* Private method in Cocoa. Implemented so our tests
     can call and use a single method. */
  return (float)[self evaluateYAtX: (float)x];
}

/*
- (CGPoint) valueForParameter: (CGFloat)t
{
  CGFloat x, y, k;
  
  k = ((1-t)*(1-t)*(1-t));
  
  x = _c1x * (3*t*t*(1-t)) + _c2x * (3*t*(1-t)*(1-t)) + k;
  y = _c1y * (3*t*t*(1-t)) + _c2y * (3*t*(1-t)*(1-t)) + k;
  
  return CGPointMake(x, y);
}
*/
@end
/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
