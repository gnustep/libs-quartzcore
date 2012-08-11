/* 
   CARenderer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: March 2012

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
#import "QuartzCore/CARenderer.h"
#import "QuartzCore/CATransform3D.h"
#import "QuartzCore/CALayer.h"
#import "CALayer+FrameworkPrivate.h"
#import "CABackingStore.h"
#if !(__APPLE__)
#import <GL/gl.h>
#import <GL/glu.h>
#else
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#endif
#import <AppKit/NSOpenGL.h>

#import "GLHelpers/CAGLTexture.h"
#import "GLHelpers/CAGLSimpleFramebuffer.h"
#import "GLHelpers/CAGLShader.h"
#import "GLHelpers/CAGLProgram.h"

#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

@interface CARenderer()
@property (assign) NSOpenGLContext *GLContext;
- (void) _determineAndScheduleRasterizationForLayer: (CALayer *) layer;
- (void) _scheduleRasterization: (CALayer *) layer;
@end

@implementation CARenderer
@synthesize layer=_layer;
@synthesize bounds=_bounds;

@synthesize GLContext=_GLContext;

/* *** class methods *** */
/* Creates a renderer which renders into an OpenGL context. */
+ (CARenderer*) rendererWithNSOpenGLContext: (NSOpenGLContext*)ctx
                                    options: (NSDictionary*)options;
{
  return [[[self alloc] initWithNSOpenGLContext: ctx 
	                                options: options] autorelease];
}

/* *** methods *** */

- (id) initWithNSOpenGLContext: (NSOpenGLContext*)ctx
                       options: options
{
  if ((self = [super init]) != nil)
    {
      [self setGLContext: ctx];
      
      /* Set up shaders */
      [ctx makeCurrentContext];
      CAGLVertexShader * simpleVS = [CAGLVertexShader alloc];
      simpleVS = [simpleVS initWithFile: @"simple"
                                 ofType: @"vsh"];
      CAGLFragmentShader * simpleFS = [CAGLFragmentShader alloc];
      simpleFS = [simpleFS initWithFile: @"simple"
                                 ofType: @"fsh"];
      NSArray * objectsForSimpleShader = [NSArray arrayWithObjects: simpleVS, simpleFS, nil];
      [simpleVS release];
      [simpleFS release];

      CAGLProgram * simpleProgram = [CAGLProgram alloc];
      simpleProgram = [simpleProgram initWithArrayOfShaders: objectsForSimpleShader];
      [simpleProgram link];
      _simpleProgram = simpleProgram;
    }
  return self;
}

- (void) dealloc
{
  [_layer release];
  [_rasterizationSchedule release];
  
  /* Release all GL programs */
  [_simpleProgram release];
  
  [super dealloc];
}

/* Adds a rectangle to the update region. */
- (void) addUpdateRect: (CGRect)updateRect
{
}

/* Begins rendering a frame at the specified time.
   Timestamp is currently ignored. */
- (void) beginFrameAtTime: (CFTimeInterval)timeInterval
                timeStamp: (CVTimeStamp *)timeStamp
{
  if (!_firstRender)
    {
      _firstRender = timeInterval;
      return;
    }
  
  /* Prepare for rasterization */
  [_rasterizationSchedule release];
  _rasterizationSchedule = [[NSMutableArray alloc] init];
  
  /* Update layers (including determining and scheduling rasterization) */
  [self _updateLayer: _layer atTime: timeInterval];
  
  /* Rasterize */
  for (NSDictionary * rasterizationSpec in _rasterizationSchedule)
  {
    [self _rasterize: rasterizationSpec];
  }
  
  /* Release rasterization schedule */
  [_rasterizationSchedule release];
  _rasterizationSchedule = nil;
}

/* Ends rendering the frame, releasing any temporary data. */
- (void) endFrame
{
}
/* Returns time at which next update should be performed.
   Current time denotes continuous animation and next update
   should be scheduled as soon as appropriate. Infinity denotes
   that no update should be scheduled. */
- (CFTimeInterval) nextFrameTime
{
  return CACurrentMediaTime();
}

/* Renders a frame to the target context. Best case scenario, it 
   should be rendering the update region only. */
- (void) render
{
  // FIXME: [glcontext setcurrent]

  glMatrixMode(GL_MODELVIEW);

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  [self _renderLayer: [[self layer] presentationLayer]
       withTransform: CATransform3DIdentity];
}


/* Returns rectangle containing all pixels that should be updated. */
- (CGRect) updateBounds
{
  // TODO update bounds are currently unused
  return CGRectZero;
}

/* *********************** */
/* MARK: - Private methods */

