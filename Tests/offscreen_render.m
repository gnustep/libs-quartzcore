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

- (void) drawInContext:(CGContextRef)context
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

  NSMenu * mainMenu = [[NSApplication sharedApplication] mainMenu];
  
  NSMenuItem * testsMenuItem = [[NSMenuItem alloc] init];
  [testsMenuItem setTitle: @"Tests"]; /* Note: needed only under GNUstep */
  NSMenu * testsMenu = [[NSMenu alloc] initWithTitle: @"Tests"];
  {
    [testsMenu addItemWithTitle:@"Animation 1" action:@selector(animation1:) keyEquivalent:@"1"];
    [testsMenu addItemWithTitle:@"Toggle Offscreen Render Layer1" action:@selector(toggleOffscreenRenderLayer1:) keyEquivalent:@"2"];
    [testsMenu addItemWithTitle:@"Toggle Offscreen Render Layer2" action:@selector(toggleOffscreenRenderLayer2:) keyEquivalent:@"3"];
    [testsMenu addItemWithTitle:@"Set Needs Display" action:@selector(layerSetNeedsDisplay:) keyEquivalent:@"d"];
  }
  
  [testsMenuItem setSubmenu:testsMenu];
  [testsMenu release];
  
  [mainMenu insertItem:testsMenuItem atIndex:1];
  [testsMenuItem release];
  
}

- (void) animation1:sender
{
#if GNUSTEP || GSIMPL_UNDER_COCOA
  #warning Manually creating transaction for implicit animations
  [CATransaction begin];
#endif

  static BOOL toggle = NO;
  if(!toggle)
    [[_renderer layer] setPosition: CGPointZero];
  else
    [[_renderer layer] setPosition: CGPointMake([self frame].size.width/2, [self frame].size.height/2)];
  toggle = !toggle;
  
#if GNUSTEP || GSIMPL_UNDER_COCOA
  #warning Manually committing transaction for implicit animations
  [CATransaction commit];
#endif
}

- (void) toggleOffscreenRenderLayer1:sender
{
#if GNUSTEP || GSIMPL_UNDER_COCOA
  #warning Manually creating transaction for implicit animations
  [CATransaction begin];
#endif

  static BOOL toggle = NO;
  if(!toggle)
    [[_renderer layer] setShouldRasterize: YES];
  else
    [[_renderer layer] setShouldRasterize: NO];
  
  toggle = !toggle;
  
#if GNUSTEP || GSIMPL_UNDER_COCOA
  #warning Manually committing transaction for implicit animations
  [CATransaction commit];
#endif
}

- (void) toggleOffscreenRenderLayer2:sender
{
#if GNUSTEP || GSIMPL_UNDER_COCOA
  #warning Manually creating transaction for implicit animations
  [CATransaction begin];
#endif

  static BOOL toggle = NO;
  if(!toggle)
    [_theSublayer setShouldRasterize: YES];
  else
    [_theSublayer setShouldRasterize: NO];

  toggle = !toggle;
  
#if GNUSTEP || GSIMPL_UNDER_COCOA
  #warning Manually committing transaction for implicit animations
  [CATransaction commit];
#endif
}


- (void) layerSetNeedsDisplay:sender
{
  CALayer * layer = [_renderer layer];
  [layer setNeedsDisplay];
  
}

- (void) prepareOpenGL
{
  [super prepareOpenGL];

  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);  
  CGColorRef greenColor = CGColorCreateGenericRGB(0, 1, 0, 1);

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
  [layer2 setNeedsDisplay];
  [layer addSublayer: layer2];
  _theSublayer = [layer2 retain];
  
  [layer setSublayerTransform: CATransform3DMakeRotation(M_PI_2 * 0.25 /* 45 deg */, 0, 0, 1)];
}

- (void) dealloc
{
  [_theSublayer removeFromSuperlayer];
  [_theSublayer release];
  [_renderer release];
  [super dealloc];
}

- (void) timerAnimation: (NSTimer *)aTimer
{

#if GNUSTEP || GSIMPL_UNDER_COCOA
  #warning Manually creating transaction for implicit animations
  [CATransaction begin];
#endif

  [[self openGLContext] makeCurrentContext];

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);

  glClear(GL_COLOR_BUFFER_BIT);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, [self frame].size.width, 0, [self frame].size.height, -1, 1);
    
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  
  /* */
  [_renderer beginFrameAtTime: CACurrentMediaTime()
                    timeStamp: NULL];
  [_renderer addUpdateRect: [_renderer bounds]];
  [_renderer render];
  [_renderer endFrame];
  /* */
  
  glFlush();

  [[self openGLContext] flushBuffer];
  
  
#if GNUSTEP || GSIMPL_UNDER_COCOA
  #warning Manually committing transaction for implicit animations
  [CATransaction commit];
#endif
}


@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
