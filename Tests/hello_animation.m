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

@interface HelloAnimationCustomBasicAnimation : CABasicAnimation
@end
@implementation HelloAnimationCustomBasicAnimation
@end

@interface HelloAnimationCustomAction : NSObject<CAAction>
@end
@implementation HelloAnimationCustomAction
- (void)runActionForKey:(NSString *)key object:(id)anObject arguments:(NSDictionary *)dict
{
  NSLog(@"running action for key %@ on object %@ with arguments %@", key, anObject, dict);
  CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath: key];
  [(CALayer *)anObject addAnimation: animation forKey: key];
}
@end

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

- (id<CAAction>) actionForLayer: (CALayer *)layer
                         forKey: (NSString *)event
{
  if ([event isEqualToString: @"position"])
    {
      //return [HelloAnimationCustomBasicAnimation animationWithKeyPath: event];

      return [[[HelloAnimationCustomAction alloc] init] autorelease];
    }

  return nil;
}
@end

/* ******************** */

@interface HelloAnimationOpenGLView : QCTestOpenGLView
{
  CARenderer * _renderer;
  HelloAnimationLayerDelegate * _layerDelegate;
  CALayer * _theSublayer;
}

- (void) timerAnimation: (NSTimer *)aTimer;

@end

Class classOfTestOpenGLView()
{
  return [HelloAnimationOpenGLView class];
}

/* *********************** */
@implementation HelloAnimationOpenGLView

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
    [testsMenu addItemWithTitle:@"Animation 6" action:@selector(animation6:) keyEquivalent:@"6"];
    [testsMenu addItemWithTitle:@"Animation 7" action:@selector(animation7:) keyEquivalent:@"7"];
    [testsMenu addItemWithTitle:@"Animation 8" action:@selector(animation8:) keyEquivalent:@"8"];
    [testsMenu addItemWithTitle:@"Set Needs Display" action:@selector(layerSetNeedsDisplay:) keyEquivalent:@"d"];
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
  [[_renderer layer] setPosition: CGPointMake([self frame].size.width/2, [self frame].size.height/2)];
  [self printPos: [_renderer layer]];
  [self performSelector:@selector(printPos:) withObject: [_renderer layer] afterDelay:0.5];
  [CATransaction commit];

}

- (void) animation3:sender
{
  CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position"];
  [animation setDuration: 1];
  [animation setFromValue: [NSValue valueWithPoint: NSMakePoint(400, 150)]];
  [animation setToValue: [NSValue valueWithPoint: NSMakePoint(400, 250)]];
  
  [[_renderer layer] addAnimation: animation forKey:@"thePositionAnimation"];
    
  [self printPos: [_renderer layer]];
  [self performSelector:@selector(printPos:) withObject: [_renderer layer] afterDelay:0.5];
}

- (void) animation4:sender
{
  CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position"];
  [animation setFromValue: [NSValue valueWithPoint: NSMakePoint(0, 0)]];
  [animation setToValue: [NSValue valueWithPoint: NSMakePoint(50, 50)]];
  [animation setDuration: 0.5];
  [animation setAutoreverses: YES];
  [animation setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionDefault]];
  [animation setRepeatCount: 3]; //__builtin_inf()];
  
  [_theSublayer addAnimation: animation forKey:@"repeatingAnimation"];
}

- (void) animation5:sender
{
  static BOOL toggle = NO;
  CALayer * layer = [_renderer layer];
  if (!toggle)
    [layer setTransform: CATransform3DMakeRotation(M_PI_4/2, 0, 0, 1)];
  else
    [layer setTransform: CATransform3DIdentity];
  
  toggle = !toggle;
}

- (void) animation6:sender
{
  CALayer * layer = [_renderer layer];
  [layer setBounds:CGRectMake([layer bounds].origin.x, [layer bounds].origin.y, [layer bounds].size.width + rand() % 50 - 25, [layer bounds].size.height + rand() % 50 - 25)];
}

- (void) animation7:sender
{
  CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform"];
  [animation setFromValue: [NSValue valueWithCATransform3D: [_theSublayer transform]]];
  [animation setToValue: [NSValue valueWithCATransform3D: CATransform3DTranslate(CATransform3DRotate([_theSublayer transform], M_PI, 0, 0, 1), -150, 0, 0)]];
  [animation setDuration: 2];
  [animation setAutoreverses: YES];
  
  [_theSublayer addAnimation: animation forKey: @"doABarrelRoll"];
  
  CABasicAnimation * opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
  [opacity setFromValue: [NSNumber numberWithFloat: [_theSublayer opacity]]];
  [opacity setToValue: [NSNumber numberWithFloat: 0.5]];
  [opacity setDuration: 2];
  [opacity setAutoreverses: YES];
  
  [_theSublayer addAnimation: opacity forKey: @"pulse"];
}

