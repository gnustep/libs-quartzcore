/* Tests/CAMediaTimingFunction/camediatimingfunction.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vucica <ivan@vucica.net>
   Date: August 2012

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

#if GSIMPL_UNDER_COCOA
#import <GSQuartzCore/AppleSupport.h>
#endif

#import <QuartzCore/CAMediaTimingFunction.h>
#import "../Testing.h"

#define QC_EXACT_FLOAT_EQUALITY 0

/* Private method for calculating input. */
@interface CAMediaTimingFunction ()
- (float) _solveForInput: (float)x;
@end

@interface CAMediaTimingFunction (TestGraph)
- (void) testGraph;
@end
@implementation CAMediaTimingFunction (TestGraph)
- (void) testGraph
{
  printf("--------\n");
  for (int i = 0; i < 20; i++)
    {
      for (int j = 0; j < 40; j++)
        {
          float x = j / 40.;
          float y = 1.-(i / 20.);
          
          if ([self _solveForInput: x] > y)
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


@end


BOOL QCFloatsAreEqual(float a, float b)
{
#if QC_EXACT_FLOAT_EQUALITY
  return a == b;
#else
  return fabs(b - a) < 0.00001;
#endif
}

void QCPrintControlPoints(float *values)
{
  for (int i = 0; i < 4; i++)
    {
      printf("(%.02f %.02f)%s", values[i*2+0], values[i*2+1], i!=3 ? ", " : "\n");
    }
}

void QCGetControlPoints(CAMediaTimingFunction *func, float *controlPointValues)
{
  for (int i = 0; i < 4; i++)
    {
      [func getControlPointAtIndex: i
                            values: controlPointValues+(i*2)];
    }
}

BOOL QCControlPointValuesAreEqual(float *a, float *b)
{
  for (int i = 0; i < 4; i++)
    {
      if (!QCFloatsAreEqual(a[i*2+0], b[i*2+0]) ||
          !QCFloatsAreEqual(a[i*2+1], b[i*2+1]))
        return NO;
    }
  return YES;
}

int main(int argc, char ** argv)
{
  int testsFailed = 0;
  
  float controlPointValues[8];
  //////////////////////////

  CAMediaTimingFunction * defaultFunc = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionDefault];
  float correctDefaultFuncControlPointValues[] = { 
    0.0, 0.0,  0.25, 0.1,  0.25, 1.0,  1.0, 1.0 };

  QCGetControlPoints(defaultFunc, controlPointValues);
  PASS(QCControlPointValuesAreEqual(
    controlPointValues, correctDefaultFuncControlPointValues),
    "default function control points are correct");
  //////////////////////////

  CAMediaTimingFunction * easeInEaseOutFunc = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
  float correctEaseInEaseOutFuncControlPointValues[] = { 
    0.0, 0.0,  0.42, 0.0,  0.58, 1.0,  1.0, 1.0 };
  
  QCGetControlPoints(easeInEaseOutFunc, controlPointValues);
  PASS(QCControlPointValuesAreEqual(
    controlPointValues, correctEaseInEaseOutFuncControlPointValues),
    "ease in ease out function control points are correct");
  //////////////////////////

  CAMediaTimingFunction * easeInFunc = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn];
  float correctEaseInFuncControlPointValues[] = { 
    0.0, 0.0,  0.42, 0.0,  1.0, 1.0,  1.0, 1.0 };

  QCGetControlPoints(easeInFunc, controlPointValues);
  PASS(QCControlPointValuesAreEqual(
    controlPointValues, correctEaseInFuncControlPointValues),
    "ease in function control points are correct");
  //////////////////////////

  CAMediaTimingFunction * easeOutFunc = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
  float correctEaseOutFuncControlPointValues[] = { 
    0.0, 0.0,  0.0, 0.0,  0.58, 1.0,  1.0, 1.0 };

  QCGetControlPoints(easeOutFunc, controlPointValues);
  PASS(QCControlPointValuesAreEqual(
    controlPointValues, correctEaseOutFuncControlPointValues),
    "ease out function control points are correct");
  //////////////////////////

  CAMediaTimingFunction * linearFunc = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
  float correctLinearFuncControlPointValues[] = { 
    0.0, 0.0,  0.0, 0.0,  1.0, 1.0,  1.0, 1.0 };

  QCGetControlPoints(linearFunc, controlPointValues);
  PASS(QCControlPointValuesAreEqual(
    controlPointValues, correctLinearFuncControlPointValues),
    "linear function control points are correct");
  //////////////////////////

  CAMediaTimingFunction * customFunc = [CAMediaTimingFunction functionWithControlPoints: 0.1 : 1.0 : 1.0 : 0.2];
  float correctCustomFuncControlPointValues[] = { 
    0.0, 0.0,  0.1, 1.0,  1.0, 0.2,  1.0, 1.0 };

  QCGetControlPoints(customFunc, controlPointValues);
  PASS(QCControlPointValuesAreEqual(
    controlPointValues, correctCustomFuncControlPointValues),
    "custom function control points are correct");
  //////////////////////////

  float defaultFuncY = [defaultFunc _solveForInput: 0.67];
  float correctDefaultFuncY = 0.926527;
  PASS(QCFloatsAreEqual(defaultFuncY, correctDefaultFuncY), "default function's y value at x=0.67 is correct");
  
  [defaultFunc testGraph];
  //////////////////////////

  float easeInEaseOutFuncY = [easeInEaseOutFunc _solveForInput: 0.67];
  float correctEaseInEaseOutFuncY = 0.772850;
  PASS(QCFloatsAreEqual(easeInEaseOutFuncY, correctEaseInEaseOutFuncY), "ease in ease out function's y value at x=0.67 is correct");

  [easeInEaseOutFunc testGraph];
  //////////////////////////

  float easeInFuncY = [easeInFunc _solveForInput: 0.67];
  float correctEaseInFuncY = 0.515911;
  PASS(QCFloatsAreEqual(easeInFuncY, correctEaseInFuncY), "ease in function's y value at x=0.67 is correct");

  [easeInFunc testGraph];
  //////////////////////////

  float easeOutFuncY = [easeOutFunc _solveForInput: 0.67];
  float correctEaseOutFuncY = 0.846581;
  PASS(QCFloatsAreEqual(easeOutFuncY, correctEaseOutFuncY), "ease out function's y value at x=0.67 is correct");

  [easeOutFunc testGraph];
  //////////////////////////

  float linearFuncY = [linearFunc _solveForInput: 0.67];
  float correctLinearFuncY = 0.669997;
  PASS(QCFloatsAreEqual(linearFuncY, correctLinearFuncY), "linear function's y value at x=0.67 is correct");

  [linearFunc testGraph];
  //////////////////////////

  float customFuncY = [customFunc _solveForInput: 0.67];
  float correctCustomFuncY = 0.589449;
  PASS(QCFloatsAreEqual(customFuncY, correctCustomFuncY), "custom function's y value at x=0.67 is correct");
  printf("%f\n", customFuncY);
  [customFunc testGraph];

  if(testsFailed)
    {
      printf("\7");
    }
  printf("\n\n===== %d tests failed\n\n", testsFailed);

  return testsFailed;
}

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
