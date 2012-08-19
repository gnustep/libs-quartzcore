/* Tests/offscreen_render.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vucica <ivan@vucica.net>
   Date: June 2012

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

#if !(__APPLE__)
#import <GL/gl.h>
#import <GL/glu.h>
#else
#import <OpenGL/gl.h>
#endif
#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

#if GSIMPL_UNDER_COCOA
#import <GSQuartzCore/AppleSupportRevert.h>
#endif
#import <AppKit/NSOpenGL.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>

#if !(GSIMPL_UNDER_COCOA)
#import <QuartzCore/CARenderer.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CABase.h>
#import <QuartzCore/CATransaction.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>
#else
#import <GSQuartzCore/AppleSupport.h>
#import <GSQuartzCore/CARenderer.h>
#import <GSQuartzCore/CALayer.h>
#import <GSQuartzCore/CABase.h>
#import <GSQuartzCore/CATransaction.h>
#import <GSQuartzCore/CAAnimation.h>
#import <GSQuartzCore/CAMediaTimingFunction.h>
#endif

#import "QCTestOpenGLView.h"

@interface OffscreenRenderCustomLayer : CALayer
{
  CGSize _size;
}
@property (assign) CGSize size;

@end

@implementation OffscreenRenderCustomLayer
@synthesize size=_size;

- (void) drawInContext: (CGContextRef)context
{
  float width = [self size].width;
  float height = [self size].height;

  /* Draw some content into the context */
  CGRect rect = CGRectMake(50, 50, width/2.0, height/2.0);
  CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
  CGContextSetRGBFillColor(context, 1, 0, 0, 1);
  CGContextSetLineWidth(context, 4.0);
  CGContextStrokeRect(context, rect);
  CGContextFillRect(context, rect);
}

@end

/* ******************** */

@interface OffscreenRenderOpenGLView : QCTestOpenGLView
{
  CARenderer * _renderer;
  CALayer * _theSublayer;
  CALayer * _theShadowedSublayer;
  CALayer * _theShadowedSublayerChild;
}

- (void) timerAnimation: (NSTimer *)aTimer;

@end

Class classOfTestOpenGLView()
{
  return [OffscreenRenderOpenGLView class];
}

/* *********************** */
@implementation OffscreenRenderOpenGLView

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)viewDidMoveToSuperview
{
  [super viewDidMoveToSuperview];

  static BOOL ranOnce = NO;
  if (ranOnce)
    return;
  ranOnce = YES;

  NSMenu * mainMenu = [[NSApplication sharedApplication] mainMenu];
  
  NSMenuItem * testsMenuItem = [[NSMenuItem alloc] init];
  [testsMenuItem setTitle: @"Tests"]; /* Note: needed only under GNUstep */
  NSMenu * testsMenu = [[NSMenu alloc] initWithTitle: @"Tests"];
  {
    [testsMenu addItemWithTitle:@"Animation 1" action:@selector(animation1:) keyEquivalent:@"1"];
    [testsMenu addItemWithTitle:@"Animation 2" action:@selector(animation2:) keyEquivalent:@"2"];
    [testsMenu addItemWithTitle:@"Animation 3" action:@selector(animation3:) keyEquivalent:@"3"];
    [testsMenu addItemWithTitle:@"Animation 4" action:@selector(animation4:) keyEquivalent:@"4"];
    [testsMenu addItemWithTitle:@"Animation 5" action:@selector(animation5:) keyEquivalent:@"5"];
    [testsMenu addItemWithTitle:@"Toggle Offscreen Render Layer1" action:@selector(toggleOffscreenRenderLayer1:) keyEquivalent:@"6"];
    [testsMenu addItemWithTitle:@"Toggle Offscreen Render Layer2" action:@selector(toggleOffscreenRenderLayer2:) keyEquivalent:@"7"];
    [testsMenu addItemWithTitle:@"Set Needs Display" action:@selector(layerSetNeedsDisplay:) keyEquivalent:@"d"];
  }
  
  [testsMenuItem setSubmenu:testsMenu];
  [testsMenu release];
  
  [mainMenu insertItem:testsMenuItem atIndex:1];
  [testsMenuItem release];
  
}

