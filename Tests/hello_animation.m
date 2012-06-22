/* Tests/hello_carenderer.m

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
#else
#import <GSQuartzCore/AppleSupport.h>
#import <GSQuartzCore/CARenderer.h>
#import <GSQuartzCore/CALayer.h>
#import <GSQuartzCore/CABase.h>
#import <GSQuartzCore/CATransaction.h>
#endif

#import "QCTestOpenGLView.h"

@interface HelloAnimationLayerDelegate : NSObject
{
  CGSize _size;
}
- (void) drawLayer: (CALayer*)layer inContext: (CGContextRef)context;
@property (assign) CGSize size;
@end
@implementation HelloAnimationLayerDelegate
@synthesize size=_size;
- (void) drawLayer: (CALayer*)layer inContext: (CGContextRef)context
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

@interface HelloAnimationOpenGLView : QCTestOpenGLView
{
  CARenderer * _renderer;
  HelloAnimationLayerDelegate * _layerDelegate;
}

- (void) timerAnimation: (NSTimer *)aTimer;

@end

Class classOfTestOpenGLView()
{
  return [HelloAnimationOpenGLView class];
}

@implementation HelloAnimationOpenGLView

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)viewDidMoveToSuperview
{
  [super viewDidMoveToSuperview];

  NSMenu * mainMenu = [[NSApplication sharedApplication] mainMenu];
  
  NSMenuItem * testsMenuItem = [[NSMenuItem alloc] init];
  NSMenu * testsMenu = [[NSMenu alloc] initWithTitle:@"Tests"];
  {
    [testsMenu addItemWithTitle:@"Animation 1" action:@selector(animation1:) keyEquivalent:@"1"];
    [testsMenu addItemWithTitle:@"Animation 2" action:@selector(animation2:) keyEquivalent:@"2"];
  }
  
  [testsMenuItem setSubmenu:testsMenu];
  [testsMenu release];
  
  [mainMenu insertItem:testsMenuItem atIndex:1];
  [testsMenuItem release];
  
}

- (void) animation1:sender
{
  [[_renderer layer] setPosition: CGPointZero];
}

- (void) animation2:sender
{
  [CATransaction begin];
  [CATransaction setAnimationDuration:1];
  [[_renderer layer] setPosition: CGPointMake(50, 50)];
  [self printPos: [_renderer layer]];
  [self performSelector:@selector(printPos:) withObject: [_renderer layer] afterDelay:0.5];
  [CATransaction commit];

}
- (void) printPos: (CALayer*)layer
{
  CALayer * presLayer = [layer presentationLayer];
  NSLog(@"modelpos: %g %g", [layer position].x, [layer position].y);
  NSLog(@"pres pos: %g %g", [presLayer position].x, [presLayer position].y);
  
  NSLog(@"modelani: %@", [layer animationKeys]);
  for(NSString * ani in [layer animationKeys])
    {
      NSLog(@" %@ - %s", [layer animationForKey: ani], [[layer animationForKey: ani] isEnabled] ? "enabled" : "disabled");
    }
  NSLog(@"pres ani: %@", [presLayer animationKeys]);
  for(NSString * ani in [layer animationKeys])
    {
      NSLog(@" %@ - %s", [presLayer animationForKey: ani], [[presLayer animationForKey: ani] isEnabled] ? "enabled" : "disabled");
    }
  NSLog(@"--------");
}

- (void) prepareOpenGL
{
  [super prepareOpenGL];

  _layerDelegate = [HelloAnimationLayerDelegate new];
  [_layerDelegate setSize: CGSizeMake([self frame].size.width, [self frame].size.height)];

  CALayer * layer = [CALayer layer];
  [layer setBounds: CGRectMake(0, 0, [self frame].size.width*0.7, [self frame].size.height*0.7)];
  [layer setPosition: CGPointMake([self frame].size.width/2, [self frame].size.height/2)];
  [layer setTransform: CATransform3DMakeRotation(M_PI_4, 0, 0, 1)];
  [layer setBackgroundColor: CGColorCreateGenericRGB(1, 1, 0, 1)];
  [layer setDelegate: _layerDelegate];
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
}

- (void) dealloc
{
  [_renderer release];
  [_layerDelegate release];
  [super dealloc];
}

- (void) timerAnimation: (NSTimer *)aTimer
{
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
  [_renderer addUpdateRect:[_renderer bounds]];
  [_renderer render];
  [_renderer endFrame];
  /* */
      
  glFlush();

  [[self openGLContext] flushBuffer];
}


@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
