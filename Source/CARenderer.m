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
#import "GLHelpers/CAGLTexture.h"

#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

@interface CARenderer()
@property (assign) NSOpenGLContext *GLContext;
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
    }
  return self;
}

- (void) dealloc
{
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
  [self _updateLayer: _layer atTime: timeInterval];
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
}
/* Internal method that renders a single layer and then proceeds by recursing, rendering its children. */
- (void) _renderLayer: (CALayer *)layer
        withTransform: (CATransform3D)transform
{
  if ([layer presentationLayer])
    layer = [layer presentationLayer];
  
  [layer displayIfNeeded];

  // apply transform and translate to position
  transform = CATransform3DTranslate(transform, [layer position].x, [layer position].y, 0);
  transform = CATransform3DConcat([layer transform], transform);
  
  if (sizeof(transform.m11) == sizeof(GLdouble))
    glLoadMatrixd((GLdouble*)&transform);
  else
    glLoadMatrixf((GLfloat*)&transform);

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

          texture = [layerContents texture];
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

/* Returns rectangle containing all pixels that should be updated. */
- (CGRect) updateBounds
{
  // TODO update bounds are currently unused
  return CGRectZero;
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
