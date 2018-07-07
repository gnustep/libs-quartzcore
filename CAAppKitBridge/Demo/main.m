/* Demo/main.m

   Copyright (C) 2018 Free Software Foundation, Inc.

   Author: Stjepan Brkic <stjepanbrkicc@gmail.com>
   Date: June 2018

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

#import "../Source/GSCAData.h"
#import "../Source/NSView+CAMethods.h"
#import "DemoController.h"
#import <Foundation/Foundation.h>


int
main(int argc, const char ** argv, char ** environ)
{
  NSAutoreleasePool * pool = [NSAutoreleasePool new];
  id controller = [DemoController new];
  [[NSApplication sharedApplication] setDelegate: controller];
  [NSProcessInfo initializeWithArguments: (char**)argv
                                   count: argc
                             environment: environ];
  [NSApp run];
  [pool drain];
  return 0;
}
