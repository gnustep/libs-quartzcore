/* CAEmitterLayer.h

   Copyright (C) 2026 Free Software Foundation, Inc.

   Author: Todd White <todd.white@thalion.global>
   Date: August 2026

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
#import "QuartzCore/CALayer.h"
#import "QuartzCore/CAEmitterCell.h"

/* A layer that emits a particle system.  The particles come from the
   CAEmitterCells it is given. */
@interface CAEmitterLayer : CALayer
{
  /* property-backing ivars */
  NSArray * _emitterCells;
  CGPoint _emitterPosition;
  CGFloat _emitterZPosition;
  CGSize _emitterSize;
  CGFloat _emitterDepth;
  NSString * _emitterShape;
  NSString * _emitterMode;
  NSString * _renderMode;
  float _scale;
  unsigned int _seed;
  float _spin;
  float _velocity;
  float _birthRate;
  float _lifetime;
  BOOL _preservesDepth;
}

@property (copy) NSArray *emitterCells;
@property CGPoint emitterPosition;
@property CGFloat emitterZPosition;
@property CGSize emitterSize;
@property CGFloat emitterDepth;
@property (copy) NSString *emitterShape;
@property (copy) NSString *emitterMode;
@property (copy) NSString *renderMode;
@property float scale;
@property unsigned int seed;
@property float spin;
@property float velocity;
@property float birthRate;
@property float lifetime;
@property BOOL preservesDepth;

@end

/* emitter shapes */
extern NSString *const kCAEmitterLayerPoint;
extern NSString *const kCAEmitterLayerLine;
extern NSString *const kCAEmitterLayerRectangle;
extern NSString *const kCAEmitterLayerCuboid;
extern NSString *const kCAEmitterLayerCircle;
extern NSString *const kCAEmitterLayerSphere;

/* emitter modes */
extern NSString *const kCAEmitterLayerPoints;
extern NSString *const kCAEmitterLayerOutline;
extern NSString *const kCAEmitterLayerSurface;
extern NSString *const kCAEmitterLayerVolume;

/* the order the particles are drawn in */
extern NSString *const kCAEmitterLayerUnordered;
extern NSString *const kCAEmitterLayerOldestFirst;
extern NSString *const kCAEmitterLayerOldestLast;
extern NSString *const kCAEmitterLayerBackToFront;
extern NSString *const kCAEmitterLayerAdditive;

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