/* Internal method that updates a single presentation layer and then proceeds by recursing, updating its children. */
- (void) _updateLayer: (CALayer *)layer
               atTime: (CFTimeInterval)theTime
{
  if ([layer modelLayer])
    layer = [layer modelLayer];

  [CALayer setCurrentFrameBeginTime: theTime];
  
  /* Destroy and then recreate the presentation layer.
     This is the easiest way to reset it to default values. */
  [layer discardPresentationLayer];
  CALayer * presentationLayer = [layer presentationLayer];
  
  /* Tell the presentation layer to apply animations. */
  [presentationLayer applyAnimationsAtTime: theTime];
  
  /* Tell all children to update themselves. */
  for (CALayer * sublayer in [layer sublayers])
    {
      [self _updateLayer: sublayer
                  atTime: theTime];
    }

  /* Now that children have had a chance to suffer determining
     whether they need to be rendered offscreen, the layer itself
     can suffer it, too. */
  /* (Order is important, because the deeper the layer is, earlier
     it needs to be offscreen-rendered.) */
     
  /* TODO: */
  /* First, allow mask layer to determine this, since it's deeper than
     the current layer. */
  #if 0
  [self _determineAndScheduleRasterizationForLayer: [layer mask]];
  #endif
  
  /* Then determine current layer to determine rasterization */
  [self _determineAndScheduleRasterizationForLayer: layer];
}
/* Internal method that renders a single layer and then proceeds by recursing, rendering its children. */
- (void) _renderLayer: (CALayer *)layer
        withTransform: (CATransform3D)transform
{
  if (![layer isPresentationLayer])
    layer = [layer presentationLayer];
  
      
  // if the layer was offscreen-rendered, render just the texture
  // TODO Layers need a way to store framebuffer-rendered texture apart from CABackingStore in [layer contents]
  if ([[layer contents] isKindOfClass:[CABackingStore class]])
    {
      CAGLTexture * texture = [[layer contents] offscreenRenderTexture];
      if (texture)
        {
          transform = CATransform3DTranslate(transform, [layer position].x, [layer position].y, 0);
          if (sizeof(transform.m11) == sizeof(GLdouble))
            glLoadMatrixd((GLdouble*)&transform);
          else
            glLoadMatrixf((GLfloat*)&transform);

          #warning Intentionally coloring offscreen-rendered layer
          glColor3f(0.4, 1.0, 1.0);
          
          #warning Intentionally applying shader to offscreen-rendered layer
          [_simpleProgram use];
          GLint loc = [_simpleProgram locationForUniform:@"texture_2drect"];
          
          [_simpleProgram bindUniformAtLocation: loc
                                  toUnsignedInt: 0];//[texture textureID]];
          
          
          // TODO: replace use of glBegin()/glEnd()
          [texture bind];
          glBegin(GL_QUADS);
          glTexCoord2f(0, 0);
          glVertex2f(-256, -256);
          glTexCoord2f(0, 512);
          glVertex2f(-256, 256);
          glTexCoord2f(512, 512);
          glVertex2f(256, 256);
          glTexCoord2f(512, 0);
          glVertex2f(256, -256);
          glEnd();
          glDisable([texture textureTarget]);
          
          #warning Intentionally coloring offscreen-rendered layer
          glColor3f(1.0, 1.0, 1.0);
          #warning Intentionally applying shader to offscreen-rendered layer
          glUseProgram(0);
          
          return;
        }
    }

  
  // apply transform and translate to position
  transform = CATransform3DTranslate(transform, [layer position].x, [layer position].y, 0);
  transform = CATransform3DConcat([layer transform], transform);
  
  if (sizeof(transform.m11) == sizeof(GLdouble))
    glLoadMatrixd((GLdouble*)&transform);
  else
    glLoadMatrixf((GLfloat*)&transform);

  [layer displayIfNeeded];

  // fill vertex arrays
  GLfloat vertices[] = {
    0.0, 0.0,
    [layer bounds].size.width, 0.0,
    [layer bounds].size.width, [layer bounds].size.height,
    
    [layer bounds].size.width, [layer bounds].size.height,
    0.0, [layer bounds].size.height,
    0.0, 0.0,
  };
  CGRect cr = [layer contentsRect];
  GLfloat texCoords[] = {
    cr.origin.x,                 1.0 - (cr.origin.y),
    cr.origin.x + cr.size.width, 1.0 - (cr.origin.y),
    cr.origin.x + cr.size.width, 1.0 - (cr.origin.y + cr.size.height),
    
    cr.origin.x + cr.size.width, 1.0 - (cr.origin.y + cr.size.height),
    cr.origin.x,                 1.0 - (cr.origin.y + cr.size.height),
    cr.origin.x,                 1.0 - (cr.origin.y),
  };
  GLfloat whiteColor[] = {
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
  };
  GLfloat backgroundColor[] = {
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
  };
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
  
  // apply anchor point
  for (int i = 0; i < 6; i++)
    {
      vertices[i*2 + 0] -= [layer anchorPoint].x * [layer bounds].size.width;
      vertices[i*2 + 1] -= [layer anchorPoint].y * [layer bounds].size.height;
    }

  // apply opacity to white color
  for (int i = 0; i < 6; i++)
    {
        whiteColor[i*4 + 3] *= [layer opacity];
    }

  // apply background color
  if ([layer backgroundColor] && CGColorGetAlpha([layer backgroundColor]) > 0)
    {
      const CGFloat * componentsCG = CGColorGetComponents([layer backgroundColor]);
      GLfloat components[4];
      
      // convert
      components[0] = componentsCG[0];
      components[1] = componentsCG[1];
      components[2] = componentsCG[2];
      components[3] = componentsCG[3];
      
      // apply opacity
      components[3] *= [layer opacity];
      
      // FIXME: here we presume that color contains RGBA channels.
      // However this may depend on colorspace, number of components et al
      memcpy(backgroundColor + 0*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 1*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 2*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 3*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 4*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 5*4, components, sizeof(GLfloat)*4);
      glColorPointer(4, GL_FLOAT, 0, backgroundColor);
      
      glDrawArrays(GL_TRIANGLES, 0, 6);
    }

  // if there are some contents, draw them
  if ([layer contents])
    {
      CAGLTexture * texture = nil;
      
      if ([[layer contents] isKindOfClass: [CABackingStore class]])
        {
          CABackingStore * layerContents = ((CABackingStore *)[layer contents]);

          texture = [layerContents contentsTexture];
        }
#if !(GSIMPL_UNDER_COCOA)
      else if ([[layer contents] isKindOfClass: [CGImage class]])
        {
          // TODO
        }
#endif
      
      if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
        {
          /* Rectangle textures use non-normalized coordinates. */
          
          for (int i = 0; i < 6; i++)
            {
              texCoords[i*2 + 0] *= [texture width];
              texCoords[i*2 + 1] *= [texture height];
            }
        }
      
      [texture bind];
      glColorPointer(4, GL_FLOAT, 0, whiteColor);
      glDrawArrays(GL_TRIANGLES, 0, 6);
      [texture unbind];

    }

  transform = CATransform3DConcat ([layer sublayerTransform], transform);
  transform = CATransform3DTranslate (transform, -[layer bounds].size.width/2, -[layer bounds].size.height/2, 0);
  for (CALayer * sublayer in [layer sublayers])
    {
      [self _renderLayer: sublayer withTransform: transform];
    }
}

