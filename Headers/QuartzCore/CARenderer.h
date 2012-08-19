/* 
   CARenderer.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: March 2012

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

#import "CABase.h"
#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

@class CAAnimation;
@class CALayer;
@class NSOpenGLContext;

typedef struct _CVTimeStamp
{
  uint32_t version; /* zero */
  uint32_t videoTimeScale; /* content framerate */
  int64_t videoTime; /* content-specific time at which render is performed */
  uint64_t hostTime; /* host-specific time at which render is performed */
  double rateScalar; /* unused */
  int64_t videoRefreshPeriod; /* optimal framerate, e.g. vsync */
  /* smpte time not supported */
  char smpteTime[160]; /* ordinarily, a struct: CVSMPTETime */
  uint64_t flags;
  uint64_t reserved;
} CVTimeStamp;

@class CAGLProgram;
@interface CARenderer : NSObject
{
  NSOpenGLContext * _GLContext;
  CALayer * _layer;
  CGRect _bounds;
  CGRect _updateBounds;
  
  CFTimeInterval _firstRender;
  CFTimeInterval _currentTime;
  CFTimeInterval _nextFrameTime;
  
  NSMutableArray * _rasterizationSchedule;

  /* GL programs */
  CAGLProgram * _simpleProgram;
  CAGLProgram * _blurHorizProgram;
  CAGLProgram * _blurVertProgram;
}

+ (CARenderer*)rendererWithNSOpenGLContext: (NSOpenGLContext *)context
                                   options: (NSDictionary *)options;

@property (retain) CALayer *layer; /* root layer */
@property (nonatomic, assign) CGRect bounds;

- (void) addUpdateRect: (CGRect)updateRect;
- (void) beginFrameAtTime: (CFTimeInterval)timeInterval
                timeStamp: (CVTimeStamp *)timeStamp;
- (void) endFrame;
- (CFTimeInterval) nextFrameTime;
- (void) render;
- (CGRect) updateBounds;

@end
/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
