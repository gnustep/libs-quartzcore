/* CAGLFramebuffer.h

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

/* This object is called a simple framebuffer because all it allows
   is a texture serving as a color attachment point and a renderbuffer
   serving as a depth attachment. It also isn't too nice that it
   directly manages the renderbuffer for depth.
   
   It'd be more powerful if we also wrapped framebuffer in a way
   that allows more finetuned manipulation of attachment points.
   However, for the time being, we don't need that.
*/

#import <Foundation/Foundation.h>
#if !(__APPLE__)
#import <GL/gl.h>
#import <GL/glu.h>
#else
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#endif

@class CAGLTexture;

@interface CAGLSimpleFramebuffer : NSObject
{
  GLuint _framebufferID;
  GLuint _depthRenderbufferID;
  CAGLTexture * _texture;
  BOOL _depthBufferEnabled;
}

@property (nonatomic, retain, readonly) CAGLTexture * texture;
@property (nonatomic, getter=hasDepthBuffer) BOOL depthBufferEnabled;

- (id)initWithWidth: (CGFloat) width
             height: (CGFloat) height;
- (void) bind;
- (void) unbind;
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
