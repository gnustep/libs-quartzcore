/* CAAnimation+FrameworkPrivate.h

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

#import "QuartzCore/CAAnimation.h"

@class CALayer;

@interface CAAnimation (FrameworkPrivate)
- (void) handleAddedToLayer: (CALayer *)layer;
- (void) handleRemovedFromLayer: (CALayer *)layer;

/* Local time in the receiver's own time space, given the local time of the
   time authority it runs in.  The authority is the model layer for an
   animation added to a layer, and the group for an animation inside a
   CAAnimationGroup. */
- (CFTimeInterval) localTimeWithTimeAuthorityLocalTime: (CFTimeInterval)timeAuthorityLocalTime;

- (void) applyToLayer: (CALayer *)layer;
- (void) applyToLayer: (CALayer *)layer
  withTimeAuthorityLocalTime: (CFTimeInterval)timeAuthorityLocalTime;
@end
