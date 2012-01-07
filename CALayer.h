
/* 
   CALayer.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>
   Date: December, 2011

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

#import "CABase.h"

NSString *const kCAGravityResize;
NSString *const kCAGravityResizeAspect;
NSString *const kCAGravityResizeAspectFill;
NSString *const kCAGravityCenter;
NSString *const kCAGravityTop;
NSString *const kCAGravityBottom;
NSString *const kCAGravityLeft;
NSString *const kCAGravityRight;
NSString *const kCAGravityTopLeft;
NSString *const kCAGravityTopRight;
NSString *const kCAGravityBottomLeft;
NSString *const kCAGravityBottomRight;

@class CAAnimation;

@interface CALayer : NSObject
{
}

+ (id)layer;

@property (assign) id delegate;
@property (retain) id contents;
@property (retain) NSLayoutManager* layoutManager;
@property (copy) NSArray* sublayers;
@property CGRect frame;
@property CGRect bounds;
@property CGPoint position;
@property float opacity;
@property (getter=isOpaque) BOOL opaque;
@property (getter=isGeometryFlipped) BOOL geometryFlipped;
@property (assign) CGColorRef backgroundColor;
@property BOOL masksToBounds;
@property CGRect contentsRect;
@property (getter=isHidden) BOOL hidden;
@property (copy) NSString* contentsGravity;
@property BOOL needsDisplayOnBoundsChange;
@property CGFloat zPosition;

- (void)addAnimation:(CAAnimation *)anim forKey:(NSString *)key;
- (void)removeAnimationForKey:(NSString *)key;
- (CAAnimation *)animationForKey:(NSString *)key;
- (CGAffineTransform)affineTransform;
- (void)setAffineTransform:(CGAffineTransform)m;
- (void)addSublayer:(CALayer *)layer;
- (CGPoint)convertPoint:(CGPoint)p toLayer:(CALayer *)l;
- (void)removeFromSuperlayer;
- (void)insertSublayer:(CALayer *)layer atIndex:(unsigned)index;
- (void)insertSublayer:(CALayer *)layer below:(CALayer *)sibling;
- (void)insertSublayer:(CALayer *)layer above:(CALayer *)sibling;
- (void)setNeedsDisplay;
- (void)setNeedsDisplayInRect:(CGRect)r;
- (void)setNeedsLayout;
- (void)layoutIfNeeded;

@end
