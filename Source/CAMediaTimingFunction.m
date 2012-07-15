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

- (CGFloat) evaluateXAtParameter: (CGFloat)t
{
  return _coefficientsX[0] + t*_coefficientsX[1] + t*t*_coefficientsX[2] + t*t*t*_coefficientsX[3];
}
- (CGFloat) evaluateYAtParameter: (CGFloat)t
{
  return _coefficientsY[0] + t*_coefficientsY[1] + t*t*_coefficientsY[2] + t*t*t*_coefficientsY[3];
}

- (CGFloat) evaluateDerivationForXAtParameter: (CGFloat)t
{
  return _coefficientsX[1] + 2*t*_coefficientsX[2] + 3*t*t*_coefficientsX[3];
}

- (CGFloat) evaluateDerivationForYAtParameter: (CGFloat)t
{
  return _coefficientsY[1] + 2*t*_coefficientsY[2] + 3*t*t*_coefficientsY[3];
}

- (CGFloat) calcParameterViaNewtonRaphsonUsingX: (CGFloat)x
{
  // see http://en.wikipedia.org/wiki/Newton's_method
    
  // start with X being the correct value
  CGFloat t = x;
    
  // iterate several times
  const CGFloat epsilon = 0.00001;
  for(int i = 0; i < 10; i++)
    {
      CGFloat x2 = [self evaluateXAtParameter: t] - x;
      CGFloat d = [self evaluateDerivationForXAtParameter: t];
      
      CGFloat dt = x2/d;
      
      t = t - dt;
      
      //NSLog(@"x: %f x2: %f d: %f dt: %f t: %f", x, x2, d, dt, t);
    }
    
  return t;
}

- (CGFloat) calcParameterUsingX: (CGFloat)x
{
  // for the time being, we'll guess Newton-Raphson always
  // returns the correct value.
  
  // if we find it doesn't find the solution often enough,
  // we can add additional calculation methods.
    
  CGFloat t = [self calcParameterViaNewtonRaphsonUsingX: x];
    
  return t;
}

- (CGFloat) evaluateYAtX: (CGFloat)x
{
  CGFloat t = [self calcParameterUsingX: x];
  CGFloat y = [self evaluateYAtParameter: t];
  //NSLog(@"X: %g T: %g Y: %g", x, t, y);
  
  return y;
}

- (void) graph
{
  printf("--------\n");
  for (int i = 0; i < 20; i++)
    {
      for (int j = 0; j < 40; j++)
        {
          float x = j / 40.;
          float y = 1.-(i / 20.);
          
          if ([self evaluateYAtX: x] > y)
            {
              printf("*");
            }
          else
            {
              printf(" ");
            }
        }
      printf("\n");
    }
  printf("==========\n");

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