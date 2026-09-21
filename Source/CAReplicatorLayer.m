/* CAReplicatorLayer.m

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

#import <Foundation/Foundation.h>
#import "QuartzCore/CAReplicatorLayer.h"

@implementation CAReplicatorLayer

@synthesize instanceCount = _instanceCount;
@synthesize instanceDelay = _instanceDelay;
@synthesize instanceTransform = _instanceTransform;
@synthesize preservesDepth = _preservesDepth;
@synthesize instanceRedOffset = _instanceRedOffset;
@synthesize instanceGreenOffset = _instanceGreenOffset;
@synthesize instanceBlueOffset = _instanceBlueOffset;
@synthesize instanceAlphaOffset = _instanceAlphaOffset;

- (id) init
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  _instanceCount = 1;
  _instanceTransform = CATransform3DIdentity;
  _instanceColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);

  return self;
}

- (void) dealloc
{
  CGColorRelease(_instanceColor);

  [super dealloc];
}

- (CGColorRef) instanceColor
{
  return _instanceColor;
}

- (void) setInstanceColor: (CGColorRef)instanceColor
{
  if (instanceColor == _instanceColor)
    {
      return;
    }

  CGColorRetain(instanceColor);
  CGColorRelease(_instanceColor);
  _instanceColor = instanceColor;
}

@end
