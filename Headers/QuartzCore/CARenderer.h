/* 
   CARenderer.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: March 2012

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

#import "CABase.h"

@class CAAnimation;
@class CALayer;

#ifndef CVTimeStamp
#warning CVTimeStamp temporarily defined to int
#define CVTimeStamp int
#endif

@interface CARenderer : NSObject
{
	NSOpenGLContext * _glContext;
	CALayer * _layer;
	CGRect _bounds;
}

// MARK: - Class methods
// Creates a renderer which renders into an OpenGL context.
+ (CARenderer*)rendererWithNSOpenGLContext:(NSOpenGLContext*)ctx options:(NSDictionary*)options;

// MARK: - Properties
// Root layer.
// @property (nonatomic, retain) CALayer * layer;
- (CALayer*)layer;
- (void)setLayer:(CALayer*)layer;

// Bounds.
// @property (nonatomic, assign) CGRect bounds;
- (CGRect)bounds;
- (void)setBounds:(CGRect)bounds;

// MARK: - Methods

// Adds a rectangle to the update region.
- (void)addUpdateRect:(CGRect)updateRect;
// Begins rendering a frame at the specified time.
- (void)beginFrameAtTime:(CFTimeInterval)timeInterval timeStamp:(CVTimeStamp *)timeStamp;
// Ends rendering the frame, releasing any temporary data.
- (void)endFrame;
// Returns time when next update should be performed.
- (CFTimeInterval)nextFrameTime;
// Renders a frame to the target context. It should be rendering the
// update region only.
- (void)render;
// Returns rectangle containing all pixels that should be updated.
- (CGRect)updateBounds;

@end
