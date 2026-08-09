/* CAEmitterCell.m

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
#import "QuartzCore/CAEmitterCell.h"
#import "QuartzCore/CAFilter.h"

@implementation CAEmitterCell

@synthesize contents=_contents;
@synthesize contentsRect=_contentsRect;
@synthesize contentsScale=_contentsScale;
@synthesize emitterCells=_emitterCells;
@synthesize enabled=_enabled;

@synthesize redRange=_redRange;
@synthesize greenRange=_greenRange;
@synthesize blueRange=_blueRange;
@synthesize alphaRange=_alphaRange;
@synthesize redSpeed=_redSpeed;
@synthesize greenSpeed=_greenSpeed;
@synthesize blueSpeed=_blueSpeed;
@synthesize alphaSpeed=_alphaSpeed;

@synthesize magnificationFilter=_magnificationFilter;
@synthesize minificationFilter=_minificationFilter;
@synthesize minificationFilterBias=_minificationFilterBias;

@synthesize scale=_scale;
@synthesize scaleRange=_scaleRange;
@synthesize scaleSpeed=_scaleSpeed;

@synthesize name=_name;
@synthesize style=_style;

@synthesize spin=_spin;
@synthesize spinRange=_spinRange;
@synthesize emissionLatitude=_emissionLatitude;
@synthesize emissionLongitude=_emissionLongitude;
@synthesize emissionRange=_emissionRange;

@synthesize lifetime=_lifetime;
@synthesize lifetimeRange=_lifetimeRange;
@synthesize birthRate=_birthRate;

@synthesize velocity=_velocity;
@synthesize velocityRange=_velocityRange;
@synthesize xAcceleration=_xAcceleration;
@synthesize yAcceleration=_yAcceleration;
@synthesize zAcceleration=_zAcceleration;

/* CAMediaTiming */
@synthesize beginTime=_beginTime;
@synthesize timeOffset=_timeOffset;
@synthesize repeatCount=_repeatCount;
@synthesize repeatDuration=_repeatDuration;
@synthesize autoreverses=_autoreverses;
@synthesize fillMode=_fillMode;
@synthesize duration=_duration;
@synthesize speed=_speed;

+ (id) emitterCell
{
  return [[[self alloc] init] autorelease];
}

+ (id) defaultValueForKey: (NSString *)key
{
  if ([key isEqualToString: @"enabled"])
    {
      return [NSNumber numberWithBool: YES];
    }
  if ([key isEqualToString: @"scale"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }

  return nil;
}

- (id) init
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  _contentsRect = CGRectMake(0.0, 0.0, 1.0, 1.0);
  _contentsScale = 1.0;
  _enabled = YES;
  _color = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
  _magnificationFilter = [kCAFilterLinear copy];
  _minificationFilter = [kCAFilterLinear copy];
  _scale = 1.0;

  return self;
}

- (void) dealloc
{
  CGColorRelease(_color);
  [_contents release];
  [_emitterCells release];
  [_magnificationFilter release];
  [_minificationFilter release];
  [_name release];
  [_style release];
  [_fillMode release];

  [super dealloc];
}

- (CGColorRef) color
{
  return _color;
}

- (void) setColor: (CGColorRef)color
{
  if (color == _color)
    {
      return;
    }

  CGColorRetain(color);
  CGColorRelease(_color);
  _color = color;
}

- (BOOL) shouldArchiveValueForKey: (NSString *)key
{
  return NO;
}

/* The keys a cell carries from one of itself to another, and through an
   archive. */
static NSString * const GSEmitterCellKeys[] = {
  @"contents", @"contentsRect", @"contentsScale", @"emitterCells", @"enabled",
  @"redRange", @"greenRange", @"blueRange", @"alphaRange",
  @"redSpeed", @"greenSpeed", @"blueSpeed", @"alphaSpeed",
  @"magnificationFilter", @"minificationFilter", @"minificationFilterBias",
  @"scale", @"scaleRange", @"scaleSpeed", @"name", @"style",
  @"spin", @"spinRange", @"emissionLatitude", @"emissionLongitude",
  @"emissionRange", @"lifetime", @"lifetimeRange", @"birthRate",
  @"velocity", @"velocityRange",
  @"xAcceleration", @"yAcceleration", @"zAcceleration",
  @"beginTime", @"timeOffset", @"repeatCount", @"repeatDuration",
  @"autoreverses", @"fillMode", @"duration", @"speed"
};

- (id) initWithCoder: (NSCoder *)aDecoder
{
  self = [self init];
  if (self == nil)
    {
      return nil;
    }

  for (unsigned i = 0;
       i < sizeof(GSEmitterCellKeys)/sizeof(GSEmitterCellKeys[0]); i++)
    {
      if ([aDecoder containsValueForKey: GSEmitterCellKeys[i]])
        {
          [self setValue: [aDecoder decodeObjectForKey: GSEmitterCellKeys[i]]
                  forKey: GSEmitterCellKeys[i]];
        }
    }

  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  for (unsigned i = 0;
       i < sizeof(GSEmitterCellKeys)/sizeof(GSEmitterCellKeys[0]); i++)
    {
      if ([self shouldArchiveValueForKey: GSEmitterCellKeys[i]])
        {
          [aCoder encodeObject: [self valueForKey: GSEmitterCellKeys[i]]
                        forKey: GSEmitterCellKeys[i]];
        }
    }
}

- (id) copyWithZone: (NSZone *)zone
{
  CAEmitterCell *theCopy = [[[self class] allocWithZone: zone] init];

  if (theCopy == nil)
    {
      return nil;
    }

  for (unsigned i = 0;
       i < sizeof(GSEmitterCellKeys)/sizeof(GSEmitterCellKeys[0]); i++)
    {
      id value = [self valueForKey: GSEmitterCellKeys[i]];

      if (value != nil)
        {
          [theCopy setValue: value forKey: GSEmitterCellKeys[i]];
        }
    }
  [theCopy setColor: [self color]];

  return theCopy;
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
