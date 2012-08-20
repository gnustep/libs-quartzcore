/* Demo/AppController.m

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

#import <Foundation/Foundation.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSOpenGL.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import "DemoOpenGLView.h"
#import "AppController.h"

@implementation AppController
-(void)applicationDidFinishLaunching: (NSNotification*)aNote
{
#if GNUSTEP
  NSMenu * menu = [[NSMenu alloc] initWithTitle: @"Main Menu"];

  [menu addItemWithTitle: @"GSQCDemo"
                  action: @selector(orderFrontStandardAboutPanel:)
           keyEquivalent: @""];
  [menu addItemWithTitle: @"Quit"
                  action: @selector(terminate:)
           keyEquivalent: @"q"];

  [NSApp setMainMenu: menu];
  [menu release];
#endif

  _window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,800,600)
                                        styleMask: NSTitledWindowMask | NSClosableWindowMask
                                          backing: NSBackingStoreBuffered
                                            defer: NO];
    
  DemoOpenGLView * openGLView;
  openGLView = [[DemoOpenGLView alloc] initWithFrame: [[_window contentView] frame]
                                         pixelFormat: [DemoOpenGLView defaultPixelFormat]];
  [_window setContentView: openGLView];
  [openGLView startAnimation];
  [openGLView release];

  [_window setTitle: @"GNUstep QuartzCore Demo"];
  
  [_window makeKeyAndOrderFront: nil];
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(id)sender 
{
  return YES;
}
-(void)dealloc
{
  [_window release];
  [super dealloc];
}
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
