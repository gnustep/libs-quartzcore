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

#if 0
CATransform3D frustumTransform(float left, float right, float bottom, float top, float znear, float zfar)
{
  CATransform3D frustumTransform;

  frustumTransform.m11 = (2.0 * znear) / (right - left);
  frustumTransform.m12 = 0.0;
  frustumTransform.m13 = (right + left) / (right - left);
  frustumTransform.m14 = 0.0;

  frustumTransform.m21 = 0.0;
  frustumTransform.m22 = (2.0 * znear) / (top - bottom);
  frustumTransform.m23 = (top + bottom) / (top - bottom);
  frustumTransform.m24 = 0.0;

  frustumTransform.m31 = 0.0;
  frustumTransform.m32 = 0.0;
  frustumTransform.m33 = (-zfar - znear) / (zfar - znear);
  frustumTransform.m34 = (left - right) * zfar / (zfar - znear);

  frustumTransform.m41 = 0.0;
  frustumTransform.m42 = 0.0;
  frustumTransform.m43 = -1.0;
  frustumTransform.m44 = 0.0;

  return frustumTransform;
}
#endif

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
    
#if GNUSTEP
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
               afterDelay: 0];
    
  }
  [self startAnimation];
  
  CGColorRelease(yellowColor);
  CGColorRelease(whiteColor);

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);
  glClear(GL_COLOR_BUFFER_BIT);

}

- (void) gnustepLogoLayerStage2: (CALayer *)gnustepLogoLayer
{
  [CATransaction begin];
  [CATransaction setAnimationDuration: 3];
  CATransform3D transform = CATransform3DMakeRotation(-M_PI, 0, 1, 0);
//  transform = CATransform3DTranslate(transform, 0, 0, -300);
  [gnustepLogoLayer setTransform: transform];
  [CATransaction commit];

  [self performSelector: @selector(gnustepLogoLayerStage3:)
             withObject: gnustepLogoLayer
             afterDelay: 3];
}
- (void) gnustepLogoLayerStage3: (CALayer *)gnustepLogoLayer
{
  [CATransaction begin];
  [CATransaction setAnimationDuration: 1.5];
  CATransform3D transform = CATransform3DMakeRotation(-M_PI_2*3, 0, 1, 0);
//  transform = CATransform3DTranslate(transform, 0, 0, -300);
  [gnustepLogoLayer setTransform: transform];
  [CATransaction commit];

  [self performSelector: @selector(gnustepLogoLayerStage4:)
             withObject: gnustepLogoLayer
             afterDelay: 1.5];
}
- (void) gnustepLogoLayerStage4: (CALayer *)gnustepLogoLayer
{
  [CATransaction begin];
  [CATransaction setAnimationDuration: 1.5];
  CATransform3D transform = CATransform3DMakeRotation(0, 0, 1, 0);
//  transform = CATransform3DTranslate(transform, 0, 0, -300);
  [gnustepLogoLayer setTransform: transform];
  [CATransaction commit];

  [self performSelector: @selector(gnustepLogoLayerStage2:)
             withObject: gnustepLogoLayer
             afterDelay: 1.5];
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

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
