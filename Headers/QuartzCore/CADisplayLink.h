/* CADisplayLink.h

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
#import <QuartzCore/CABase.h>

@class NSRunLoop;
@class NSString;
@class NSTimer;

@interface CADisplayLink : NSObject
{
  id _target;
  SEL _selector;
  NSTimer *_timer;
  CFTimeInterval _timestamp;
  CFTimeInterval _duration;
  CFTimeInterval _targetTimestamp;
  NSInteger _preferredFramesPerSecond;
  BOOL _paused;
  BOOL _invalidated;
}

/* Answers a link that sends the selector to the target once a frame.  The
   target is not retained. */
+ (CADisplayLink *) displayLinkWithTarget: (id)target selector: (SEL)sel;

- (void) addToRunLoop: (NSRunLoop *)runloop forMode: (NSString *)mode;
- (void) removeFromRunLoop: (NSRunLoop *)runloop forMode: (NSString *)mode;

/* Takes the link out of every run loop it was added to.  A link cannot be
   used again afterwards. */
- (void) invalidate;

/* When the last frame was sent, and when the next one is due.  Both are 0
   until the link has sent one. */
@property (readonly) CFTimeInterval timestamp;
@property (readonly) CFTimeInterval targetTimestamp;

/* How long a frame lasts. */
@property (readonly) CFTimeInterval duration;

/* While this is set the link sends nothing, and stays in its run loops. */
@property (assign, getter=isPaused) BOOL paused;

@property (assign) NSInteger preferredFramesPerSecond;

@end
