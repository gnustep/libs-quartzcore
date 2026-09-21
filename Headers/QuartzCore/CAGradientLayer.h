/* CAGradientLayer.h

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

@interface CAGradientLayer : CALayer
{
  NSArray *_colors;
  NSArray *_locations;
  CGPoint _startPoint;
  CGPoint _endPoint;
  NSString *_type;
}

/* An array of CGColorRef, drawn in order along the gradient. */
@property (copy)   NSArray *colors;

/* Where each colour sits along the gradient, as numbers between 0 and 1.
   Nil spreads the colours evenly. */
@property (copy)   NSArray *locations;

@property (assign) CGPoint startPoint;
@property (assign) CGPoint endPoint;
@property (copy)   NSString *type;

@end

extern NSString *const kCAGradientLayerAxial;
extern NSString *const kCAGradientLayerRadial;
extern NSString *const kCAGradientLayerConic;
