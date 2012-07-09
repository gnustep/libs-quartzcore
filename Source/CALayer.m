/* CALayer.m

   Copyright (C) 2012 Free Software Foundation, Inc.
   
   Author: Ivan Vučica <ivan@vucica.net>
   Date: June 2012

   Author: Amr Aboelela <amraboelela@gmail.com>
   Date: December 2011

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
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CALayer.h"
#import "CABackingStore.h"
#import "CALayer+FrameworkPrivate.h"
#import "CAAnimation+FrameworkPrivate.h"
#import "CAImplicitAnimationObserver.h"

#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif
#import <stdlib.h>

static CFTimeInterval currentFrameBeginTime = 0;

NSString *const kCAGravityResize = @"CAGravityResize";
NSString *const kCAGravityResizeAspect = @"CAGravityResizeAspect";
NSString *const kCAGravityResizeAspectFill = @"CAGravityResizeAspectFill";
NSString *const kCAGravityCenter = @"CAGravityCenter";
NSString *const kCAGravityTop = @"CAGravityTop";
NSString *const kCAGravityBottom = @"CAGravityBottom";
NSString *const kCAGravityLeft = @"CAGravityLeft";
NSString *const kCAGravityRight = @"CAGravityRight";
NSString *const kCAGravityTopLeft = @"CAGravityTopLeft";
NSString *const kCAGravityTopRight = @"CAGravityTopRight";
NSString *const kCAGravityBottomLeft = @"CAGravityBottomLeft";
NSString *const kCAGravityBottomRight = @"CAGravityBottomRight";

static CGContextRef createCGBitmapContext (int pixelsWide,
                                    int pixelsHigh)
{
  CGContextRef    context = NULL;
  CGColorSpaceRef colorSpace;
  void *          bitmapData;
  int             bitmapByteCount;
  int             bitmapBytesPerRow;
  
  bitmapBytesPerRow   = (pixelsWide * 4);
  bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
  
  colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);// 2

  // Let CGBitmapContextCreate() allocate the memory.
  // This should be good under Cocoa too.
  bitmapData = NULL;

  context = CGBitmapContextCreate (bitmapData,
                                   pixelsWide,
                                   pixelsHigh,
                                   8,      // bits per component
                                   bitmapBytesPerRow,
                                   colorSpace,
#if !GNUSTEP
                                   kCGImageAlphaPremultipliedLast);
#else
  // Opal only supports kCGImageAlphaPremultipliedFirst.
  // However, this is incorrect since it implies ARGB.
                                  kCGImageAlphaPremultipliedFirst);
#endif

  // Note: our use of premultiplied alpha means that we need to
  // do alpha blending using:
  //  GL_SRC_ALPHA, GL_ONE

  if (context== NULL)
    {
      free (bitmapData);// 5
      fprintf (stderr, "Context not created!");
      return NULL;
    }
  CGColorSpaceRelease(colorSpace);
  
  return context;
}


@interface CALayer()
@property (nonatomic, assign) CALayer *superlayer;
@property (nonatomic, retain) NSMutableDictionary *animations;

- (void)setModelLayer: (id)modelLayer;
@end

@implementation CALayer

@synthesize delegate=_delegate;
@synthesize contents=_contents;
@synthesize layoutManager=_layoutManager;
@synthesize superlayer=_superlayer;
@synthesize sublayers=_sublayers;
@synthesize frame=_frame;
@synthesize bounds=_bounds;
@synthesize anchorPoint=_anchorPoint;
@synthesize position=_position;
@synthesize opacity=_opacity;
@synthesize transform=_transform;
@synthesize sublayerTransform=_sublayerTransform;
@synthesize opaque=_opaque;
@synthesize geometryFlipped=_geometryFlipped;
@synthesize backgroundColor=_backgroundColor;
@synthesize masksToBounds=_masksToBounds;
@synthesize contentsRect=_contentsRect;
@synthesize hidden=_hidden;
@synthesize contentsGravity=_contentsGravity;
@synthesize needsDisplayOnBoundsChange=_needsDisplayOnBoundsChange;
@synthesize zPosition=_zPosition;

/* properties in protocol CAMediaTiming */
@synthesize beginTime=_beginTime;
@synthesize timeOffset=_timeOffset;
@synthesize repeatCount=_repeatCount;
@synthesize repeatDuration=_repeatDuration;
@synthesize autoreverses=_autoreverses;
@synthesize fillMode=_fillMode;
@synthesize duration=_duration;
@synthesize speed=_speed;

/* private properties */
@synthesize animations=_animations;

/* *** class methods *** */
+ (id) layer
{
  return [[self new] autorelease];
}

