/* CAScrollLayer.h

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

@interface CAScrollLayer : CALayer
{
  NSString *_scrollMode;
}

/* Which way this layer will scroll: one of the four names below. */
@property (copy) NSString *scrollMode;

/* Moves the origin of the bounds to the given point, as far as the scroll
   mode allows. */
- (void) scrollToPoint: (CGPoint)p;

/* Scrolls the least amount that brings the rectangle into view. */
- (void) scrollToRect: (CGRect)r;

@end

extern NSString *const kCAScrollNone;
extern NSString *const kCAScrollVertically;
extern NSString *const kCAScrollHorizontally;
extern NSString *const kCAScrollBoth;
