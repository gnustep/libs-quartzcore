/* CAGLProgram.h

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

@interface CAGLProgram : NSObject
{
  NSArray * _shaders;
  GLuint _programID;
}

@property (nonatomic, retain, readonly) NSArray * shaders;
@property (nonatomic, assign, readonly) GLuint programID;

- (id) initWithArrayOfShaders: (NSArray *)shaders;
- (void) bindAttrib: (NSString *)name
         toLocation: (GLuint)location;
         
- (void) validate;
- (GLint) validateStatus;
- (void) printValidateLog;

- (void) link;
- (GLint) linkStatus;
- (void) printLinkLog;

- (NSString *) programLog;
- (void) bindUniformAtLocation: (GLint)location
                 toUnsignedInt: (GLuint)value;
- (void) bindUniformAtLocation: (GLint)location
                     toFloat4v: (GLfloat *)array;

- (GLint) locationForUniform: (NSString *)uniform;
- (void) use;

@end
