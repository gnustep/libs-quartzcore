/* CAGravity.m

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

#import "CAGravity.h"
#import "QuartzCore/CALayer.h"

CGRect
CAGravityDestinationRect(NSString *gravity, CGRect bounds,
                         CGSize contentsSize)
{
  CGSize size = contentsSize;
  CGFloat x, y;

  if (contentsSize.width <= 0 || contentsSize.height <= 0
      || bounds.size.width <= 0 || bounds.size.height <= 0)
    return CGRectZero;

  /* The three resizing gravities decide a size; the other nine keep the
     contents at their own size and only decide where they sit. */
  if ([gravity isEqualToString: kCAGravityResize])
    {
      return bounds;
    }
  else if ([gravity isEqualToString: kCAGravityResizeAspect]
           || [gravity isEqualToString: kCAGravityResizeAspectFill])
    {
      CGFloat wide = bounds.size.width / contentsSize.width;
      CGFloat high = bounds.size.height / contentsSize.height;
      CGFloat scale;

      if ([gravity isEqualToString: kCAGravityResizeAspect])
        scale = wide < high ? wide : high;
      else
        scale = wide > high ? wide : high;

      size.width = contentsSize.width * scale;
      size.height = contentsSize.height * scale;
    }

  /* Left, right, top and bottom pin one axis and centre the other. */
  if ([gravity isEqualToString: kCAGravityLeft]
      || [gravity isEqualToString: kCAGravityTopLeft]
      || [gravity isEqualToString: kCAGravityBottomLeft])
    x = 0;
  else if ([gravity isEqualToString: kCAGravityRight]
           || [gravity isEqualToString: kCAGravityTopRight]
           || [gravity isEqualToString: kCAGravityBottomRight])
    x = bounds.size.width - size.width;
  else
    x = (bounds.size.width - size.width) / 2.0;

  if ([gravity isEqualToString: kCAGravityBottom]
      || [gravity isEqualToString: kCAGravityBottomLeft]
      || [gravity isEqualToString: kCAGravityBottomRight])
    y = 0;
  else if ([gravity isEqualToString: kCAGravityTop]
           || [gravity isEqualToString: kCAGravityTopLeft]
           || [gravity isEqualToString: kCAGravityTopRight])
    y = bounds.size.height - size.height;
  else
    y = (bounds.size.height - size.height) / 2.0;

  return CGRectMake(bounds.origin.x + x, bounds.origin.y + y,
                    size.width, size.height);
}