- (void) animation1:sender
{
  static BOOL toggle = NO;
  if(!toggle)
    [[_renderer layer] setPosition: CGPointZero];
  else
    [[_renderer layer] setPosition: CGPointMake([self frame].size.width/2, [self frame].size.height/2)];
  toggle = !toggle;
}

- (void) animation2:sender
{
  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);  
  CGColorRef blueColor = CGColorCreateGenericRGB(0, 0, 1, 1);

  static BOOL toggle = NO;
  if(!toggle)
    [_theShadowedSublayer setBackgroundColor: yellowColor];
  else
    [_theShadowedSublayer setBackgroundColor: blueColor];
  toggle = !toggle;
  
  CGColorRelease(yellowColor);
  CGColorRelease(blueColor);
}

- (void) animation3:sender
{
  CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
  CGColorRef cyanColor = CGColorCreateGenericRGB(0, 1, 1, 1);

  static BOOL toggle = NO;
  if(!toggle)
    [_theShadowedSublayer setShadowColor: cyanColor];
  else
    [_theShadowedSublayer setShadowColor: blackColor];
  toggle = !toggle;
  
  CGColorRelease(blackColor);
  CGColorRelease(cyanColor);
}

- (void) animation4:sender
{
  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);  
  CGColorRef clearColor = CGColorCreateGenericRGB(0, 0, 0, 0);

  static BOOL toggle = NO;
  if(!toggle)
    [[_renderer layer] setBackgroundColor: clearColor];
  else
    [[_renderer layer] setBackgroundColor: yellowColor];
  toggle = !toggle;
  
  CGColorRelease(yellowColor);
  CGColorRelease(clearColor);
}

- (void) animation5:sender
{
  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);  
  CGColorRef clearColor = CGColorCreateGenericRGB(0, 0, 0, 0);

  static BOOL toggle = NO;
  if(!toggle)
    [_theShadowedSublayer setAnchorPoint: CGPointMake(0,0)];
  else
    [_theShadowedSublayer setAnchorPoint: CGPointMake(0.5,0.5)];
  toggle = !toggle;
  
  CGColorRelease(yellowColor);
  CGColorRelease(clearColor);
}

- (void) toggleOffscreenRenderLayer1:sender
{
  static BOOL toggle = NO;
  if(!toggle)
    [[_renderer layer] setShouldRasterize: YES];
  else
    [[_renderer layer] setShouldRasterize: NO];
  
  toggle = !toggle;
}

- (void) toggleOffscreenRenderLayer2:sender
{
  static BOOL toggle = NO;
  if(!toggle)
    [_theSublayer setShouldRasterize: YES];
  else
    [_theSublayer setShouldRasterize: NO];

  toggle = !toggle;
}


- (void) layerSetNeedsDisplay:sender
{
  CALayer * layer = [_renderer layer];
  [layer setNeedsDisplay];
}

- (void) prepareOpenGL
{
  [super prepareOpenGL];

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);
  glClear(GL_COLOR_BUFFER_BIT);
  
  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);  
  CGColorRef greenColor = CGColorCreateGenericRGB(0, 1, 0, 1);
  CGColorRef blueColor = CGColorCreateGenericRGB(0, 0, 1, 1);

  OffscreenRenderCustomLayer * layer = [OffscreenRenderCustomLayer layer];
  [layer setBounds: CGRectMake(0, 0, [self frame].size.width*0.6, [self frame].size.height*0.6)];
  [layer setPosition: CGPointMake([self frame].size.width/2, [self frame].size.height/2)];
  [layer setBackgroundColor: yellowColor];
  [layer setSize: CGSizeMake([self frame].size.width, [self frame].size.height)];
  [layer setNeedsDisplay];
  
#if GNUSTEP || GSIMPL_UNDER_COCOA
  _renderer = [CARenderer rendererWithNSOpenGLContext: [self openGLContext]
                                              options: nil];
