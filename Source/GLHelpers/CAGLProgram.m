/* CAGLProgram.m

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

#import "CAGLProgram.h"
#import "CAGLShader.h"

@interface CAGLProgram ()
@property (nonatomic, retain) NSArray * shaders;
@end

@implementation CAGLProgram
@synthesize shaders = _shaders;
@synthesize programID = _programID;
- (id) init
{
  self = [super init];
  if (!self)
    return nil;
  
  _programID = glCreateProgram();
  
  return self;
}

- (id) initWithArrayOfShaders: (NSArray *)shaders
{
  self = [self init];
  if (!self)
    return nil;
  
  [self setShaders: shaders];
  
  return self;
}

- (void) dealloc
{
  [_shaders release];
  glDeleteProgram(_programID);
  
  [super dealloc];
}


/* ************************************* */
/* MARK: Binding, validation and linking */
/* ************************************* */

- (void) bindAttrib: (NSString *)name
         toLocation: (GLuint)location
{
  /* Note: binding must, naturally, be done before linking */
  glBindAttribLocation(_programID, location, [name UTF8String]);
}

- (void) validate
{
  [_shaders makeObjectsPerformSelector: @selector(compile)
                            withObject: nil];

  /* TODO: Make printing logs depend on a user default */
  [_shaders makeObjectsPerformSelector: @selector(printLog)
                            withObject: nil];
    
  [_shaders makeObjectsPerformSelector: @selector(attachToProgram:)
                            withObject: self];
  
  glLinkProgram(_programID);
}
- (GLint) validateStatus
{
  GLint status;
  glGetProgramiv(_programID, GL_LINK_STATUS, &status);
  return status;
}
- (void) printValidateLog
{
  /* Get log, if any */
  NSString * validateLog = [self programLog];
  if (validateLog)
    {
      NSLog(@"GL Program validation log:");
      printf("%s\n", [validateLog UTF8String]);
    }
  
  /* Get validation status */
  if ([self validateStatus] == GL_FALSE)
    {
      NSLog(@"Failed to validate GL program");
    }
}

- (void) link
{
  [_shaders makeObjectsPerformSelector: @selector(compile)
                            withObject: nil];

  /* TODO: Make printing logs depend on a user default */
  [_shaders makeObjectsPerformSelector: @selector(printLog)
                            withObject: nil];
  
  [_shaders makeObjectsPerformSelector: @selector(attachToProgram:)
                            withObject: self];
  
  glLinkProgram(_programID);
}
- (GLint) linkStatus
{
  GLint status;
  glGetProgramiv(_programID, GL_LINK_STATUS, &status);
  return status;
}

- (void) printLinkLog
{
  /* Get log, if any */
  NSString * linkLog = [self programLog];
  if (linkLog)
    {
      NSLog(@"GL Program link log:");
      printf("%s\n", [linkLog UTF8String]);
    }
  
  /* Get link status */
  if ([self linkStatus] == GL_FALSE)
    {
      NSLog(@"Failed to link GL program");
    }
}

/* ***************************************** */
/* MARK: Getting and setting info on program */
/* ***************************************** */

- (NSString *) programLog
{
  GLint logLength;
  glGetProgramiv(_programID, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0)
    {
      GLchar * log = (GLchar *)malloc(logLength);
      glGetProgramInfoLog(_programID, logLength, &logLength, log);
      NSString * logString = [NSString stringWithUTF8String: log];
      free(log);
      return logString;
    }
  
  return nil;
}

- (GLint) locationForUniform: (NSString *)uniform
{
  GLint loc = glGetUniformLocation(_programID, [uniform UTF8String]);
  if (loc == -1)
    NSLog(@"CAGLProgram: Nonexistent uniform: %@", uniform);
  return loc;
}

- (void) bindUniformAtLocation: (GLint)location
                 toUnsignedInt: (GLuint)value
{
  // Can't use glProgramUniform4i() since it's defined in a
  // later OpenGL spec.
  // Use of [self use] modifies state a bit, but that doesn't
  // really matter.
  //glProgramUniform4i(_programID, location, 1, value);
  
  [self use];
  if (location != -1)
    glUniform1i(location, value);
    //glUniform1uiEXT(location, value);
}

- (void) bindUniformAtLocation: (GLint)location
                     toFloat4v: (GLfloat *)array
{
  // Can't use glProgramUniform4fv() since it's defined in a
  // later OpenGL spec.
  // Use of [self use] modifies state a bit, but that doesn't
  // really matter.
  //glProgramUniform4fv(_programID, location, 1, array);
  
  [self use];
  if (location != -1)
    glUniform4fv(location, 1, array);
}


/* ********************** *
 * MARK: Activate program *
 * ********************** */
- (void) use
{
  glUseProgram(_programID);
}

@end
