/* CAEmitterCell.h

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
#import "QuartzCore/CABase.h"
#import "QuartzCore/CAMediaTiming.h"
#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

/* One source of the particles a CAEmitterLayer emits.  A cell may hold cells
   of its own, so that a particle emits particles in turn. */
@interface CAEmitterCell : NSObject <NSCoding, NSCopying, CAMediaTiming>
{
  /* property-backing ivars */
  id _contents;
  CGRect _contentsRect;
  CGFloat _contentsScale;
  NSArray * _emitterCells;
  BOOL _enabled;
  CGColorRef _color;
  float _redRange, _greenRange, _blueRange, _alphaRange;
  float _redSpeed, _greenSpeed, _blueSpeed, _alphaSpeed;
  NSString * _magnificationFilter;
  NSString * _minificationFilter;
  float _minificationFilterBias;
  CGFloat _scale, _scaleRange, _scaleSpeed;
  NSString * _name;
  NSDictionary * _style;
  CGFloat _spin, _spinRange;
  CGFloat _emissionLatitude, _emissionLongitude, _emissionRange;
  float _lifetime, _lifetimeRange, _birthRate;
  CGFloat _velocity, _velocityRange;
  CGFloat _xAcceleration, _yAcceleration, _zAcceleration;

  /* CAMediaTiming ivars */
  CFTimeInterval _beginTime;
  CFTimeInterval _timeOffset;
  float _repeatCount;
  float _repeatDuration;
  BOOL _autoreverses;
  NSString * _fillMode;
  CFTimeInterval _duration;
  float _speed;
}

+ (id) emitterCell;
+ (id) defaultValueForKey: (NSString *)key;

- (BOOL) shouldArchiveValueForKey: (NSString *)key;

@property (retain) id contents;
@property CGRect contentsRect;
@property CGFloat contentsScale;
@property (copy) NSArray *emitterCells;
@property (getter=isEnabled) BOOL enabled;
@property CGColorRef color;

@property float redRange;
@property float greenRange;
@property float blueRange;
@property float alphaRange;
@property float redSpeed;
@property float greenSpeed;
@property float blueSpeed;
@property float alphaSpeed;

@property (copy) NSString *magnificationFilter;
@property (copy) NSString *minificationFilter;
@property float minificationFilterBias;

@property CGFloat scale;
@property CGFloat scaleRange;
@property CGFloat scaleSpeed;

@property (copy) NSString *name;
@property (copy) NSDictionary *style;

@property CGFloat spin;
@property CGFloat spinRange;
@property CGFloat emissionLatitude;
@property CGFloat emissionLongitude;
@property CGFloat emissionRange;

@property float lifetime;
@property float lifetimeRange;
@property float birthRate;

@property CGFloat velocity;
@property CGFloat velocityRange;
@property CGFloat xAcceleration;
@property CGFloat yAcceleration;
@property CGFloat zAcceleration;

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