#else
  _renderer = [CARenderer rendererWithCGLContext: [self openGLContext].CGLContextObj
                                         options: nil];
#endif
  [_renderer retain];
  [_renderer setLayer: layer];
  [_renderer setBounds: NSRectToCGRect([self bounds])];
  
  OffscreenRenderCustomLayer * layer2 = [OffscreenRenderCustomLayer layer];
  [layer2 setBounds: CGRectMake (0, 0, 100, 100)];
  [layer2 setBackgroundColor: greenColor];
  [layer2 setSize: CGSizeMake([self frame].size.width, [self frame].size.height)];
  [layer2 setPosition: CGPointMake ([layer bounds].size.width, 0)];
  [layer2 setNeedsDisplay];
  [layer addSublayer: layer2];
  _theSublayer = [layer2 retain];
  
  
  OffscreenRenderCustomLayer * layer3 = [OffscreenRenderCustomLayer layer];
  [layer3 setBounds: CGRectMake (0, 0, 125, 125)];
  [layer3 setValue:(id)blueColor forKey:@"backgroundColor"]; // testing KVC for colors
  [layer3 setSize: CGSizeMake([self frame].size.width, [self frame].size.height)];
  [layer3 setNeedsDisplay];
  [layer3 setPosition: CGPointMake ([layer bounds].size.width, [layer bounds].size.height)];
  [layer3 setShadowOpacity: 1.0];
  [layer addSublayer: layer3];
  _theShadowedSublayer = [layer3 retain];
  
  
  OffscreenRenderCustomLayer * layer4 = [OffscreenRenderCustomLayer layer];
  [layer4 setBounds: CGRectMake (0, 0, 125, 125)];
  [layer4 setSize: CGSizeMake(100, 100)];
  [layer4 setNeedsDisplay];
  [layer4 setPosition: CGPointMake (0, [layer bounds].size.height)];
  [layer addSublayer: layer4];
  
  CFURLRef poweredByGNUstepURL = (CFURLRef)[[NSBundle mainBundle] URLForResource:@"PoweredByGNUstep" withExtension:@"tiff"];
  CGImageSourceRef poweredByGNUstepSource = CGImageSourceCreateWithURL(poweredByGNUstepURL, NULL);
  CGImageRef poweredByGNUstepImage = CGImageSourceCreateImageAtIndex(poweredByGNUstepSource, 0, NULL);
  CFRelease(poweredByGNUstepSource);
  
  if (poweredByGNUstepImage)
    {
      OffscreenRenderCustomLayer * layer5 = [OffscreenRenderCustomLayer layer];
      [layer5 setBounds: CGRectMake (0, 0, CGImageGetWidth(poweredByGNUstepImage), CGImageGetHeight(poweredByGNUstepImage))];
      [layer5 setContents: (id)poweredByGNUstepImage];
      [layer5 setPosition: CGPointMake ([layer bounds].size.width / 2, [layer bounds].size.height / 2)];
      [layer addSublayer: layer5];
      
      CGImageRelease(poweredByGNUstepImage);
    }
  else
    NSLog(@"offscreen_render could not find PoweredByGNUstep.tiff");
  
  CGColorRelease(yellowColor);
  CGColorRelease(greenColor);
  CGColorRelease(blueColor);
}

- (void) dealloc
{
  [_theShadowedSublayer removeFromSuperlayer];
  [_theShadowedSublayer release];
  [_theSublayer removeFromSuperlayer];
  [_theSublayer release];
  [_renderer release];
  [super dealloc];
}

- (void) timerAnimation: (NSTimer *)aTimer
{
  [super timerAnimation: aTimer];
  [[self openGLContext] makeCurrentContext];

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, [self frame].size.width, 0, [self frame].size.height, -1, 1);
        
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
  
  _timer = [NSTimer scheduledTimerWithTimeInterval: 1./60 //[_renderer nextFrameTime]-CACurrentMediaTime()
                                            target: self
                                          selector: @selector(timerAnimation:)
                                          userInfo: nil
                                           repeats: NO];
}


@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
