/* Demo/TextLayer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vucica <ivan@vucica.net>
   Date: August 2012

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

#import "TextLayer.h"

@implementation TextLayer
@synthesize text = _text;
@synthesize color = _color;
@synthesize fontSize = _fontSize;

- (void) dealloc
{
  [_text release];
  [super dealloc];
}

- (void) setColor: (CGColorRef)color
{
  if (color == _color)
    return;
  
  CGColorRetain(color);
  CGColorRelease(_color);
  _color = color;
}

- (void) drawInContext: (CGContextRef)context
{
#if !(GNUSTEP)
  // Cocoa-provided Core Graphics
  [self drawInContextCoreText: context];
#else
  // Opal doesn't work with -drawInContextCoreText:.
  [self drawInContextElementary: context];
#endif
}
- (void) drawInContextCoreText: (CGContextRef)context
{
  /* Requires CoreText */
  
  if (!_text)
    return;
  if (!_color)
    return;
  CTFontRef font = CTFontCreateWithName((CFStringRef)@"Helvetica-Bold", _fontSize ?: 8, NULL);
  
  NSDictionary * attributesDict;
  attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                    (id)font, (id)kCTFontAttributeName,
                    (id)_color, (id)kCTForegroundColorAttributeName,
                    nil];

  NSAttributedString * stringToDraw;
  stringToDraw = [[NSAttributedString alloc] initWithString: _text
                                                 attributes: attributesDict];
  CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)stringToDraw);
  
  /* Drawing */
  CGContextSetTextPosition(context, 5, 15);
  CTLineDraw(line, context);
  
  /* Cleanup */
  [stringToDraw release];
  [(id)line release];
  [(id)font release];
  CGColorRelease(_color);
}

- (void) drawInContextElementary: (CGContextRef)ctx
{
  /* Lacks support for UTF-8 */
  
  CGContextSaveGState(ctx);

  //CGContextSetGrayFillColor(ctx, 0, 1);
  CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
  if (_color)
    CGContextSetFillColorWithColor(ctx, _color);
  else
    NSLog(@"Nil color");
  CGContextSelectFont(ctx, "Helvetica-Bold", _fontSize, kCGEncodingMacRoman);
  CGContextShowTextAtPoint(ctx, 5, 15, [_text UTF8String], [_text length]);
  
  CGContextRestoreGState(ctx);
}


  /*
  // create system font
  CTFontRef sysUIFont = CTFontCreateUIFontForLanguage(kCTFontSystemFontType, 24.0, NULL);

  // create from the postscript name
  CTFontRef helveticaBold = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 24.0, NULL);
 
  // create it by replacing traits of existing font, this replaces bold with italic
  CTFontRef helveticaItalic = CTFontCreateCopyWithSymbolicTraits(helveticaBold, 24.0, NULL,
    kCTFontItalicTrait, kCTFontBoldTrait | kCTFontItalicTrait);
  */

@end
