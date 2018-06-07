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

NSString *const kCAFillRuleNonZero = @"kCAFillRuleNonZero";
NSString *const kCAFillRuleEvenOdd = @"kCAFillRuleEvenOdd";
                                    
NSString *const kCALineJoinMiter = @"kCALineJoinMiter";
NSString *const kCALineJoinRound = @"kCALineJoinRound";
NSString *const kCALineJoinBevel = @"kCALineJoinBevel";
                                    
NSString *const kCALineCapButt = @"kCALineCapButt";
NSString *const kCALineCapRound = @"kCALineCapRound";
NSString *const kCALineCapSquare = @"kCALineCapSquare";

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
@end
