/* Demo/DemoOpenGLView.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vucica <ivan@vucica.net>
   Date: August 2012

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

#import "DemoOpenGLView.h"

#if !(__APPLE__)
#import <GL/gl.h>
#import <GL/glu.h>
#else
#import <OpenGL/gl.h>
#endif
#import <CoreGraphics/CoreGraphics.h>

#if !(GSIMPL_UNDER_COCOA)
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#else
#import <AppKit/NSOpenGL.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import <GSQuartzCore/AppleSupport.h>
#import <GSQuartzCore/QuartzCore.h>
#endif

#import "TextLayer.h"
#import "GradientLayer.h"


@implementation DemoOpenGLView

- (void) dealloc
{
  if (_isAnimating)
    [self stopAnimation];

  [super dealloc];
}

- (void) startAnimation
{
  if (!_timer)
    _timer = [NSTimer scheduledTimerWithTimeInterval: 1./60. 
                                              target: self 
                                            selector: @selector(timerAnimation:) 
                                            userInfo: nil 
                                             repeats: YES];
  _isAnimating = YES;

}

- (void) stopAnimation
{
  [_timer invalidate];
  _timer = nil;

  _isAnimating = NO;
}

- (CGImageRef) createImageWithResource: (NSString *)imageName ofType: (NSString *)type
{
  CFURLRef imageURL = (CFURLRef)[[NSBundle mainBundle] URLForResource: imageName withExtension: type];
  CGImageSourceRef imageSource = CGImageSourceCreateWithURL(imageURL, NULL);
  CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
#if GNUSTEP
  if (imageURL && !image)
    {
      if ([imageSource isKindOfClass: NSClassFromString(@"CGImageSourcePNG")] &&
          [type isEqualToString: @"tiff"])
        {
          NSLog(@"Opal bug! Trying to read a %@ with %@.", type, [imageSource class]);
          [(id)imageSource release];
          NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat: @"public.%@", type], kCGImageSourceTypeIdentifierHint, nil];
          imageSource = CGImageSourceCreateWithURL(imageURL, options);
          image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        }
    }
#endif

#if !GNUSTEP
  CFRelease(imageSource);
#else
  // avoding linking to corebase, for now
  [(id)imageSource release];
#endif

  if (!image)
    {
      NSLog(@"failed to load image %@.%@", imageName, type);
    }
  return image;
}

- (void) prepareOpenGL
{
  [super prepareOpenGL];
  CGColorRef whiteColor = CGColorCreateGenericRGB(1, 1, 1, 1);
  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);
  CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
  CGColorRef grayColor = CGColorCreateGenericRGB(0.4, 0.4, 0.4, 1);

  /* Create renderer */
#if GNUSTEP || GSIMPL_UNDER_COCOA
  _renderer = [CARenderer rendererWithNSOpenGLContext: [self openGLContext]
                                              options: nil];
#else
  _renderer = [CARenderer rendererWithCGLContext: [self openGLContext].CGLContextObj
                                         options: nil];
#endif
  [_renderer retain];
  [_renderer setBounds: NSRectToCGRect([self bounds])];

  /* Create root layer */
  {
    CALayer * layer = [CALayer layer];
    [_renderer setLayer: layer];
    [layer setBounds: NSRectToCGRect([self bounds])];
    [layer setBackgroundColor: whiteColor];  
    CGPoint midPos = CGPointMake([_renderer bounds].size.width/2,
                                 [_renderer bounds].size.height/2);
    [layer setPosition: midPos];

    /* Load a perspective transform */
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = 1.0 / -500.;
    [layer setSublayerTransform: perspective];

    _rootLayer = [layer retain];
  }

  /* Create GNUstep logo layer */
  {
    CALayer * gnustepLogoLayer = [CALayer layer];
    [_rootLayer addSublayer: gnustepLogoLayer];
    CGPoint midPos = CGPointMake([_rootLayer bounds].size.width/2,
                                 [_rootLayer bounds].size.height/2);
    [gnustepLogoLayer setPosition: midPos];
    CGImageRef image = [self createImageWithResource: @"GNUstep"
                                              ofType: @"png"];
    if (!image)
      {
        NSLog(@"Could not load GNUstep logo image.");
        // FIXME: Opal crashes on CGImageGetWidth()/Height() for NULL arg
        exit(-1);
      }
    [gnustepLogoLayer setContents: (id)image];
    [gnustepLogoLayer setBounds: CGRectMake(0, 0,
                                            CGImageGetWidth(image),
                                            CGImageGetHeight(image))];
    [gnustepLogoLayer setOpacity: 0];
    [gnustepLogoLayer setShadowOpacity: 1];

    [CATransaction flush];
    
#if GNUSTEP || GSIMPL_UNDER_COCOA
    // Implicit animation can't pick up the current time unless the
    // current time has been calculated. This is a bug in QuartzCore.

    // Note! We are happy with implicit animations not functioning
    // before this.
    [_renderer beginFrameAtTime: CACurrentMediaTime() timeStamp: NULL];
    [_renderer endFrame];
#endif

    [CATransaction begin];
    [CATransaction setAnimationDuration: 3];
    [gnustepLogoLayer setOpacity: 1];
    [CATransaction commit];
    
    [self performSelector: @selector(gnustepLogoLayerStage2:)
               withObject: gnustepLogoLayer 
               afterDelay: 3];
    
  }
  {
    TextLayer * gnustepTitleLayer = [TextLayer layer];
    [_rootLayer addSublayer: gnustepTitleLayer];
    [gnustepTitleLayer setText: @"GNUstep"];
    [gnustepTitleLayer setBounds: CGRectMake(0, 0, 250, 50)];
    [gnustepTitleLayer setPosition: CGPointMake(300, [self frame].size.height - 100)];
    [gnustepTitleLayer setColor: grayColor];
    [gnustepTitleLayer setShadowColor: blackColor];
    [gnustepTitleLayer setShadowOpacity: 1.0];
    [gnustepTitleLayer setShadowOffset: CGSizeMake(0, 0)];
    [gnustepTitleLayer setOpacity: 0];
    [gnustepTitleLayer setFontSize: 48];
    [gnustepTitleLayer setNeedsDisplay];
    
    /* After layer is displayed, shrink it */
    [self performSelector: @selector(gnustepTitleLayerStage1:)
               withObject: gnustepTitleLayer
               afterDelay: 0.1];
    
    [self performSelector: @selector(gnustepTitleLayerStage2:)
               withObject: gnustepTitleLayer
               afterDelay: 3];


  }
  
  
  [self startAnimation];
  
  CGColorRelease(yellowColor);
  CGColorRelease(whiteColor);
  CGColorRelease(blackColor);
  CGColorRelease(grayColor);

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);
  glClear(GL_COLOR_BUFFER_BIT);

}

