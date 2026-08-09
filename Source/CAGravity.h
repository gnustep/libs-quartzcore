/* CAGravity.h

   Copyright (C) 2026 Free Software Foundation, Inc.

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
#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

/* The rectangle, in a layer's bounds coordinates, that contents of the given
   size occupy under the given gravity.  Both renderers ask this so that they
   place the contents the same way. */
CGRect CAGravityDestinationRect(NSString *gravity, CGRect bounds,
                                CGSize contentsSize);
