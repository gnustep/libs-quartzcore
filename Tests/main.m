/* Tests/main.m

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

#import <Foundation/Foundation.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSOpenGL.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#if !(GSIMPL_UNDER_COCOA)
#import <QuartzCore/QuartzCore.h>
#else
#import <GSQuartzCore/AppleSupport.h>
#import <GSQuartzCore/QuartzCore.h>
#endif
#import "QCTestOpenGLView.h"

@interface AppController : NSObject
{
  NSWindow *window;
}
@end

@implementation AppController
-(void)applicationDidFinishLaunching: (NSNotification*)aNote
{
#if GNUSTEP
  NSMenu * menu = [[NSMenu alloc] initWithTitle: @"Main Menu"];

  [menu addItemWithTitle: [classOfTestOpenGLView() description]
                  action: @selector(orderFrontStandardAboutPanel:)
           keyEquivalent: @""];
  [menu addItemWithTitle: @"Quit"
                  action: @selector(terminate:)
           keyEquivalent: @"q"];

  [NSApp setMainMenu: menu];
  [menu release];
#endif

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,800,600)
                                       styleMask: NSTitledWindowMask | NSClosableWindowMask
                                         backing: NSBackingStoreBuffered
                                           defer: NO];
    
  QCTestOpenGLView * openGLView;
  openGLView = [[classOfTestOpenGLView() alloc] initWithFrame: [[window contentView] frame]
                                                  pixelFormat: [classOfTestOpenGLView() defaultPixelFormat]];
  [window setContentView: openGLView];
  [openGLView startAnimation];
  [openGLView release];

  [window setTitle: [[openGLView class] description]];
  
  [window makeKeyAndOrderFront: nil];
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(id)sender 
{
  return YES;
}
-(void)dealloc
{
  [window release];
  [super dealloc];
}
@end

int main(int argc, const char ** argv, char ** environ) {
#if GNUSTEP
  NSAutoreleasePool * pool = [NSAutoreleasePool new];
  AppController * controller = [AppController new];
  [[NSApplication sharedApplication] setDelegate:controller];
  [NSProcessInfo initializeWithArguments: (char**)argv
                                   count: argc
                             environment: environ];
  [NSApp run];
  [pool drain];
  return 0;

#else
  return NSApplicationMain(argc, argv);
#endif
}

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
