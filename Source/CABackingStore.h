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
 * This class is a simple wrapper around CGContextRef and GL textures.
 * Use of GL textures is TBD.
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

@interface CABackingStore : NSObject
{
  CGContextRef _context;
  GLuint _texture;
}

+ (CABackingStore *)backingStoreWithContext: (CGContextRef) context;

- (id)initWithContext: (CGContextRef) context;
@property /* (retain) */ CGContextRef context;
@property GLuint texture;

@end
/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
