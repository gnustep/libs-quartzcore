/* CATextLayer.m

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
#import "QuartzCore/CATextLayer.h"

NSString *const kCAAlignmentNatural = @"natural";
NSString *const kCAAlignmentLeft = @"left";
NSString *const kCAAlignmentRight = @"right";
NSString *const kCAAlignmentCenter = @"center";
NSString *const kCAAlignmentJustified = @"justified";

NSString *const kCATruncationNone = @"none";
NSString *const kCATruncationStart = @"start";
NSString *const kCATruncationEnd = @"end";
NSString *const kCATruncationMiddle = @"middle";

@implementation CATextLayer

@synthesize string = _string;
@synthesize fontSize = _fontSize;
@synthesize alignmentMode = _alignmentMode;
@synthesize truncationMode = _truncationMode;
@synthesize wrapped = _wrapped;

- (id) init
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  /* Apple starts with Helvetica at this size, held as a font object.  A
     name is the same thing to the property, and is what there is to hold
     here. */
  _font = [@"Helvetica" retain];
  _fontSize = 36.0;
  _foregroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
  _alignmentMode = [kCAAlignmentNatural copy];
  _truncationMode = [kCATruncationNone copy];

  return self;
}

- (void) dealloc
{
  [(id)_font release];
  CGColorRelease(_foregroundColor);
  [_string release];
  [_alignmentMode release];
  [_truncationMode release];

  [super dealloc];
}

- (CFTypeRef) font
{
  return _font;
}

- (void) setFont: (CFTypeRef)font
{
  if (font == _font)
    {
      return;
    }

  [(id)font retain];
  [(id)_font release];
  _font = font;
}

- (CGColorRef) foregroundColor
{
  return _foregroundColor;
}

- (void) setForegroundColor: (CGColorRef)foregroundColor
{
  if (foregroundColor == _foregroundColor)
    {
      return;
    }

  CGColorRetain(foregroundColor);
  CGColorRelease(_foregroundColor);
  _foregroundColor = foregroundColor;
}

/* TODO: draw the text.  The properties above are held and read back, but
   nothing draws a glyph, so a text layer draws as a plain layer does. */

@end
