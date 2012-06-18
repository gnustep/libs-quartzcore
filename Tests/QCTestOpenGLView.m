/* Tests/QCTestOpenGLView.m

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

#import "QCTestOpenGLView.h"

@implementation QCTestOpenGLView

- (void) prepareOpenGL
{
  [super prepareOpenGL];
  
}
- (void) dealloc
{
  if(_isAnimating)
    [self stopAnimation];

  [super dealloc];
}

#if 0
/* Not needed for now */
+ (NSOpenGLPixelFormat*) defaultPixelFormat
{
  NSOpenGLPixelFormatAttribute attributes[] = { 
    NSOpenGLPFAAccelerated,
    NSOpenGLPFADepthSize, 16,
    NSOpenGLPFAMinimumPolicy,
    NSOpenGLPFAClosestPolicy,
    0 
  };  
  NSOpenGLPixelFormat *format;
    
  format = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];

  return format;
}
#endif

- (void) startAnimation
{
  if(!_timer)
    _timer = [NSTimer scheduledTimerWithTimeInterval: 1./60. 
                                              target: self 
                                            selector: @selector(timerAnimation:) 
                                            userInfo: nil 
                                             repeats: YES];
  _isAnimating = YES;

}

- (void) stopAnimation
{
  [_timer invalidate];
  _timer = nil;

  _isAnimating = NO;
}

- (void) timerAnimation: (NSTimer *)timer
{
  // noop by default
}
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
