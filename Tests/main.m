#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
//#import <QuartzCore/QuartzCore.h>

@interface AppController : NSObject
{
  NSWindow *window;
}
@end

@implementation AppController
-(void)applicationDidFinishLaunching:(NSNotification*)aNote
{
  window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,640,480)
                                       styleMask:NSTitledWindowMask | NSClosableWindowMask
                                         backing:0
                                           defer:NO];

  NSOpenGLView * openGLView = [[NSOpenGLView alloc] init];
  [window setContentView:openGLView];
  [openGLView release];

  [window makeKeyAndOrderFront:nil];
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

int main(int argc, const char ** argv) {
  AppController * controller = [AppController new];
  [[NSApplication sharedApplication] setDelegate:controller];
  return NSApplicationMain(argc, argv);
}

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
