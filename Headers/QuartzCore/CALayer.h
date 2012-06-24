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
@class NSLayoutManager;
typedef struct _cairo_surface cairo_surface_t;

@protocol CAAction
@required
- (void)runActionForKey:(NSString *)key object:(id)anObject arguments:(NSDictionary *)dict;
@end

#if !(GSIMPL_UNDER_COCOA)
/* This needs to become a public interface of Opal! */
CGContextRef opal_new_CGContext(cairo_surface_t *target, CGSize device_size);
#endif

@interface CALayer : NSObject<CAMediaTiming>
{
  /* property-backing i-vars */
  id _delegate;
  id _contents;
  NSLayoutManager * _layoutManager;
  CALayer * _superlayer;
  NSArray * _sublayers;
  CGRect _frame;
  CGRect _bounds;
  CGPoint _anchorPoint;
  CGPoint _position;
  CATransform3D _transform;
  float _opacity;
  BOOL _opaque;
  BOOL _geometryFlipped;
  CGColorRef _backgroundColor;
  BOOL _masksToBounds;
  CGRect _contentsRect;
  BOOL _hidden;
  NSString * _contentsGravity;
  BOOL _needsDisplayOnBoundsChange;
  CGFloat _zPosition;
  id _presentationLayer;
  id _modelLayer;

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
  CGContextRef _opalContext;
#if !(GSIMPL_UNDER_COCOA)
  cairo_surface_t * _cairoSurface;
#endif
  BOOL _needsDisplay;
  BOOL _needsLayout;
  NSMutableDictionary *_animations;
}

+ (id) layer;
+ (id) defaultValueForKey: (NSString *)key;
+ (id<CAAction>) defaultActionForKey: (NSString *)key;

@property (assign)                   id delegate;
@property (retain)                   id contents;
@property (retain)                   NSLayoutManager *layoutManager;
@property (nonatomic,readonly)       CALayer *superlayer;
@property (nonatomic,copy)           NSArray *sublayers;
@property (assign)                   CGRect frame;
@property (nonatomic,assign)         CGRect bounds;
@property (assign)                   CGPoint anchorPoint;
@property (assign)                   CGPoint position;
@property (assign)                   CATransform3D transform;
@property (assign)                   float opacity;
@property (getter=isOpaque)          BOOL opaque;
@property (getter=isGeometryFlipped) BOOL geometryFlipped;
@property /* retained */ (nonatomic) CGColorRef backgroundColor;
@property (assign)                   BOOL masksToBounds;
@property (assign)                   CGRect contentsRect;
@property (getter=isHidden)          BOOL hidden;
@property (copy)                     NSString *contentsGravity;
@property (assign)                   BOOL needsDisplayOnBoundsChange;
@property (assign)                   CGFloat zPosition;

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

- (NSArray *) animationKeys;

@end

@interface CALayer (FrameworkPrivate)
/* Don't use these framework-private methods.
 * They may get removed at any time.
 */

/* sets value passed into -[CARenderer beginFrameAtTime:...]
   used as "time of object superior to root layer" (that is,
   CARenderer) */
+ (void) setCurrentFrameBeginTime: (CFTimeInterval)frameTime;
- (CALayer *) rootLayer;
- (NSArray *) allAncestorLayers;
- (CALayer *) nextAncestorOf: (CALayer *)layer;

- (void) discardPresentationLayer;
- (void) applyAnimationsAtTime: (CFTimeInterval)time;

- (CFTimeInterval) activeTime;
- (CFTimeInterval) localTime;
@end

@interface NSObject (CALayer)
- (void) displayLayer: (CALayer*)layer;
- (void) drawLayer: (CALayer*)layer inContext: (CGContextRef)context;
- (void) layoutSublayersOfLayer: (CALayer*)layer;
- (id<CAAction>) actionForLayer: (CALayer*)layer forKey: (NSString*)eventKey;
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
