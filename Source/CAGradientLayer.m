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

/* TODO: draw the gradient.  The properties above are held and read back,
   but nothing fills the backing store, so a gradient layer draws as a plain
   layer does.  The colours and the locations map onto a CGGradient drawn
   between startPoint and endPoint. */

@end
