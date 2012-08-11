/* CAGLShader.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: August 2012

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

@interface CAGLShader : NSObject
{
  NSString * _source;
  GLuint _shaderID;
  
  /* 'compiled' prevents multiple compiles for same program.
     It's not updated if 'source' is changed (which we don't
     support anyway -- shader is mostly an immutable object,
     especially having been compiled. */
  BOOL _compiled;
}
@property (nonatomic, retain, readonly) NSString * source;
@property (nonatomic, assign, readonly) GLuint shaderID;

- (id) initWithFile: (NSString*)file
             ofType: (NSString*)type;
- (void) compile;
- (void) printLog;
- (GLint) compileStatus;
- (NSString *) shaderLog;

- (GLenum) shaderType;
@end

@interface CAGLVertexShader : CAGLShader
{
}
- (GLenum) shaderType;
@end

@interface CAGLFragmentShader : CAGLShader
{
}
- (GLenum) shaderType;
@end

