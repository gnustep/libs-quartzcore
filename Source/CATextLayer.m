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
#import "CALayer+FrameworkPrivate.h"

#include <CoreText/CoreText.h>

@interface CATextLayer (FontForDrawing)
- (CTFontRef) fontForDrawing;
@end

/* CoreFoundation is not linked into this framework on GNUstep, so a CoreText
   object is released the way the rest of it releases one. */
static void releaseCoreTextObject(const void *object)
{
  if (object == NULL)
    return;
#if GNUSTEP
  [(id)object release];
#else
  CFRelease(object);
#endif
}

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

/* Changing what is drawn asks for a display, which is what Apple does. */
- (void) setString: (id)string
{
  if (string == _string)
    {
      return;
    }

  [_string release];
  _string = [string retain];
  [self setNeedsDisplay];
}

- (void) setFontSize: (CGFloat)fontSize
{
  if (fontSize == _fontSize)
    {
      return;
    }

  _fontSize = fontSize;
  [self setNeedsDisplay];
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

/* The font property takes a font object or a name.  Whichever it is, drawing
   needs a font at the layer's own size. */
- (CTFontRef) fontForDrawing
{
  if (_font == NULL)
    {
      return CTFontCreateWithName((CFStringRef)@"Helvetica", _fontSize, NULL);
    }

  if ([(id)_font isKindOfClass: [NSString class]])
    {
      return CTFontCreateWithName((CFStringRef)_font, _fontSize, NULL);
    }

#if GNUSTEP
  if ([(id)_font isKindOfClass: NSClassFromString(@"OPFont")])
#else
  if (CFGetTypeID(_font) == CTFontGetTypeID())
#endif
    {
      CTFontRef sized = CTFontCreateCopyWithAttributes((CTFontRef)_font,
                                                       _fontSize, NULL, NULL);
      CFStringRef family;

      if (sized != NULL)
        {
          return sized;
        }

      /* Where a copy at another size is not available, the family name is
         enough to build the same face again. */
      family = CTFontCopyFamilyName((CTFontRef)_font);
      if (family != NULL)
        {
          CTFontRef named = CTFontCreateWithName(family, _fontSize, NULL);

          releaseCoreTextObject(family);
          return named;
        }
    }

  return CTFontCreateWithName((CFStringRef)@"Helvetica", _fontSize, NULL);
}

/* The string is drawn under the layer's contents, its first line against the
   top of the bounds.  A plain string is set in the layer's own font, size and
   colour; an attributed string carries its own and the layer's are not used,
   which is what Apple does. */
- (void) drawBackgroundInContext: (CGContextRef)context
{
  CGRect bounds = [self bounds];
  NSAttributedString *attributed = nil;
  CTLineRef line;
  CGFloat ascent = 0, descent = 0, leading = 0;
  double width;
  CGFloat x;

  if (_string == nil)
    return;

  if ([_string isKindOfClass: [NSAttributedString class]])
    {
      attributed = [_string retain];
    }
  else if ([_string isKindOfClass: [NSString class]])
    {
      NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
      CTFontRef font = [self fontForDrawing];

      if (font == NULL)
        return;

      [attributes setObject: (id)font forKey: (id)kCTFontAttributeName];
      if (_foregroundColor != NULL)
        {
          [attributes setObject: (id)_foregroundColor
                         forKey: (id)kCTForegroundColorAttributeName];
        }
      attributed = [[NSAttributedString alloc] initWithString: _string
                                                   attributes: attributes];
      releaseCoreTextObject(font);
    }
  else
    {
      return;
    }

  if (attributed == nil || [attributed length] == 0)
    {
      [attributed release];
      return;
    }

  line = CTLineCreateWithAttributedString((CFAttributedStringRef)attributed);
  [attributed release];
  if (line == NULL)
    return;

  width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

  /* natural and justified are left here, as they are on Apple for a single
     line of Latin text. */
  if ([_alignmentMode isEqualToString: kCAAlignmentRight])
    x = CGRectGetMaxX(bounds) - width;
  else if ([_alignmentMode isEqualToString: kCAAlignmentCenter])
    x = CGRectGetMinX(bounds) + (bounds.size.width - width) / 2.0;
  else
    x = CGRectGetMinX(bounds);

  CGContextSaveGState(context);
  CGContextClipToRect(context, bounds);
  if (_foregroundColor != NULL)
    {
      CGContextSetFillColorWithColor(context, _foregroundColor);
    }
  /* The first baseline sits one line height below the top of the bounds. */
  CGContextSetTextPosition(context, x,
                           CGRectGetMaxY(bounds) - (ascent + descent));
  CTLineDraw(line, context);
  CGContextRestoreGState(context);

  releaseCoreTextObject(line);
}

@end
