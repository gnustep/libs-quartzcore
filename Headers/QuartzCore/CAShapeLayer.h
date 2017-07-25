/* CAShapeLayer.h

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

#import <QuartzCore/CALayer.h>
#import <CoreGraphics/CoreGraphics.h>

@interface CAShapeLayer : CALayer {
  CGPathRef _path;
  CGColorRef _fillColor;
  NSString *_fillRule;
  CGColorRef _strokeColor;
  CGFloat _strokeStart;
  CGFloat _strokeEnd;
  CGFloat _lineWidth;
  CGFloat _miterLimit;
  NSString *_lineCap;
  NSString *_lineJoin;
  CGFloat _lineDashPhase;
  NSArray *_lineDashPattern;
}

@property CGPathRef path;
@property CGColorRef fillColor;
@property(copy) NSString *fillRule;
@property CGColorRef strokeColor;
@property CGFloat strokeStart;
@property CGFloat strokeEnd;
@property CGFloat lineWidth;
@property CGFloat miterLimit;
@property(copy) NSString *lineCap;
@property(copy) NSString *lineJoin;
@property CGFloat lineDashPhase;
@property(copy) NSArray *lineDashPattern;
@end

extern NSString *const kCAFillRuleNonZero;
extern NSString *const kCAFillRuleEvenOdd;

extern NSString *const kCALineJoinMiter;
extern NSString *const kCALineJoinRound;
extern NSString *const kCALineJoinBevel;

extern NSString *const kCALineCapButt;
extern NSString *const kCALineCapRound;
extern NSString *const kCALineCapSquare;
