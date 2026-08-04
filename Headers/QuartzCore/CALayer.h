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

extern NSString *const kCAGravityResize;
extern NSString *const kCAGravityResizeAspect;
extern NSString *const kCAGravityResizeAspectFill;
extern NSString *const kCAGravityCenter;
extern NSString *const kCAGravityTop;
extern NSString *const kCAGravityBottom;
extern NSString *const kCAGravityLeft;
extern NSString *const kCAGravityRight;
extern NSString *const kCAGravityTopLeft;
extern NSString *const kCAGravityTopRight;
extern NSString *const kCAGravityBottomLeft;
extern NSString *const kCAGravityBottomRight;

/* action keys */
extern NSString *const kCAOnOrderIn;
extern NSString *const kCAOnOrderOut;
extern NSString *const kCATransition;

/* the edges of a layer, for -edgeAntialiasingMask */
enum
{
  kCALayerLeftEdge = 1U << 0,
  kCALayerRightEdge = 1U << 1,
  kCALayerBottomEdge = 1U << 2,
  kCALayerTopEdge = 1U << 3
};
typedef unsigned int CAEdgeAntialiasingMask;

/* which parts of a layer give way when its superlayer is resized */
enum
{
  kCALayerNotSizable = 0,
  kCALayerMinXMargin = 1U << 0,
  kCALayerWidthSizable = 1U << 1,
  kCALayerMaxXMargin = 1U << 2,
  kCALayerMinYMargin = 1U << 3,
  kCALayerHeightSizable = 1U << 4,
  kCALayerMaxYMargin = 1U << 5
};
typedef unsigned int CAAutoresizingMask;

/* which corners -cornerRadius rounds */
enum
{
  kCALayerMinXMinYCorner = 1U << 0,
  kCALayerMaxXMinYCorner = 1U << 1,
  kCALayerMinXMaxYCorner = 1U << 2,
  kCALayerMaxXMaxYCorner = 1U << 3
};
typedef unsigned int CACornerMask;

/* the shape a rounded corner is drawn with */
extern NSString *const kCACornerCurveCircular;
extern NSString *const kCACornerCurveContinuous;

/* the pixel format a layer asks for its contents */
extern NSString *const kCAContentsFormatAutomatic;
extern NSString *const kCAContentsFormatRGBA8Uint;
extern NSString *const kCAContentsFormatRGBA16Float;
extern NSString *const kCAContentsFormatGray8Uint;

/* the range of brightness a layer asks for */
extern NSString *const CADynamicRangeStandard;
extern NSString *const CADynamicRangeConstrainedHigh;
extern NSString *const CADynamicRangeHigh;

/* when a layer's contents are tone mapped */
extern NSString *const CAToneMapModeAutomatic;
extern NSString *const CAToneMapModeNever;
extern NSString *const CAToneMapModeIfSupported;

@class CAAnimation;
@class CARenderer;

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
  CARenderer * _renderer;
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
  NSMutableDictionary *_dynamicPropertyValueDict;
  id _presentationLayer;
  id _modelLayer;
  CGColorRef _borderColor;
  CGFloat _contentsScale;

  CALayer * _mask;
  NSArray * _filters;
  NSArray * _backgroundFilters;
  id _compositingFilter;
  CGRect _contentsCenter;
  CAEdgeAntialiasingMask _edgeAntialiasingMask;
  CAAutoresizingMask _autoresizingMask;
  CACornerMask _maskedCorners;
  NSString * _cornerCurve;
  NSString * _contentsFormat;
  NSString * _preferredDynamicRange;
  NSString * _toneMapMode;
  CGFloat _contentsHeadroom;
  BOOL _wantsExtendedDynamicRangeContent;
  BOOL _wantsDynamicContentScaling;
  float _minificationFilterBias;
  BOOL _allowsEdgeAntialiasing;
  BOOL _allowsGroupOpacity;
  BOOL _drawsAsynchronously;

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
  NSMutableArray *_archivingKeyPaths;
  NSMutableSet *_valuesThatWereSet;
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
@property (NONATOMIC_GSONLY,assign)  CGRect contentsRect;
@property (assign,getter=isHidden)   BOOL hidden;
@property (copy)                     NSString *contentsGravity;
@property (assign)                   BOOL needsDisplayOnBoundsChange;
@property (assign)                   CGFloat zPosition;
@property (copy)                     NSDictionary *actions;
/* TODO: Style property is unimplemented */
@property (copy)                     NSDictionary *style;
#if __clang__
@property (retain, readonly)         NSArray *animationKeys;
#else
#warning GCC workaround: CALayer.animationKeys publicly defined as NSMutableArray although it should not be.
@property (retain, readonly)         NSMutableArray *animationKeys;
#endif

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
- (void) drawInContext: (CGContextRef)context;
- (void) renderInContext: (CGContextRef)context;
- (BOOL) needsLayout;
- (void) setNeedsLayout;
- (void) layoutIfNeeded;

- (id) presentationLayer;
- (id) modelLayer;

- (CGAffineTransform) affineTransform;
- (void) setAffineTransform: (CGAffineTransform)affineTransform;

- (BOOL) contentsAreFlipped;
- (BOOL) shouldArchiveValueForKey: (NSString *)key;

- (void) resizeWithOldSuperlayerSize: (CGSize)size;
- (void) resizeSublayersWithOldSize: (CGSize)size;

@property (nonatomic, assign) CGColorRef borderColor; /* retained by CG */
@property (nonatomic, assign) CGFloat contentsScale;
@property (nonatomic, assign) CGFloat anchorPointZ;

/* The renderer does not read any of the following yet. */
@property (retain)                   CALayer *mask;
@property (copy)                     NSArray *filters;
@property (retain)                   id compositingFilter;
@property (copy)                     NSArray *backgroundFilters;
@property (NONATOMIC_GSONLY,assign)  CGRect contentsCenter;
@property (assign)                   CAEdgeAntialiasingMask edgeAntialiasingMask;
@property (assign)                   float minificationFilterBias;
@property (assign)                   BOOL allowsEdgeAntialiasing;
@property (assign)                   BOOL allowsGroupOpacity;
@property (assign)                   BOOL drawsAsynchronously;
@property (assign)                   CAAutoresizingMask autoresizingMask;

/* Nothing reads any of the following yet: this framework rounds no corners,
   chooses no pixel format for its backing store, and has no notion of a
   display brighter than white. */
@property (assign)                   CACornerMask maskedCorners;
@property (copy)                     NSString *cornerCurve;
@property (copy)                     NSString *contentsFormat;
@property (copy)                     NSString *preferredDynamicRange;
@property (copy)                     NSString *toneMapMode;
@property (assign)                   CGFloat contentsHeadroom;
@property (assign)                   BOOL wantsExtendedDynamicRangeContent;
@property (assign)                   BOOL wantsDynamicContentScaling;

+ (CGFloat) cornerCurveExpansionFactor: (NSString *)curve;
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
