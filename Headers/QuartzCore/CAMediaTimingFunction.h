/* CAMediaTimingFunction.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: July 2012
   
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

#import <Foundation/NSObject.h> 

extern NSString *const kCAMediaTimingFunctionDefault;
extern NSString *const kCAMediaTimingFunctionEaseInEaseOut;
extern NSString *const kCAMediaTimingFunctionEaseIn;
extern NSString *const kCAMediaTimingFunctionEaseOut;
extern NSString *const kCAMediaTimingFunctionLinear;

@interface CAMediaTimingFunction : NSObject
{
  float _c1x, _c1y;
  float _c2x, _c2y;
  
  CGFloat _coefficientsX[4];
  CGFloat _coefficientsY[4];
}

+ (id) functionWithName:(NSString *)name;
+ (id) functionWithControlPoints: (float)c1x
                                : (float)c1y
                                : (float)c2x
                                : (float)c2y;
- (id) initWithControlPoints: (float)c1x
                            : (float)c1y
                            : (float)c2x
                            : (float)c2y;
- (void)getControlPointAtIndex: (size_t)index values: (float*)ptr;
@end
/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */

