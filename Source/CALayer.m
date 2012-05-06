/* CALayer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>
   Date: December 2011

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

#import "QuartzCore/CALayer.h"

NSString *const kCAGravityResize = @"CAGravityResize";
NSString *const kCAGravityResizeAspect = @"CAGravityResizeAspect";
NSString *const kCAGravityResizeAspectFill = @"CAGravityResizeAspectFill";
NSString *const kCAGravityCenter = @"CAGravityCenter";
NSString *const kCAGravityTop = @"CAGravityTop";
NSString *const kCAGravityBottom = @"CAGravityBottom";
NSString *const kCAGravityLeft = @"CAGravityLeft";
NSString *const kCAGravityRight = @"CAGravityRight";
NSString *const kCAGravityTopLeft = @"CAGravityTopLeft";
NSString *const kCAGravityTopRight = @"CAGravityTopRight";
NSString *const kCAGravityBottomLeft = @"CAGravityBottomLeft";
NSString *const kCAGravityBottomRight = @"CAGravityBottomRight";

@implementation CALayer

@synthesize delegate=_delegate;
@synthesize contents=_contents;
@synthesize layoutManager=_layoutManager;
@synthesize sublayers=_sublayers;
@synthesize frame=_frame;
@synthesize bounds=_bounds;
@synthesize position=_position;
@synthesize opacity=_opacity;
@synthesize opaque=_opaque;
@synthesize geometryFlipped=_geometryFlipped;
@synthesize backgroundColor=_backgroundColor;
@synthesize masksToBounds=_masksToBounds;
@synthesize contentsRect=_contentsRect;
@synthesize hidden=_hidden;
@synthesize contentsGravity=_contentsGravity;
@synthesize needsDisplayOnBoundsChange=_needsDisplayOnBoundsChange;
@synthesize zPosition=_zPosition;

@end

