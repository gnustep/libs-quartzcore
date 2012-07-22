/* CAGLTexture.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: July 2012

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

#import "CAGLTexture.h"

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


@implementation CAGLTexture
@synthesize textureID=_textureID;
@synthesize width=_width;
@synthesize height=_height;

+ (CAGLTexture *) texture
{
  return [[self new] autorelease];
}

- (id) init
{
  self = [super init];
  if (!self)
    return nil;
  
  glGenTextures(1, &_textureID);

  return self;
}

- (void) loadEmptyImageWithWidth: (GLuint)width
                          height: (GLuint)height
{
  /* Used for, for example, renderbuffer's target */
  qcLoadTexImage(GL_RGBA,
    width,
    height,
    GL_RGBA,
    GL_UNSIGNED_BYTE,
    0);

  _width = width;
  _height = height;
}
- (void) loadRGBATexImage: (void *)data
                    width: (GLuint)width
                   height: (GLuint)height
{
  glBindTexture(TEXTURE_TARGET, _textureID);

  qcLoadTexImage(GL_RGBA,
    width,
    height,
    GL_RGBA,
    GL_UNSIGNED_BYTE,
    data);
}

- (void) bind
{
  glEnable(TEXTURE_TARGET);
  glBindTexture(TEXTURE_TARGET, _textureID);
}

- (void) unbind
{
  glBindTexture(TEXTURE_TARGET, 0);
  glDisable(TEXTURE_TARGET);
}

- (GLenum) textureTarget
{
  return TEXTURE_TARGET;
}

@end
