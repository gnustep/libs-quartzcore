/* Tests/hello_opal.m

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
#import <OpenGL/OpenGL.h>
#endif
#import <AppKit/NSOpenGL.h>
#import <CoreGraphics/CoreGraphics.h>
#import <cairo/cairo.h>

#import "QCTestOpenGLView.h"

#define USE_RECT 0
#if USE_RECT
/* FIXME: Use of rectangle textures is broken */
#define TEXTURE_TARGET GL_TEXTURE_RECTANGLE_ARB
#else
#define TEXTURE_TARGET GL_TEXTURE_2D
#endif

/* This needs to become a public interface of Opal! */
CGContextRef opal_new_CGContext(cairo_surface_t *target, CGSize device_size);

@interface HelloOpalOpenGLView : QCTestOpenGLView
{
  cairo_surface_t * _cairoSurface;
  CGContextRef _opalContext;
  GLuint _texture;
}

- (void) timerAnimation: (NSTimer *)aTimer;
- (void) dumpXPM: (unsigned char *)data width: (int)width height: (int)height;

@end

Class classOfTestOpenGLView()
{
  return [HelloOpalOpenGLView class];
}

@implementation HelloOpalOpenGLView

- (void) prepareOpenGL
{
  [super prepareOpenGL];
  int width = [self frame].size.width;
  int height = [self frame].size.height;

  /* We could use CGBitmapContext, but for sake of this test/example... */
  _cairoSurface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
  _opalContext = opal_new_CGContext(_cairoSurface, CGSizeMake(width, height));
  
  /* Draw some content into the context */
  CGRect rect = CGRectMake(50, 50, width/2.0, height/2.0);
  CGContextSetRGBStrokeColor(_opalContext, 0, 0, 1, 1);
  CGContextSetRGBFillColor(_opalContext, 1, 0, 0, 1);
  CGContextSetLineWidth(_opalContext, 4.0);
  CGContextStrokeRect(_opalContext, rect);
  CGContextFillRect(_opalContext, rect);
#if 0
#if !GNUSTEP
  CGContextFlush(_opalContext);
#else
  /* Under X11, opal tries to be smart and tries to XFlush() */
  /* This breaks on contexts which are not backed by an X11 drawable */
  cairo_surface_flush(_cairoSurface);
#endif
#endif

  /* Get this content into an OpenGL texture */
  glGenTextures(1, &_texture);
  glBindTexture(TEXTURE_TARGET, _texture);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  unsigned char * data = cairo_image_surface_get_data(_cairoSurface);
#if USE_RECT
  glTexImage2D(TEXTURE_TARGET, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
#else
  gluBuild2DMipmaps(TEXTURE_TARGET, GL_RGBA, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
#endif

  /* [self dumpXPM: data width: width height: height]; */
}

- (void) dealloc
{
  cairo_surface_finish(_cairoSurface);
  CGContextRelease(_opalContext);

  [super dealloc];
}

- (void) timerAnimation: (NSTimer *)aTimer
{
  [[self openGLContext] makeCurrentContext];

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);
 
  glClear(GL_COLOR_BUFFER_BIT);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  /* glOrtho(0, 0, [self frame].size.width, [self frame].size.height, -1, 1); */

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  glEnable(GL_TEXTURE_2D);
  glEnable(TEXTURE_TARGET);
  glBindTexture(TEXTURE_TARGET, _texture);
  glColor3f(1,1,1);

  /* Using glBegin() in a small test like this one shouldn't be a problem. */
  glBegin(GL_QUADS);
  glTexCoord2f(0.0, 1.0);
  glVertex2f(-1.0, -1.0);

  glTexCoord2f(0.0, 0.0);
  glVertex2f(-1.0, 1.0);

  glTexCoord2f(1.0, 0.0);
  glVertex2f(1.0, 1.0);

  glTexCoord2f(1.0, 1.0);
  glVertex2f(1.0, -1.0);
  glEnd();

  [[self openGLContext] flushBuffer];
}


/* ----------- */

- (void) dumpXPM: (unsigned char *)data width: (int)width height: (int)height
{
  /* Used in debugging. Writes XPM with white pixels 
     that otherwise have red byte set to something 
     other than zero. */

  FILE * f = fopen("/tmp/test.xpm", "w");
  fputs("/* XPM */\n", f);
  fputs("static char * test_xpm[] = {\n", f);
  fprintf(f, "\"%d %d 2 1\",\n", width, height);
  fputs("\" \tc #000000\",\n", f);
  fputs("\"c\tc #FFFFFF\",\n", f);
  for(int i = 0; i < height; i++)
    {
      fputc('"', f);
      for(int j = 0; j < width; j++)
	fputc((data[(i*width + j)*4]>0 ? 'c' : ' '), f);

      if(i != height-1)
	fputs("\",\n", f);
      else
	fputc('"', f);
    }
  fputs("};", f);

  fclose(f);

}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
