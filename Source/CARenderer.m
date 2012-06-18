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
#if !(__APPLE__)
#import <GL/gl.h>
#import <GL/glu.h>
#else
#import <OpenGL/OpenGL.h>
#endif
#import <CoreGraphics/CoreGraphics.h>
#import <cairo/cairo.h>

#define USE_RECT 0
#if USE_RECT
/* FIXME: Use of rectangle textures is broken */
#define TEXTURE_TARGET GL_TEXTURE_RECTANGLE_ARB
#define qcLoadTexImage(channels, width, height, format, type, data) \
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, channels, \
                     width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE\
                     data)

#else
#define TEXTURE_TARGET GL_TEXTURE_2D
#define qcLoadTexImage(channels, width, height, format, type, data) \
        gluBuild2DMipmaps(GL_TEXTURE_2D, channels, width, height, format, type, data)
#endif

@interface CARenderer()
@property (assign) NSOpenGLContext *GLContext;
@end

/* FIXME:
   CGContext @interface has been COPIED from opal.
   This is wrong.
   The only reason why we need this is to get the cairo context
   from a CGContextRef.
   */
/* ********************************** */
typedef struct ct_additions ct_additions;
@interface CGContext : NSObject
{
@public
  cairo_t *ct;  /* A Cairo context -- destination of this CGContext */
  ct_additions *add;  /* Additional things not in Cairo's gstate */
  CGAffineTransform txtmatrix;
  CGFloat scale_factor;
  CGSize device_size;
}
- (id) initWithSurface: (cairo_surface_t *)target size: (CGSize)size;
@end
/* ************************************ */
/* END FIXME */

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
  if((self = [super init]) != nil)
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
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GREATER, 0.5);

  [self _renderLayer: [self layer]
       withTransform: CATransform3DIdentity];
}

/* Internal method that renders only a single layer. */
- (void) _renderLayer: (CALayer *)layer
        withTransform: (CATransform3D)transform
{
  [layer displayIfNeeded];

  // apply transform and translate to position
  transform = CATransform3DTranslate(transform, [layer position].x, [layer position].y, 0);
  transform = CATransform3DConcat([layer transform], transform);
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
  GLfloat texCoords[] = {
    0.0, 1.0,
    1.0, 1.0,
    1.0, 0.0,
    
    1.0, 0.0,
    0.0, 0.0,
    0.0, 1.0
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
  for(int i = 0; i < 6; i++)
    {
      vertices[i*2 + 0] -= [layer anchorPoint].x * [layer bounds].size.width;
      vertices[i*2 + 1] -= [layer anchorPoint].y * [layer bounds].size.height;
    }

  // apply background color
  if([layer backgroundColor] && CGColorGetAlpha([layer backgroundColor]) > 0)
    {
      const CGFloat * components = CGColorGetComponents([layer backgroundColor]);
      // FIXME: here we presume that color contains RGBA channels.
      // However this may depend on colorspace, number of components et al
      memcpy(backgroundColor + 0*4, components, sizeof(CGFloat)*4);
      memcpy(backgroundColor + 1*4, components, sizeof(CGFloat)*4);
      memcpy(backgroundColor + 2*4, components, sizeof(CGFloat)*4);
      memcpy(backgroundColor + 3*4, components, sizeof(CGFloat)*4);
      memcpy(backgroundColor + 4*4, components, sizeof(CGFloat)*4);
      memcpy(backgroundColor + 5*4, components, sizeof(CGFloat)*4);
      glColorPointer(4, GL_FLOAT, 0, backgroundColor);
      
      glDisable(TEXTURE_TARGET);
      glDrawArrays(GL_TRIANGLES, 0, 6);
    }

  // if there are some contents, draw them
  if([layer contents])
    {
      /* FIXME: should cache textures of layers, and update them
         only if needed */
      GLuint texture;
      glGenTextures(1, &texture);
      glBindTexture(TEXTURE_TARGET, texture);
      if([[layer contents] isKindOfClass: [CGContext class]])
        {
          CGContext * layerContents = [layer contents];

          glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
          cairo_surface_t * cairoSurface = cairo_get_target(layerContents->ct);
          qcLoadTexImage(GL_RGBA,
                         cairo_image_surface_get_width(cairoSurface),
                         cairo_image_surface_get_height(cairoSurface),
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         cairo_image_surface_get_data(cairoSurface));
 
	}
      else if ([[layer contents] isKindOfClass: [CGImage class]])
	{
	  // TODO
	}

      /* FIXME: at the very least, replace glBegin()/glEnd() 
         with vertex arrays */
      
      glEnable(TEXTURE_TARGET);
      glColorPointer(4, GL_FLOAT, 0, whiteColor);
      glDrawArrays(GL_TRIANGLES, 0, 6);

      glDeleteTextures(1, &texture);
    }

  // TODO render sublayers
}

/* Returns rectangle containing all pixels that should be updated. */
- (CGRect) updateBounds
{
  // TODO update bounds are currently unused
  return CGRectZero;
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
