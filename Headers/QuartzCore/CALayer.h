/* CALayer.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: June 2012

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

#import "QuartzCore/CABase.h"
#import "QuartzCore/CAMediaTiming.h"
#import "QuartzCore/CATransform3D.h"
#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

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
NSString *const kCATransition;

@class CAAnimation;

#import "QuartzCore/CAAction.h"

#if GNUSTEP
#define NONATOMIC_GSONLY nonatomic
#else
#define NONATOMIC_GSONLY atomic
#endif

@class CABackingStore;
@class CAGLSimpleFramebuffer;

@interface CALayer : NSObject<CAMediaTiming>
{
  /* property-backing i-vars */
  id _delegate;
  id _contents;
  id _layoutManager;
  CALayer * _superlayer;
  NSArray * _sublayers;
  CGRect _frame;
  CGRect _bounds;
  CGPoint _anchorPoint;
  CGPoint _position;
  CATransform3D _transform;
  CATransform3D _sublayerTransform;
  float _opacity;
  BOOL _shouldRasterize;
  BOOL _opaque;
  BOOL _geometryFlipped;
  CGColorRef _backgroundColor;
  BOOL _masksToBounds;
  CGRect _contentsRect;
  BOOL _hidden;
  NSString * _contentsGravity;
  BOOL _needsDisplayOnBoundsChange;
  CGFloat _zPosition;
  NSDictionary *_actions;
  NSDictionary *_style;
  id _presentationLayer;
  id _modelLayer;
  
  CGColorRef _shadowColor;
  CGSize _shadowOffset;
  float _shadowOpacity;
  CGPathRef _shadowPath;
  CGFloat _shadowRadius;
  
  /* media timing i-vars */
  CFTimeInterval _beginTime;
  CFTimeInterval _timeOffset;
  float _repeatCount;
  float _repeatDuration;
  BOOL _autoreverses;
  NSString* _fillMode;
  CFTimeInterval _duration;
  float _speed;
  
  /* i-vars */
  BOOL _needsDisplay;
  BOOL _needsLayout;
  NSMutableDictionary *_animations;
  NSMutableArray *_animationKeys;
  NSMutableArray *_observedKeyPaths;
  CABackingStore * _backingStore;
  
  /* TODO: add CAGLSimpleFramebuffer ivars for storing:
     - offscreen rendering framebuffer
     - shadow framebuffer
     - ...more?
     Creating framebuffers is more expensive than reusing them.
     */
}

+ (id) layer;
+ (id) defaultValueForKey: (NSString *)key;
+ (id<CAAction>) defaultActionForKey: (NSString *)key;

@property (assign)                   id delegate;
@property (retain)                   id contents;
@property (retain)                   id layoutManager;
@property (nonatomic,readonly)       CALayer *superlayer;
@property (nonatomic,copy)           NSArray *sublayers;
@property (assign)                   CGRect frame;
@property (nonatomic,assign)         CGRect bounds;
@property (NONATOMIC_GSONLY,assign)  CGPoint anchorPoint;
@property (NONATOMIC_GSONLY,assign)  CGPoint position;
@property (NONATOMIC_GSONLY,assign)  CATransform3D transform;
@property (NONATOMIC_GSONLY,assign)  CATransform3D sublayerTransform;
@property (assign)                   float opacity;
@property (assign,getter=isOpaque)   BOOL opaque;
@property (assign)                   BOOL shouldRasterize;

@property (nonatomic, assign)        CGColorRef shadowColor; /* retained by CG */
@property (NONATOMIC_GSONLY,assign)  CGSize shadowOffset;
@property (assign)                   float shadowOpacity;
@property (nonatomic, assign)        CGPathRef shadowPath; /* retained by CG; not supported yet; TODO: should not be implicitly animatable */
@property (assign)                   CGFloat shadowRadius;

@property (assign,getter=isGeometryFlipped) BOOL geometryFlipped; /* not supported yet */
@property (nonatomic, assign)        CGColorRef backgroundColor; /* retained by CG */
@property (assign)                   BOOL masksToBounds;
@property (assign)                   CGRect contentsRect;
@property (assign,getter=isHidden)   BOOL hidden;
@property (copy)                     NSString *contentsGravity;
@property (assign)                   BOOL needsDisplayOnBoundsChange;
@property (assign)                   CGFloat zPosition;
@property (copy)                     NSDictionary *actions;
/* TODO: Style property is unimplemented */
@property (copy)                     NSDictionary *style;
@property (retain, readonly)         NSArray *animationKeys;

- (id) init;
- (id) initWithLayer: (CALayer *)layer;

- (id<CAAction>) actionForKey: (NSString*)key;

- (void) addAnimation: (CAAnimation *)anim forKey: (NSString *)key;
- (void) removeAnimationForKey: (NSString *)key;
- (CAAnimation *) animationForKey:( NSString *)key;

- (void) addSublayer: (CALayer *)layer;
- (void) removeFromSuperlayer;
- (void) insertSublayer: (CALayer *)layer atIndex: (unsigned)index;
- (void) insertSublayer: (CALayer *)layer below: (CALayer *)sibling;
- (void) insertSublayer: (CALayer *)layer above: (CALayer *)sibling;

- (CGPoint) convertPoint: (CGPoint)pt fromLayer: (CALayer *)layer;
- (CGPoint) convertPoint: (CGPoint)pt toLayer: (CALayer *)layer;
- (CGRect) convertRect: (CGRect)rect fromLayer: (CALayer *)layer;
- (CGRect) convertRect: (CGRect)rect toLayer: (CALayer *)layer;
- (CFTimeInterval) convertTime: (CFTimeInterval)theTime fromLayer: (CALayer *)layer;
- (CFTimeInterval) convertTime: (CFTimeInterval)theTime toLayer: (CALayer *)layer;

- (void) display;
- (void) displayIfNeeded;
- (BOOL) needsDisplay;
- (void) setNeedsDisplay;
- (void) setNeedsDisplayInRect: (CGRect)r;
- (BOOL) needsLayout;
- (void) setNeedsLayout;
- (void) layoutIfNeeded;

- (id) presentationLayer;
- (id) modelLayer;

- (CGAffineTransform) affineTransform;
- (void) setAffineTransform: (CGAffineTransform)affineTransform;

@end

@interface NSObject (CALayerActions)
- (void) displayLayer: (CALayer*)layer;
- (void) drawLayer: (CALayer*)layer inContext: (CGContextRef)context;
- (id<CAAction>) actionForLayer: (CALayer*)layer forKey: (NSString*)eventKey;
@end

@interface NSObject (CALayerLayoutManager)
- (void) layoutSublayersOfLayer: (CALayer*)layer;
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
