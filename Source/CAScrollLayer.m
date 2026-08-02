/* CAScrollLayer.m

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
#import "QuartzCore/CAScrollLayer.h"

NSString *const kCAScrollNone = @"none";
NSString *const kCAScrollVertically = @"vertically";
NSString *const kCAScrollHorizontally = @"horizontally";
NSString *const kCAScrollBoth = @"both";

@implementation CAScrollLayer

@synthesize scrollMode = _scrollMode;

- (id) init
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  _scrollMode = [kCAScrollBoth copy];

  return self;
}

- (void) dealloc
{
  [_scrollMode release];

  [super dealloc];
}

- (void) scrollToPoint: (CGPoint)p
{
  CGRect bounds = [self bounds];
  BOOL horizontally = [_scrollMode isEqualToString: kCAScrollHorizontally]
                        || [_scrollMode isEqualToString: kCAScrollBoth];
  BOOL vertically = [_scrollMode isEqualToString: kCAScrollVertically]
                      || [_scrollMode isEqualToString: kCAScrollBoth];

  if (horizontally)
    {
      bounds.origin.x = p.x;
    }
  if (vertically)
    {
      bounds.origin.y = p.y;
    }

  [self setBounds: bounds];
}

- (void) scrollToRect: (CGRect)r
{
  CGRect bounds = [self bounds];
  CGPoint p = bounds.origin;

  /* Move only as far as it takes to bring each edge inside. */
  if (CGRectGetMaxX(r) > CGRectGetMaxX(bounds))
    {
      p.x = CGRectGetMaxX(r) - bounds.size.width;
    }
  if (CGRectGetMinX(r) < p.x)
    {
      p.x = CGRectGetMinX(r);
    }

  if (CGRectGetMaxY(r) > CGRectGetMaxY(bounds))
    {
      p.y = CGRectGetMaxY(r) - bounds.size.height;
    }
  if (CGRectGetMinY(r) < p.y)
    {
      p.y = CGRectGetMinY(r);
    }

  [self scrollToPoint: p];
}

@end
