/* Tests/QCTestOpenGLView.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vucica <ivan@vucica.net>
   Date: May 2012

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

#import <AppKit/NSOpenGLView.h>

#if !(GSIMPL_UNDER_COCOA)
#else
#import <GSQuartzCore/AppleSupport.h>
#endif

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

@class CARenderer;
@class CALayer;

@interface DemoOpenGLView : NSOpenGLView
{
  NSTimer * _timer;
  BOOL _isAnimating;

  CARenderer * _renderer;
  CALayer * _rootLayer;
}

- (void) startAnimation;
- (void) stopAnimation;
- (void) timerAnimation: (NSTimer *)aTimer;
- (void) clearBounds: (CGRect) bounds;
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
