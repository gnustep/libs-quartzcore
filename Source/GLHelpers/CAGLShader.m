/* CAGLShader.m

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

#import "CAGLShader.h"
#import "CAGLProgram.h"

@interface CAGLShader ()
@property (nonatomic, retain) NSString * source;
@end


@implementation CAGLShader
@synthesize source = _source;
@synthesize shaderID = _shaderID;

- (id) init
{
  self = [super init];
  if (!self)
    return nil;
  
  _shaderID = glCreateShader([self shaderType]);
  
  return self;
}

- (id) initWithFile: (NSString*)file
             ofType: (NSString*)type
{
  self = [self init];
  if (!self)
    return nil;

  /* Find path to file with source */
  NSBundle * bundle = [NSBundle bundleForClass: [self class]];
  NSString * filePath = [bundle pathForResource: file
                                         ofType: type];
  if (!filePath)
    {
      [self release];
      return nil;
    }
  
  /* Find source file */
  NSString * source = [NSString stringWithContentsOfFile: filePath
                                                encoding: NSUTF8StringEncoding
                                                   error: nil];
  if (!source)
    {
      [self release];
      return nil;
    }
  [self setSource: source];
  
  return self;
}

- (void) dealloc
{
  [_source release];
  glDeleteShader(_shaderID);
  [super dealloc];
}

- (GLenum) shaderType
{
  NSLog(@"Warning: %@ does not override %@ from CAGLShader", [self class], NSStringFromSelector(_cmd));
  return 0;
}

- (void) compile
{
  if (_compiled)
    return;
  
  _compiled = YES;
  
  /* Upload the shader to the GPU */
  const GLchar * source = [_source UTF8String];
  glShaderSource(_shaderID,
                 1,
                 &source,
                 NULL);
  
  /* Compile the shader */
  glCompileShader(_shaderID);

}

- (void) printLog
{
  /* Get log, if any */
  NSString * compileLog = [self shaderLog];
  if (compileLog)
    {
      NSLog(@"Shader compile log:");
      printf("%s\n", [compileLog UTF8String]);
    }
  
  /* Get compile status */
  if ([self compileStatus] == GL_FALSE)
    {
      NSLog(@"Failed to compile shader");
    }
}

- (GLint) compileStatus
{
  GLint status;
  glGetShaderiv(_shaderID, GL_COMPILE_STATUS, &status);
  return status;
}

- (NSString *) shaderLog
{
  GLint logLength;
  glGetShaderiv(_shaderID, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0)
    {
      GLchar * log = (GLchar *)malloc(logLength);
      glGetShaderInfoLog(_shaderID, logLength, &logLength, log);
      NSString * logString = [NSString stringWithUTF8String: log];
      free(log);
      return logString;
    }
  
  return nil;
}

- (void) attachToProgram: (CAGLProgram *)program
{
  if ([self compileStatus] == GL_FALSE)
    return;
  
  glAttachShader([program programID], _shaderID);
}

@end

@implementation CAGLVertexShader
- (GLenum) shaderType
{
  return GL_VERTEX_SHADER;
}
@end

@implementation CAGLFragmentShader
- (GLenum) shaderType
{
  return GL_FRAGMENT_SHADER;
}
@end
