#import <AppKit/NSWindow.h>
#import <AppKit/NSOpenGL.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import <CAAppKitBridge/NSView+CAmethods.h>
#import "DemoController.h"

@implementation DemoController
-(void)applicationDidFinishLaunching: (NSNotification*)aNote
{

/*  NSMenu * menu = [[NSMenu alloc] initWithTitle: @"Main Menu"];

  [menu addItemWithTitle: @"GSQCDemo"
                  action: @selector(orderFrontStandardAboutPanel:)
           keyEquivalent: @""];
  [menu addItemWithTitle: @"Quit"
                  action: @selector(terminate:)
           keyEquivalent: @"q"];

  [NSApp setMainMenu: menu];
//  [menu release];
*/
  _window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,800,600)
                                        styleMask: NSTitledWindowMask | NSClosableWindowMask
                                          backing: NSBackingStoreBuffered
                                            defer: NO];


  NSView * demoView1;
  NSView * demoView2;
  NSView * demoView3;
  NSView * demoView4;


  demoView1 = [[NSView alloc] initWithFrame: [[_window contentView] frame]
                                         pixelFormat: [NSView defaultPixelFormat]];
  demoView2 = [[NSView alloc] initWithFrame: [[_window contentView] frame]
                                         pixelFormat: [NSView defaultPixelFormat]];
  demoView3 = [[NSView alloc] initWithFrame: [[_window contentView] frame]
                                         pixelFormat: [NSView defaultPixelFormat]];
  demoView4 = [[NSView alloc] initWithFrame: [[_window contentView] frame]
                                         pixelFormat: [NSView defaultPixelFormat]];

//  NSLog(@"%p %p %p %p",demoView1,demoView2,demoView3,demoView4);

  [_window setContentView: demoView1];
 // [openGLView startAnimation];
 // [openGLView release];

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