/* CATextLayer.h

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

#import <QuartzCore/CALayer.h>

@interface CATextLayer : CALayer
{
  id _string;
  CFTypeRef _font;
  CGFloat _fontSize;
  CGColorRef _foregroundColor;
  NSString *_alignmentMode;
  NSString *_truncationMode;
  BOOL _wrapped;
}

/* The text to draw, as an NSString or an NSAttributedString. */
@property (copy)             id string;

/* The font to draw it in.  A font name is enough. */
@property (nonatomic,assign) CFTypeRef font;

@property (assign)           CGFloat fontSize;
@property (nonatomic,assign) CGColorRef foregroundColor;
@property (copy)             NSString *alignmentMode;
@property (copy)             NSString *truncationMode;

/* Whether a line too long for the layer is carried on to the next. */
@property (assign,getter=isWrapped) BOOL wrapped;

@end

extern NSString *const kCAAlignmentNatural;
extern NSString *const kCAAlignmentLeft;
extern NSString *const kCAAlignmentRight;
extern NSString *const kCAAlignmentCenter;
extern NSString *const kCAAlignmentJustified;

extern NSString *const kCATruncationNone;
extern NSString *const kCATruncationStart;
extern NSString *const kCATruncationEnd;
extern NSString *const kCATruncationMiddle;
