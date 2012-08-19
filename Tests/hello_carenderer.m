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
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#if GSIMPL_UNDER_COCOA
#import <GSQuartzCore/AppleSupportRevert.h>
#endif
#import <AppKit/NSOpenGL.h>

#if !(GSIMPL_UNDER_COCOA)
#import <QuartzCore/CARenderer.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CABase.h>
#else
#import <GSQuartzCore/AppleSupport.h>
#import <GSQuartzCore/CARenderer.h>
#import <GSQuartzCore/CALayer.h>
#import <GSQuartzCore/CABase.h>
#endif

#import "QCTestOpenGLView.h"

@interface HelloCARendererLayerDelegate : NSObject
{
  CGSize _size;
}
- (void) drawLayer: (CALayer*)layer inContext: (CGContextRef)context;
@property (assign) CGSize size;
@end
@implementation HelloCARendererLayerDelegate
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

@interface HelloCARendererOpenGLView : QCTestOpenGLView
{
  CARenderer * _renderer;
  HelloCARendererLayerDelegate * _layerDelegate;
}

- (void) timerAnimation: (NSTimer *)aTimer;

@end

Class classOfTestOpenGLView()
{
  return [HelloCARendererOpenGLView class];
}

@implementation HelloCARendererOpenGLView

- (void) prepareOpenGL
{
  [super prepareOpenGL];

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);
  glClear(GL_COLOR_BUFFER_BIT);

  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);

  _layerDelegate = [HelloCARendererLayerDelegate new];
  [_layerDelegate setSize: CGSizeMake([self frame].size.width, [self frame].size.height)];

  CALayer * layer = [CALayer layer];
  [layer setBounds: CGRectMake(0, 0, [self frame].size.width*0.7, [self frame].size.height*0.7)];
  [layer setPosition: CGPointMake([self frame].size.width/2, [self frame].size.height/2)];
  [layer setTransform: CATransform3DMakeRotation(M_PI_4, 0, 0, 1)];
  [layer setBackgroundColor: yellowColor];
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
  
  CGColorRelease(yellowColor);
}

- (void) dealloc
{
  [_renderer release];
  [_layerDelegate release];
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
  [self clearBounds :[_renderer updateBounds]];
  [_renderer render];
  [_renderer endFrame];
  /* */
  
  {
#if GNUSTEP || GSIMPL_UNDER_COCOA
    // FIXME: this is unneeded under cocoa and should be unnecessary with GS
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glLoadIdentity();
#endif
    glDisable(GL_TEXTURE_2D);
    // Using glBegin() in a small test like this one shouldn't be a problem.
    glBegin(GL_TRIANGLES);
    glColor3f(1.0, 0.0, 0.0);
    glVertex2f(0.0, 0.0);
    glColor3f(0.0, 1.0, 0.0);
    glVertex2f(100.0, 0.0);
    glColor3f(0.0, 0.0, 1.0);
    glVertex2f(100.0, 100.0);
    glEnd();
    
  }
    
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