- (void) gnustepLogoLayerStage2: (CALayer *)gnustepLogoLayer
{
  [CATransaction begin];
  [CATransaction setAnimationDuration: 1];
  CATransform3D transform = CATransform3DIdentity;
  transform = CATransform3DTranslate(transform, -130, 100, 0);
  transform = CATransform3DScale(transform, 0.7, 0.7, 1.0);

  transform = CATransform3DRotate(transform,  M_PI_4, 0, 1, 0);
  [gnustepLogoLayer setTransform: transform];
  [CATransaction commit];

  [self performSelector: @selector(presentMenu:)
             withObject: nil
             afterDelay: 1];
}

- (void) gnustepLogoLayerStage2_lessTransforms: (CALayer *)gnustepLogoLayer
{
  /* Same as gnustepLogoLayerStage2:, except with less transforms and more
     use of other properties for animation. */
  [CATransaction begin];
  [CATransaction setAnimationDuration: 1];
  CATransform3D transform = CATransform3DIdentity;

  transform = CATransform3DRotate(transform,  M_PI_4, 0, 1, 0);
  [gnustepLogoLayer setTransform: transform];
  [gnustepLogoLayer setPosition: CGPointMake(150,
                                             [self frame].size.height - 100)];
  [gnustepLogoLayer setBounds: CGRectMake(0, 0,
                                          [gnustepLogoLayer bounds].size.width * 0.7,
                                          [gnustepLogoLayer bounds].size.height * 0.7)];
  [CATransaction commit];

  [self performSelector: @selector(presentMenu:)
             withObject: nil
             afterDelay: 1];
}



- (void) gnustepTitleLayerStage1: (TextLayer *)gnustepTitleLayer
{
  [CATransaction begin];
  [CATransaction setAnimationDuration: 0.01];

  [gnustepTitleLayer setBounds: CGRectMake(0, 0, 1, 50)];
  [gnustepTitleLayer setPosition: CGPointMake([gnustepTitleLayer position].x - 250/2, [gnustepTitleLayer position].y)];
  [gnustepTitleLayer setContentsRect: CGRectMake(0, 0, 1./250., 1.)];
  
  [CATransaction commit];
}
- (void) gnustepTitleLayerStage2: (TextLayer *)gnustepTitleLayer
{

  [CATransaction begin];
  [CATransaction setDisableActions: YES];
  
  [gnustepTitleLayer setOpacity: 1];
  
  [CATransaction commit],

  [CATransaction begin];
  [CATransaction setAnimationDuration: 1];

  [gnustepTitleLayer setBounds: CGRectMake(0, 0, 250, 50)];
  [gnustepTitleLayer setPosition: CGPointMake([gnustepTitleLayer position].x + 250/2, [gnustepTitleLayer position].y)];
  [gnustepTitleLayer setContentsRect: CGRectMake(0, 0, 1., 1.)];
  
  [CATransaction commit];

}

