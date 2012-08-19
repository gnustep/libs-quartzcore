/* CAGLTexture.h

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

#import <Foundation/Foundation.h>
#if (__APPLE__)
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#else
#import <GL/gl.h>
#import <GL/glu.h>
#endif

@interface CAGLTexture : NSObject
{
  GLuint _textureID;
  GLint _width;
  GLint _height;
}

@property (readonly) GLuint textureID;
@property (readonly) GLint width;
@property (readonly) GLint height;

+ (CAGLTexture *) texture;

- (void) loadEmptyImageWithWidth: (GLuint)width
                          height: (GLuint)height;
- (void) loadImage: (CGImageRef) image;
- (void) loadRGBATexImage: (void *)data
                    width: (GLuint)width
                   height: (GLuint)height;

- (void) bind;
- (void) unbind;

- (GLenum) textureTarget;
@end
