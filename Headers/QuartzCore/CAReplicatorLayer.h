/* CAReplicatorLayer.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>

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

#import <QuartzCore/CABase.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransform3D.h>

@interface CAReplicatorLayer : CALayer
{
  NSInteger _instanceCount;
  CFTimeInterval _instanceDelay;
  CATransform3D _instanceTransform;
  CGColorRef _instanceColor;
  float _instanceRedOffset;
  float _instanceGreenOffset;
  float _instanceBlueOffset;
  float _instanceAlphaOffset;
  BOOL _preservesDepth;
}

/* How many copies to draw, the source layer included. */
@property (assign) NSInteger instanceCount;

/* How long to wait before each copy after the first. */
@property (assign) CFTimeInterval instanceDelay;

/* Applied to one copy to produce the next. */
@property (assign) CATransform3D instanceTransform;

@property (assign) BOOL preservesDepth;

/* Multiplied into each copy, with the four offsets added per copy. */
@property (nonatomic, assign) CGColorRef instanceColor;

@property (assign) float instanceRedOffset;
@property (assign) float instanceGreenOffset;
@property (assign) float instanceBlueOffset;
@property (assign) float instanceAlphaOffset;

@end
