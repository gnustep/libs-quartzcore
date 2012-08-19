/* 
   CABackingStore.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
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

/*
 * This class serves to store graphics related to a layer:
 * - CGBitmapContextRef for drawing contents
 * - OpenGL texture containing drawn contents
 * - OpenGL texture containing offscreen-rendered cache of contents
 *   and sublayers
 * In the future, this class will probably also wrap CGImageRefs. 
 */


#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif
#if (__APPLE__)
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#else
#import <GL/gl.h>
#import <GL/glu.h>
#endif

@class CAGLTexture;

@interface CABackingStore : NSObject
{
  CGContextRef _context;
  CAGLTexture * _contentsTexture;
  CAGLTexture * _offscreenRenderTexture;
}

+ (CABackingStore *) backingStoreWithWidth: (CGFloat) width
                                    height: (CGFloat) height;

- (id) initWithWidth: (CGFloat) width
              height: (CGFloat) height;
- (void) refresh;

@property /* (retain) */ CGContextRef context;
@property (retain) CAGLTexture * contentsTexture;
@property (retain) CAGLTexture * offscreenRenderTexture;
@property (readonly) CGFloat width;
@property (readonly) CGFloat height;

@end
/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
