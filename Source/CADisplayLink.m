/* CADisplayLink.m

   Copyright (C) 2012, 2026 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>

   Author: Todd White <todd.white@thalion.global>
   Date: August 2026

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
#import "QuartzCore/CADisplayLink.h"

/* Frames a second when nothing else has been asked for. */
static const NSInteger CADisplayLinkDefaultFramesPerSecond = 60;

@implementation CADisplayLink

@synthesize timestamp = _timestamp;
@synthesize duration = _duration;
@synthesize targetTimestamp = _targetTimestamp;
@synthesize paused = _paused;
@synthesize preferredFramesPerSecond = _preferredFramesPerSecond;

+ (CADisplayLink *) displayLinkWithTarget: (id)target selector: (SEL)sel
{
  CADisplayLink *link = [[self alloc] init];

  link->_target = target;
  link->_selector = sel;

  return [link autorelease];
}

- (id) init
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  _preferredFramesPerSecond = CADisplayLinkDefaultFramesPerSecond;
  _duration = 1.0 / (CFTimeInterval)CADisplayLinkDefaultFramesPerSecond;

  return self;
}

- (void) dealloc
{
  [_timer invalidate];
  [_timer release];

  [super dealloc];
}

/* There is no display to follow here, so a timer at the asked-for rate is
   what drives the link. */
- (NSTimeInterval) _interval
{
  NSInteger frames = _preferredFramesPerSecond;

  if (frames <= 0)
    {
      frames = CADisplayLinkDefaultFramesPerSecond;
    }

  return 1.0 / (NSTimeInterval)frames;
}

- (void) _fire: (NSTimer *)timer
{
  if (_paused || _invalidated)
    {
      return;
    }

  _duration = [self _interval];
  _timestamp = CACurrentMediaTime();
  _targetTimestamp = _timestamp + _duration;

  [_target performSelector: _selector withObject: self];
}

- (void) addToRunLoop: (NSRunLoop *)runloop forMode: (NSString *)mode
{
  if (_invalidated)
    {
      return;
    }

  if (_timer == nil)
    {
      _timer = [[NSTimer timerWithTimeInterval: [self _interval]
                                        target: self
                                      selector: @selector(_fire:)
                                      userInfo: nil
                                       repeats: YES] retain];
    }

  [runloop addTimer: _timer forMode: mode];
}

- (void) removeFromRunLoop: (NSRunLoop *)runloop forMode: (NSString *)mode
{
  /* A timer leaves a run loop only by being invalidated, so the link keeps
     the mode it was added for until it is taken out of all of them. */
  [self invalidate];
}

- (void) invalidate
{
  _invalidated = YES;
  [_timer invalidate];
  [_timer release];
  _timer = nil;
  _target = nil;
}

@end
