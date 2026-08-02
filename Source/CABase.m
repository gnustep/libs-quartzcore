/*
   CABase.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
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

#import "QuartzCore/CABase.h"

#if GNUSTEP
#import <sys/time.h>
#import <time.h>

/* Media time is the time since the machine started and only moves forward.
   The wall clock moves when the date is set and when NTP corrects it, and
   animation begin times are derived from media time. */
CFTimeInterval CACurrentMediaTime(void)
{
#if defined(CLOCK_MONOTONIC)
  struct timespec monotonicTime;

  if (clock_gettime(CLOCK_MONOTONIC, &monotonicTime) == 0)
    {
      return (double)monotonicTime.tv_sec
        + ((double)monotonicTime.tv_nsec)/(1000 * 1000 * 1000.);
    }
#endif

  /* Nothing better to read from.  This moves with the wall clock. */
  {
    struct timeval systemTime;

    gettimeofday(&systemTime, NULL);
    return (double)systemTime.tv_sec + ((double)systemTime.tv_usec)/(1000 * 1000.);
  }
}
#else
#import <mach/mach_time.h>

/* mach_absolute_time() counts in machine-dependent units, not nanoseconds.
   mach_timebase_info() gives the ratio between the two: 1/1 on Intel and
   125/3 on Apple silicon, where one tick is 41.67ns. */
CFTimeInterval CACurrentMediaTime(void)
{
  static double secondsPerTick = 0.0;

  if (secondsPerTick == 0.0)
    {
      mach_timebase_info_data_t timebase;

      mach_timebase_info(&timebase);
      secondsPerTick = (double)timebase.numer
        / ((double)timebase.denom * (1000 * 1000 * 1000.));
    }

  return (double)mach_absolute_time() * secondsPerTick;
}

#endif

