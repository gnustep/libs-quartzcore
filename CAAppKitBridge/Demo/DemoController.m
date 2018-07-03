#import <AppKit/NSWindow.h>
#import <AppKit/NSOpenGL.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import "DemoController.h"

@implementation DemoController
-(void)applicationDidFinishLaunching: (NSNotification*)aNote
{
  _window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,800,600)
                                        styleMask: NSTitledWindowMask | NSClosableWindowMask
                                          backing: NSBackingStoreBuffered
                                            defer: NO];

  NSView * demoView1;
  NSView * demoView2;
  NSView * demoView3;
  NSView * demoView4;

  demoView1 = [[NSView alloc] initWithFrame: [[_window contentView] frame];
  demoView2 = [[NSView alloc] initWithFrame: [[_window contentView] frame];
  demoView3 = [[NSView alloc] initWithFrame: [[_window contentView] frame];
  demoView4 = [[NSView alloc] initWithFrame: [[_window contentView] frame];

  [_window setContentView: demoView1];
  [_window setTitle: @"GNUstep QuartzCore CAAppKitBridge Demo"];
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