+ (id) defaultValueForKey: (NSString *)key
{
  if ([key isEqualToString:@"delegate"])
    {
      return nil;
    }
  if ([key isEqualToString: @"anchorPoint"])
    {
      CGPoint pt = CGPointMake(0.5, 0.5);
      return [NSValue valueWithBytes: &pt objCType: @encode(CGPoint)];
    }
  if ([key isEqualToString: @"transform"])
    {
      return [NSValue valueWithCATransform3D: CATransform3DIdentity];
    }
  if ([key isEqualToString: @"sublayerTransform"])
    {
      return [NSValue valueWithCATransform3D: CATransform3DIdentity];
    }
  if ([key isEqualToString:@"opacity"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
    
  /* CAMediaTiming */
  if ([key isEqualToString:@"duration"])
    {
      return [NSNumber numberWithFloat: __builtin_inf()];
      /* FIXME: is there a cleaner way to get inf apart from "1./0"? */
    }
  if ([key isEqualToString:@"speed"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString:@"autoreverses"])
    {
      return [NSNumber numberWithBool: NO];
    }
  if ([key isEqualToString:@"repeatCount"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString: @"beginTime"])
    {
      return [NSNumber numberWithFloat: 0.0];
    }

  return nil;
}
/* *** methods *** */
- (id) init
{
  if ((self = [super init]) != nil)
    {
      _animations = [[NSMutableDictionary alloc] init];
      _sublayers = [[NSMutableArray alloc] init];
      _observedKeyPaths = [[NSMutableArray alloc] init];

      /* TODO: list all properties below */
      static NSString * keys[] = {
        @"anchorPoint", @"transform", @"sublayerTransform",
        @"opacity", @"delegate", 
        
        @"beginTime", @"duration", @"speed", @"autoreverses",
        @"repeatCount",
        
        @"bounds", @"position" };
      
      for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
        {
          id defaultValue = [[self class] defaultValueForKey: keys[i]];
          if (defaultValue)
            {
              [self setValue: defaultValue
                      forKey: keys[i]];
            }

          /* implicit animations support */
          /* TODO: only animatable properties should be observed */
          /* TODO: @dynamically created properties also need to be
              set up and observed. */
          [self addObserver: [CAImplicitAnimationObserver sharedObserver]
                 forKeyPath: keys[i]
                    options: NSKeyValueObservingOptionOld
                    context: nil];
          [_observedKeyPaths addObject: keys[i]];
        }

    }
  return self;
}

- (id) initWithLayer: (CALayer*)layer
{
  /* Used when creating shadow copies of 'layer', e.g. when creating 
     presentation layer. Not to be used by app developer for copying existing
     layers. */

  if ((self = [self init]) != nil)
    {
#if 1
      // REMOVE THIS
      for(id i in _observedKeyPaths)
        {
          [self removeObserver: [CAImplicitAnimationObserver sharedObserver] forKeyPath: i];
        }
      [_observedKeyPaths release];
      _observedKeyPaths = nil;
#endif

      [self setDelegate: [layer delegate]];
      [self setLayoutManager: [layer layoutManager]];
      [self setSuperlayer: [layer superlayer]]; /* if copied for use in presentation layer, then ignored */
      [self setSublayers: [layer sublayers]]; /* if copied for use in presentation layer, then ignored */
      /* frame not copied: dynamically generated */
      [self setBounds: [layer bounds]];
      [self setAnchorPoint: [layer anchorPoint]];
      [self setPosition: [layer position]];
      [self setOpacity: [layer opacity]];
      [self setTransform: [layer transform]];
      [self setSublayerTransform: [layer sublayerTransform]];
      [self setOpaque: [layer isOpaque]];
      [self setGeometryFlipped: [layer isGeometryFlipped]];
      [self setBackgroundColor: [layer backgroundColor]];
      [self setMasksToBounds: [layer masksToBounds]];
      [self setContentsRect: [layer contentsRect]];
      [self setHidden: [layer isHidden]];
      [self setContentsGravity: [layer contentsGravity]];
      [self setNeedsDisplayOnBoundsChange: [layer needsDisplayOnBoundsChange]];
      [self setZPosition: [layer zPosition]];
      
      /* FIXME
         setting contents currently needs to be below setting bounds, 
         because setting the bounds currently destroys the contents. */
      [self setContents: [layer contents]]; 
      
      /* properties in protocol CAMediaTiming */
      [self setBeginTime: [layer beginTime]];
      [self setTimeOffset: [layer timeOffset]];
      [self setRepeatCount: [layer repeatCount]];
      [self setRepeatDuration: [layer repeatDuration]];
      [self setAutoreverses: [layer autoreverses]];
      [self setFillMode: [layer fillMode]];
      [self setDuration: [layer duration]];
      [self setSpeed: [layer speed]];
      
      /* private properties */
      [self setAnimations: [layer animations]];
    }
  return self;
}

- (void) dealloc
{
  for(NSString *keyPath in _observedKeyPaths)
    {
      [self removeObserver: [CAImplicitAnimationObserver sharedObserver]
                forKeyPath: keyPath];
    }
  [_observedKeyPaths release];
  [_layoutManager release];
  [_contents release];
  [_sublayers release];
  CGColorRelease(_backgroundColor);
  [_contentsGravity release];
  [_fillMode release];
  
  CGContextRelease(_opalContext);
  
  [_animations release];
  
  [super dealloc];
}

- (NSString *)description
{
  return [NSString stringWithFormat: @"<%@: %p; position: %g,%g>",
          [self class],
          self,
          [self position].x, [self position].y];
}

/* *** properties *** */
- (void) setBounds: (CGRect)bounds
{
  if (CGRectEqualToRect(bounds, _bounds))
    return;
  
  _bounds = bounds;

  if ([self needsDisplayOnBoundsChange])
    {
      [self setNeedsDisplay];
    }
}

- (void)setBackgroundColor: (CGColorRef)backgroundColor
{
  if (backgroundColor == _backgroundColor)
    return;
  
  CGColorRetain(backgroundColor);
  CGColorRelease(_backgroundColor);
  _backgroundColor = backgroundColor;
}

/* *** display methods *** */

- (void) display
{
  if ([_delegate respondsToSelector: @selector(displayLayer:)])
    {
      [_delegate displayLayer: self];
    }
  else
    {
      /* By default, uses -drawInContext: to update the 'contents' property. */
    
      CGRect bounds = [self bounds];
      
      if (!_opalContext ||
          CGBitmapContextGetWidth(_opalContext) != bounds.size.width ||
          CGBitmapContextGetHeight(_opalContext) != bounds.size.height)
      {
        CGContextRelease(_opalContext);

        _opalContext = createCGBitmapContext(bounds.size.width, bounds.size.height);
      }
      
      CGContextSaveGState (_opalContext);
      CGContextClipToRect (_opalContext, [self bounds]);
      [self drawInContext: _opalContext];
      CGContextRestoreGState (_opalContext);

      self.contents = [CABackingStore backingStoreWithContext: _opalContext];
    }
}

- (void) displayIfNeeded
{
  if (_needsDisplay)
    {
      [self display];
    }

  _needsDisplay = NO;
}

- (BOOL) needsDisplay
{
  return _needsDisplay;
}

- (void) setNeedsDisplay
{
  /* TODO: schedule redraw of the scene */
  _needsDisplay = YES;
}

- (void) setNeedsDisplayInRect: (CGRect)r
{
  [self setNeedsDisplay];
}

- (void) drawInContext: (CGContextRef)context
{
  if ([_delegate respondsToSelector: @selector(drawLayer:inContext:)])
    {
      [_delegate drawLayer: self inContext: context];
    }
}

/* layout methods */
- (void) layoutIfNeeded
{ 
}

- (void) layoutSublayers
{
}

- (void) setNeedsLayout
{
  _needsLayout = YES;
}

- (id) presentationLayer
{
  if (!_modelLayer && !_presentationLayer)
    {
      [self displayIfNeeded];

      _presentationLayer = [[CALayer alloc] initWithLayer: self];
      [_presentationLayer setModelLayer: self];
      assert([_presentationLayer isPresentationLayer]);
      
    }
  return _presentationLayer;
}

- (void) discardPresentationLayer
{
  [_presentationLayer release];
  _presentationLayer = nil;
}

- (id) modelLayer
{
  return _modelLayer;
}

- (void) setModelLayer: (id)modelLayer
{
  _modelLayer = modelLayer;
}

- (BOOL) isPresentationLayer
{
  return !_presentationLayer;
}

- (CALayer *) superlayer
{
  if (![self isPresentationLayer])
    {
      return _superlayer;
    }
  else
    {
      return [[[self modelLayer] superlayer] presentationLayer];
    }
}

- (NSArray *) sublayers
{
  if (![self isPresentationLayer])
    {
      return _sublayers;
    }
  else
    {
      NSMutableArray * presentationSublayers = [NSMutableArray arrayWithCapacity:[[[self modelLayer] sublayers] count]];
      for (id modelSublayer in [[self modelLayer] sublayers])
        {
          [presentationSublayers addObject: [modelSublayer presentationLayer]];
        }
      return presentationSublayers;
    }
}

/* ********************************** */
- (void) addAnimation: (CAAnimation *)anim forKey: (NSString *)key
{
  [_animations setValue: anim
                 forKey: key];
}

- (void) removeAnimationForKey: (NSString *)key
{
  [_animations removeObjectForKey: key];
}

- (CAAnimation *)animationForKey: (NSString *)key
{
  return [_animations valueForKey: key];
}

- (NSArray *) animationKeys
{
  return [_animations allKeys];
}

- (void) applyAnimationsAtTime: (CFTimeInterval)theTime
{
  if (![self isPresentationLayer])
    {
      static BOOL warned = NO;
      if (!warned)
        {
          NSLog(@"One time warning: Attempted to apply animations to model layer. Redirecting to presentation layer since applying animations only makes sense for presentation layers.");
          warned = YES;
        }
      [[self presentationLayer] applyAnimationsAtTime: theTime];
      return;
    }
    
    NSMutableArray * animationKeysToRemove = [NSMutableArray new];
    for (NSString * animationKey in _animations)
      {
        CAAnimation * animation = [_animations objectForKey: animationKey];
        if ([animation beginTime] == 0)
          {
            // FIXME: this MUST be grabbed from CATransaction, and
            // it must be done by the animation itself!
            // alternatively, this needs to be applied to the
            // animation upon +[CATransaction commit]
            
            CFTimeInterval oldFrameBeginTime = currentFrameBeginTime;
            currentFrameBeginTime = CACurrentMediaTime();
            [animation setBeginTime: [animation activeTimeWithTimeAuthorityLocalTime: [self localTime]]];
            currentFrameBeginTime = oldFrameBeginTime;
          }
        if ([animation isKindOfClass: [CAPropertyAnimation class]])
          {
            CAPropertyAnimation * propertyAnimation = ((CAPropertyAnimation *)animation);
                        
            if ([propertyAnimation removedOnCompletion] && [propertyAnimation activeTimeWithTimeAuthorityLocalTime: [self localTime]] > [propertyAnimation duration] * [propertyAnimation repeatCount] * ([propertyAnimation autoreverses] ? 2 : 1))
              {
                /* FIXME: doesn't take into account speed */
                
                [animationKeysToRemove addObject: animationKey];
                continue; /* Prevents animation from applying for one frame longer than its duration */
              }
            
            [propertyAnimation applyToLayer: self];
            
          }
      }
    
    [_animations removeObjectsForKeys:animationKeysToRemove];
    [animationKeysToRemove release];
}

/* ******************************** */

- (void) addSublayer: (CALayer *)layer
{
  NSMutableArray * mutableSublayers = (NSMutableArray*)_sublayers;
  
  [mutableSublayers addObject: layer];
  [layer setSuperlayer: self];
}

- (void)removeFromSuperlayer
{
  NSMutableArray * mutableSublayersOfSuperlayer = (NSMutableArray*)[[self superlayer] sublayers];
  
  [mutableSublayersOfSuperlayer removeObject: self];
  [self setSuperlayer: nil];
}

- (void) insertSublayer: (CALayer *)layer atIndex: (unsigned)index
{
  NSMutableArray * mutableSublayers = (NSMutableArray*)_sublayers;
  
  [mutableSublayers insertObject: layer atIndex: index];
  [layer setSuperlayer: self];
}

- (void) insertSublayer: (CALayer *)layer below: (CALayer *)sibling;
{
  NSMutableArray * mutableSublayers = (NSMutableArray*)_sublayers;
  
  NSInteger siblingIndex = [mutableSublayers indexOfObject: sibling];
  [mutableSublayers insertObject: layer atIndex:siblingIndex];
  [layer setSuperlayer: self];
}

- (void) insertSublayer: (CALayer *)layer above: (CALayer *)sibling;
{
  NSMutableArray * mutableSublayers = (NSMutableArray*)_sublayers;
  
  NSInteger siblingIndex = [mutableSublayers indexOfObject: sibling];
  [mutableSublayers insertObject: layer atIndex:siblingIndex+1];
  [layer setSuperlayer: self];
}

- (CALayer *) rootLayer
{
  CALayer * layer = self;
  while([layer superlayer])
    layer = [layer superlayer];
  
  return layer;
}

- (NSArray *) allAncestorLayers
{
  /* This could be cached. It could even be updated at 
    -addSublayer: and -insertSublayer:... methods. */
  
  NSMutableArray * allAncestorLayers = [NSMutableArray array];
  
  CALayer * layer = self;
  while([layer superlayer])
    {
      layer = [layer superlayer];
      if (layer)
        [allAncestorLayers addObject: layer];
    }
  
  return allAncestorLayers;
}

- (CALayer *) nextAncestorOf: (CALayer *)layer
{
  if ([[self sublayers] containsObject: layer])
    return self;
    
  for (id i in [self sublayers])
    {
      if ([i nextAncestorOf: layer])
        return i;
    }
  
  return nil;
}

+ (void) setCurrentFrameBeginTime: (CFTimeInterval)frameTime
{
  currentFrameBeginTime = frameTime;
}

- (CFTimeInterval) activeTimeWithTimeAuthorityLocalTime: (CFTimeInterval)timeAuthorityLocalTime
{
  /* Slides */
  CFTimeInterval activeTime = (timeAuthorityLocalTime - [self beginTime]) * [self speed] + [self timeOffset];
  assert(activeTime > 0);

  return activeTime;
}

- (CFTimeInterval) localTimeWithTimeAuthority: (id<CAMediaTiming>)timeAuthority
{
  /* Slides */
  CFTimeInterval timeAuthorityLocalTime = [timeAuthority localTime];
  if (!timeAuthority)
    timeAuthorityLocalTime = currentFrameBeginTime ? currentFrameBeginTime : CACurrentMediaTime();
  
  CFTimeInterval activeTime = [self activeTimeWithTimeAuthorityLocalTime: timeAuthorityLocalTime];
  if (isinf([self duration]))
    return activeTime;
  
  NSInteger k = floor(activeTime / [self duration]);
  CFTimeInterval localTime = activeTime - k * [self duration];
  if ([self autoreverses] && k % 2 == 1)
    {
      localTime = [self duration] - localTime;
    }
    
  return localTime;
}




- (CFTimeInterval) activeTime
{
  /* Slides */
  id<CAMediaTiming> timeAuthority = [self superlayer];
  if (!timeAuthority)
    return [self activeTimeWithTimeAuthorityLocalTime: currentFrameBeginTime ? currentFrameBeginTime : CACurrentMediaTime()];
  else
    return [self activeTimeWithTimeAuthorityLocalTime: [timeAuthority localTime]];
}

- (CFTimeInterval) localTime
{
  id<CAMediaTiming> timeAuthority = [self superlayer];
  return [self localTimeWithTimeAuthority: timeAuthority];
}

- (CFTimeInterval) convertTime: (CFTimeInterval)theTime fromLayer: (CALayer *)layer
{
  if (layer == nil)
    return [self localTime];

  /* Just make use of convertTime:toLayer: instead of reimplementing */
  return [layer convertTime: theTime toLayer: self];
}
- (CFTimeInterval) convertTime: (CFTimeInterval)theTime toLayer: (CALayer *)layer
{
  /* Method used to convert 'activeTime' of self into 'activeTime' 
     of 'layer'. */

  if (layer == self)
    return theTime;

  /* First, convert theTime to the "media time" timespace, the 
     timespace returned by CACurrentMediaTime(). */
     
  /* For self, invert formula in theTime. */
  theTime -= [self timeOffset];
  theTime /= [self speed];
  theTime += [self beginTime];

  NSArray * ancestorLayers = [self allAncestorLayers];
  for (CALayer * l in ancestorLayers)
    {
      /* layer was one of our ancestors? great! */
      if (layer == l)
        return theTime;
      
      /* For each layer, we invert the formula in -activeTime. */
      theTime -= [l timeOffset];
      theTime /= [l speed];
      theTime += [l beginTime];
    }
  
  if (layer == nil)
    {
      /* We were requested time in "media time" timespace. */
      return theTime;
    }
  
  /* Use activeTime/localTime mechanism to convert media time into 
     layer time */
  CFTimeInterval oldFrameBeginTime = currentFrameBeginTime;
  currentFrameBeginTime = theTime;
  theTime = [layer activeTime];
  currentFrameBeginTime = oldFrameBeginTime;
  
  return theTime;
}

/* Unimplemented functions: */
#if 0
- (CGPoint) convertPoint: (CGPoint)p fromLayer: (CALayer *)l;
- (CGPoint) convertPoint: (CGPoint)p toLayer: (CALayer *)l;
- (CGRect) convertRect: (CGRect)p fromLayer: (CALayer *)l;
- (CGRect) convertRect: (CGRect)p toLayer: (CALayer *)l;
- (void)setNeedsLayout;
- (void)layoutIfNeeded;

#endif

/* TODO:
 * -setSublayers: needs to correctly unset superlayer from old values and set new superlayer for new values.
 */

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