- (void) presentMenu: (id)object
{
#define MENU_ITEM(name) [NSDictionary dictionaryWithObjectsAndKeys: name, @"name", nil]
  NSArray * items = [NSArray arrayWithObjects:
   MENU_ITEM(@"Welcome to"),
   MENU_ITEM(@"GNUstep"),
   MENU_ITEM(@"QuartzCore"),
   MENU_ITEM(@"Core Animation"),
   nil];
   
  
  int index = 0;
  for (id item in items)
    {
      /* Problems with setTimeOffset:, in both Cocoa and GNUstep.
         So we'll just add the object at different times.
         */
      [self performSelector: @selector(presentMenuItem:)
                 withObject: item
                 afterDelay: index * 0.5];
                 
      index++;
    }
}
- (void) presentMenuItem: (id) item
{
  static int index = 0;
  
  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);
  CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);

  /* Create a background gradient layer */
  GradientLayer * backgroundLayer = [GradientLayer layer];
  [backgroundLayer setBounds: CGRectMake(0, 0, 300, 50)];
  [backgroundLayer setPosition: CGPointMake([_rootLayer bounds].size.width - [backgroundLayer bounds].size.width/2 + 50, [_rootLayer bounds].size.height/2 - index * 50)];
  [backgroundLayer setNeedsDisplay];
  [_rootLayer addSublayer: backgroundLayer];
  
  /* Create text layer */
  TextLayer * textLayer = [TextLayer layer];
  [textLayer setBounds: [backgroundLayer bounds]];
  [textLayer setPosition: CGPointMake([backgroundLayer bounds].size.width/2, [backgroundLayer bounds].size.height/2)];
  [textLayer setText: [item valueForKey: @"name"]];
  [textLayer setColor: blackColor];
//  [textLayer setShadowRadius: 1.0];
//  [textLayer setShadowOpacity: 1.0];
//  [textLayer setShadowOffset: CGSizeZero];
  [textLayer setFontSize: 16];
  [textLayer setNeedsDisplay];
  [backgroundLayer addSublayer: textLayer];
  
  CABasicAnimation * slideIn = [CABasicAnimation animationWithKeyPath: @"position"];
  CGPoint fromPt = CGPointMake([_rootLayer bounds].size.width + [backgroundLayer bounds].size.width/2, [backgroundLayer position].y);
  CGPoint toPt = [backgroundLayer position];
  [slideIn setFromValue: [NSValue valueWithBytes: &fromPt objCType: @encode(CGPoint)]];
  [slideIn setToValue: [NSValue valueWithBytes: &toPt objCType: @encode(CGPoint)]];
  [slideIn setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionDefault]];
  [slideIn setDuration: 1];
  //[slideIn setFillMode: kCAFillModeBackwards];
  [slideIn setSpeed: 1];
  
  [backgroundLayer addAnimation: slideIn forKey: @"position"];
  
  CGColorRelease(blackColor);
  CGColorRelease(yellowColor);
  
  index ++;
  
  /* Force update of painted content. Not needed under Cocoa. */
  [_renderer addUpdateRect: [_renderer bounds]];
}

- (void) timerAnimation: (NSTimer *)timer
{
  [[self openGLContext] makeCurrentContext];

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, [self frame].size.width, 0, [self frame].size.height, -2500, 2500);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  /* */
  [_renderer beginFrameAtTime: CACurrentMediaTime()
                    timeStamp: NULL];
  [self clearBounds: [_renderer updateBounds]];
  [_renderer render];
  [_renderer endFrame];
  /* */

  glFlush();

  [[self openGLContext] flushBuffer];
}

- (void)clearBounds:(CGRect)bounds
{  
  glBegin(GL_QUADS);
  glColor4f(0,0,0,1);
  glVertex2f(bounds.origin.x, bounds.origin.y);
  glVertex2f(bounds.origin.x+bounds.size.width, bounds.origin.y);
  glVertex2f(bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height);
  glVertex2f(bounds.origin.x, bounds.origin.y+bounds.size.height);
  glEnd();
}

- (void) mouseDown:(NSEvent *)theEvent
{
  /* We don't yet have coordinate system conversion in GNUstep QuartzCore */
  /* Let's perform it manually. */
  NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  //curPoint.x -= [_renderer bounds].size.width/2;
  //curPoint.y -= [_renderer bounds].size.height/2;
  
  /* No support for frame. This means we can play only with immediate nontransformed
     sublayers of the root layer, and only after applying positions to rects. */
  for (CALayer * sublayer in [_rootLayer sublayers])
    {
      /* A primitive way to calculate frame */
      CGRect frame = [sublayer bounds];
      frame.origin = CGPointMake([sublayer position].x - frame.size.width/2, [sublayer position].y - frame.size.height/2);
      if ([sublayer isKindOfClass: [GradientLayer class]])
        {
          /* CGRectContainsPoint() is a primitive way of detecting clickable 'buttons' on the right side. */

          /* Here we have two possible implementations of animating the button clicked on.
             We can do it either via transforms or via changing bounds. We could also use 
             setPosition:. */
#if 1
          if (CGRectContainsPoint(frame, NSPointToCGPoint(curPoint)))
            {
              [sublayer setTransform: CATransform3DMakeTranslation(-50, 0, 0)];
            }
          else
            {
              [sublayer setTransform: CATransform3DIdentity];
            }

#else

          if (CGRectContainsPoint(frame, NSPointToCGPoint(curPoint)))
            {
              [sublayer setBounds: CGRectMake(0, 0, 300, 50)];
            }
          else
            {
              [sublayer setBounds: CGRectMake(0, 0, 200, 50)];
            }
#endif
        }
    }
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
