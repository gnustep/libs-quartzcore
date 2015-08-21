/* Tests/CALayer/calayer.m

   Copyright (C) 2015 Free Software Foundation, Inc.

   Author: Filip Zelic <zelic.filip@gmail.com>
   Date: July 2015

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

#import "QuartzCore/CALayer.h"
#import "../Testing.h"

@interface CALayerTestSubclass : CALayer
@property (nonatomic,
           retain,
           getter=manualTempDynamicPropertyTestGetter,
           setter=setDynamicPropertyDifferentName:) NSString *dynamicPropertyObject;
@property (retain) NSString *dynamicPropertyStringObject;
@property (assign) float dynamicPropertyFloat;
@property (assign) BOOL dynamicPropertyBool;
@property (assign) char dynamicPropertyChar;
@property (assign) double dynamicPropertyDouble;
@end
@implementation CALayerTestSubclass
@dynamic dynamicPropertyObject;
@dynamic dynamicPropertyStringObject;
@dynamic dynamicPropertyFloat;
@dynamic dynamicPropertyBool;
@dynamic dynamicPropertyChar;
@dynamic dynamicPropertyDouble;
@end

int main(int argc, char ** argv)
{
  int testsFailed = 0;
  CALayerTestSubclass *testLayer = [CALayerTestSubclass layer];
  //////////////////////////

  NSString *expectedString = @"Testing object.";
  [testLayer setDynamicPropertyStringObject: @"Testing object."];
  PASS([testLayer dynamicPropertyStringObject] == expectedString,
    "Setter and getter for dynamic property object are working");

  //////////////////////////

  NSString *expectedStringObject = @"Testing custom getter and setter.";
  /* TODO: Calling [GSKVOCALayerTestSubclass -setDynamicPropertyStringObject:] with incorrect signature.  
            Method has v@:@"NSString", selector has v24@0:8@16 */
  [testLayer setDynamicPropertyStringObject: @"Testing custom getter and setter."];
  /* TODO: Calling [GSKVOCALayerTestSubclass -dynamicPropertyStringObject] with incorrect signature.  
            Method has @"NSString"@:, selector has @16@0:8 */
  PASS([testLayer dynamicPropertyStringObject] == expectedStringObject,
    "Custom setter and getter for dynamic properties are working");

  //////////////////////////

  float expectedFloatNumber = 20.0;
  [testLayer setDynamicPropertyFloat: 20.0];

  PASS([testLayer dynamicPropertyFloat] == expectedFloatNumber,
    "Setter and getter for dynamic property float are working");

  //////////////////////////

  double expectedDoubleNumber = 3.141592653589793238;
  [testLayer setDynamicPropertyDouble: 3.141592653589793238];

  PASS([testLayer dynamicPropertyDouble] == expectedDoubleNumber,
    "Setter and getter for dynamic property double are working");
  //////////////////////////

  BOOL expectedBoolValue = YES;
  [testLayer setDynamicPropertyBool: YES];

  PASS([testLayer dynamicPropertyBool] == expectedBoolValue,
    "Setter and getter for dynamic property bool are working");

  //////////////////////////

  if(testsFailed)
    {
      printf("\7");
    }
  printf("\n\n===== %d tests failed\n\n", testsFailed);

  return testsFailed;
}