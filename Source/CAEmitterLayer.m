/* CAEmitterLayer.m

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
#import "QuartzCore/CAEmitterLayer.h"

NSString *const kCAEmitterLayerPoint = @"point";
NSString *const kCAEmitterLayerLine = @"line";
NSString *const kCAEmitterLayerRectangle = @"rectangle";
NSString *const kCAEmitterLayerCuboid = @"cuboid";
NSString *const kCAEmitterLayerCircle = @"circle";
NSString *const kCAEmitterLayerSphere = @"sphere";

NSString *const kCAEmitterLayerPoints = @"points";
NSString *const kCAEmitterLayerOutline = @"outline";
NSString *const kCAEmitterLayerSurface = @"surface";
NSString *const kCAEmitterLayerVolume = @"volume";

NSString *const kCAEmitterLayerUnordered = @"unordered";
NSString *const kCAEmitterLayerOldestFirst = @"oldestFirst";
NSString *const kCAEmitterLayerOldestLast = @"oldestLast";
NSString *const kCAEmitterLayerBackToFront = @"backToFront";
NSString *const kCAEmitterLayerAdditive = @"additive";

@implementation CAEmitterLayer

@synthesize emitterCells=_emitterCells;
@synthesize emitterPosition=_emitterPosition;
@synthesize emitterZPosition=_emitterZPosition;
@synthesize emitterSize=_emitterSize;
@synthesize emitterDepth=_emitterDepth;
@synthesize emitterShape=_emitterShape;
@synthesize emitterMode=_emitterMode;
@synthesize renderMode=_renderMode;
@synthesize scale=_scale;
@synthesize seed=_seed;
@synthesize spin=_spin;
@synthesize velocity=_velocity;
@synthesize birthRate=_birthRate;
@synthesize lifetime=_lifetime;
@synthesize preservesDepth=_preservesDepth;

+ (id) defaultValueForKey: (NSString *)key
{
  if ([key isEqualToString: @"emitterShape"])
    {
      return kCAEmitterLayerPoint;
    }
  if ([key isEqualToString: @"emitterMode"])
    {
      return kCAEmitterLayerVolume;
    }
  if ([key isEqualToString: @"renderMode"])
    {
      return kCAEmitterLayerUnordered;
    }
  if ([key isEqualToString: @"scale"]
      || [key isEqualToString: @"spin"]
      || [key isEqualToString: @"velocity"]
      || [key isEqualToString: @"birthRate"]
      || [key isEqualToString: @"lifetime"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }

  return [super defaultValueForKey: key];
}

- (id) init
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  _emitterShape = [kCAEmitterLayerPoint copy];
  _emitterMode = [kCAEmitterLayerVolume copy];
  _renderMode = [kCAEmitterLayerUnordered copy];
  _scale = 1.0;
  _spin = 1.0;
  _velocity = 1.0;
  _birthRate = 1.0;
  _lifetime = 1.0;

  return self;
}

- (void) dealloc
{
  [_emitterCells release];
  [_emitterShape release];
  [_emitterMode release];
  [_renderMode release];

  [super dealloc];
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