- (void) animation8:sender
{
  static BOOL toggle = NO;
  CALayer * layer = [_renderer layer];
  if (!toggle)
    [layer setOpacity: 0.2];
  else
    [layer setOpacity: 1.0];
  
  toggle = !toggle;
}

- (void) layerSetNeedsDisplay:sender
{
  CALayer * layer = [_renderer layer];
  [layer setNeedsDisplay];
  
  [self printPos: layer];
}


- (void) printPos: (CALayer*)layer
{
#if 1
  CALayer * presLayer = [layer presentationLayer];
  NSLog(@"modelpos: %g %g", [layer position].x, [layer position].y);
  NSLog(@"pres pos: %g %g", [presLayer position].x, [presLayer position].y);
  
  NSLog(@"modelani: %@", [layer animationKeys]);
  for (NSString * ani in [layer animationKeys])
    {
      NSLog(@" %@ %g", [layer animationForKey: ani], [[layer animationForKey: ani] beginTime]);
    }
  NSLog(@"pres ani: %@", [presLayer animationKeys]);
  for (NSString * ani in [presLayer animationKeys])
    {
      NSLog(@" %@ %g", [presLayer animationForKey: ani], [[presLayer animationForKey: ani] beginTime]);
    }
  NSLog(@"--------");
#endif
}

- (void) prepareOpenGL
{
  [super prepareOpenGL];

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);
  glClear(GL_COLOR_BUFFER_BIT);

  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);  
  CGColorRef greenColor = CGColorCreateGenericRGB(0, 1, 0, 1);

  _layerDelegate = [HelloAnimationLayerDelegate new];
  [_layerDelegate setSize: CGSizeMake([self frame].size.width, [self frame].size.height)];

  CALayer * layer = [CALayer layer];
  [layer setBounds: CGRectMake(0, 0, [self frame].size.width*0.6, [self frame].size.height*0.6)];
  [layer setPosition: CGPointMake([self frame].size.width/2, [self frame].size.height/2)];
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
  
  CALayer * layer2 = [CALayer layer];
  [layer2 setDelegate: _layerDelegate];
  [layer2 setBounds: CGRectMake (0, 0, 100, 100)];
  [layer2 setBackgroundColor: greenColor];
  [layer2 setSpeed: 2];
  /*
  [layer2 setDuration: __builtin_inf()];
  [layer2 setBeginTime: CACurrentMediaTime()*[layer speed]+1];
  */
  [layer2 setBeginTime: 1];
  [layer setBeginTime: 1];
  [layer2 setNeedsDisplay];
  [layer addSublayer: layer2];
  _theSublayer = [layer2 retain];
  
  [layer setSublayerTransform: CATransform3DMakeRotation(M_PI_2 * 0.25 /* 45 deg */, 0, 0, 1)];

  CGColorRelease(yellowColor);
  CGColorRelease(greenColor);
}

- (void) dealloc
{
  [_theSublayer removeFromSuperlayer];
  [_theSublayer release];
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
  
  #if 0
  NSLog(@"Time conversion of layer: %g %g", CACurrentMediaTime(), [[_renderer layer] convertTime: CACurrentMediaTime() fromLayer: nil]);
  NSLog(@"Time conversion of sublayer: %g", [_theSublayer convertTime: CACurrentMediaTime() fromLayer: nil]);
  #endif
  /* */
  [_renderer beginFrameAtTime: CACurrentMediaTime()
                    timeStamp: NULL];
  [self clearBounds: [_renderer updateBounds]];
  [_renderer render];
  [_renderer endFrame];
  /* */
  #if 0
  NSLog(@"Time conversion of layer - postrender: %g %g", CACurrentMediaTime(), [[_renderer layer] convertTime: CACurrentMediaTime() fromLayer: nil]);
  NSLog(@"Time conversion of sublayer to layer - postrender: %g", [_theSublayer convertTime: CACurrentMediaTime() fromLayer: [_renderer layer]]);
  
  NSLog(@"Experimenting: %g", [[_renderer layer] convertTime: CACurrentMediaTime() toLayer: _theSublayer]);
  if ([[[_renderer layer] animationKeys] count])
    NSLog(@"Experimenting2: %g", [[[_renderer layer] animationForKey:[[[_renderer layer] animationKeys] objectAtIndex:0]] beginTime]);
  #endif
  
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
