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

@interface CALayer (CALayerScrolling)

/* The part of the layer inside the visible area of the nearest CAScrollLayer
   above it, in the layer's own coordinates.  A layer with no such ancestor
   is visible throughout, so this is its bounds. */
@property (readonly) CGRect visibleRect;

/* Scrolls the nearest CAScrollLayer above the layer so that the point sits
   at the origin of the visible area. */
- (void) scrollPoint: (CGPoint)p;

/* Scrolls it the least amount that brings the rectangle into view. */
- (void) scrollRectToVisible: (CGRect)r;

@end