- (void) _determineAndScheduleRasterizationForLayer: (CALayer*)layer
{
  BOOL shouldRasterize = NO;
  /* Whether a layer needs to be rasterized is complex to determine,
     but the first thing to check is user-specifiable property
     'shouldRasterize'. */
  if (!shouldRasterize && [[layer presentationLayer] shouldRasterize])
    {
      shouldRasterize = YES;
    }
  
  
  /* Now, based on results, either rasterize or invalidate rasterization */
  if (shouldRasterize)
    [self _scheduleRasterization: layer];
  else
    {
      // TODO
      #warning Layers need a way to store framebuffer-rendered texture apart from CABackingStore in [layer contents]
      if ([[layer contents] isKindOfClass:[CABackingStore class]])
        {
          [[layer contents] setOffscreenRenderTexture: nil];
        }
    }
  
}

- (void) _scheduleRasterization: (CALayer *)layer
{
  NSMutableDictionary * rasterizationSpec = [NSMutableDictionary new];
  
  [rasterizationSpec setValue: layer forKey: @"layer"];
  [_rasterizationSchedule addObject: rasterizationSpec];
  [rasterizationSpec release];
}

- (void) _rasterize: (NSDictionary*) rasterizationSpec
{
  CALayer * layer = [rasterizationSpec valueForKey: @"layer"];

  /* we need to render the presentationLayer */
  if (![layer isPresentationLayer])
    layer = [layer presentationLayer];

  // TODO Layers need a way to store framebuffer-rendered texture apart from CABackingStore in [layer contents]
  if ([[layer contents] isKindOfClass:[CABackingStore class]])
    {
      /* Empty the cache so redraw gets performed in -[CARenderer _renderLayer:withTransform:] */
      [[layer contents] setOffscreenRenderTexture: nil];
    }

  // TODO: 512x512 is NOT correct, we need to determine the actual layer size together with sublayers
  const GLuint rasterize_w = 512, rasterize_h = 512;
  CAGLSimpleFramebuffer * framebuffer = [[CAGLSimpleFramebuffer alloc] initWithWidth: rasterize_w height: rasterize_h];
  [framebuffer setDepthBufferEnabled: YES];
  [framebuffer bind];
  
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  glDisable([[framebuffer texture] textureTarget]);
  
  [self _renderLayer: layer withTransform: CATransform3DMakeTranslation(rasterize_w/2.0 - [layer position].x, rasterize_h/2.0 - [layer position].y, 0)];
  
  [framebuffer unbind];
  
  // TODO Layers need a way to store framebuffer-rendered texture apart from CABackingStore in [layer contents]
  if ([[layer contents] isKindOfClass:[CABackingStore class]])
    {
      [[layer contents] setOffscreenRenderTexture: [framebuffer texture]];
    }
  
  [framebuffer release];
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
