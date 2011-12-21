
/* 
   CALayer.h

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

#import <AppKit/AppKit.h>

extern NSString* const kCAGravityResize;
extern NSString* const kCAGravityResizeAspect;
extern NSString* const kCAGravityResizeAspectFill;
extern NSString* const kCAGravityCenter;
extern NSString* const kCAGravityTop;
extern NSString* const kCAGravityBottom;
extern NSString* const kCAGravityLeft;
extern NSString* const kCAGravityRight;
extern NSString* const kCAGravityTopLeft;
extern NSString* const kCAGravityTopRight;
extern NSString* const kCAGravityBottomLeft;
extern NSString* const kCAGravityBottomRight;

@interface CALayer : NSObject
{
}

@property (assign) id delegate;
@property NSLayoutManager* layoutManager;
@property (copy) NSArray* sublayers;
@property CGRect frame;
@property CGRect bounds;
@property CGPoint position;
@property float opacity;
@property (getter=isOpaque) BOOL opaque;
@property CGColorRef backgroundColor;
@property BOOL masksToBounds;
@property CGRect contentsRect;
@property (getter=isHidden) BOOL hidden;
@property (copy) NSString* contentsGravity;
@property BOOL needsDisplayOnBoundsChange;
@property CGFloat zPosition;

- (CGAffineTransform)affineTransform;
- (void)setAffineTransform:(CGAffineTransform)m;
- (void)addSublayer:(CALayer *)layer;
- (CGPoint)convertPoint:(CGPoint)p toLayer:(CALayer *)l;

@end
