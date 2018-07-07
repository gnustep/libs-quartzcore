#import "DemoController.h"

@implementation DemoController
- (void) applicationDidFinishLaunching: (id)t
{
  NSView * view = [[NSView alloc] init];
  NSView * view2 = [[NSView alloc] init];
  NSView * view3 = [[NSView alloc] init];
  NSView * view3_5 = [[NSView alloc] init];
  NSView * view4 = [[NSView alloc] init];

  NSLog(@"%p %p %p %p %p", view, view2, view3, view3_5, view4);

  [view addSubview: view2];
  [view2 addSubview: view3];
  [view2 addSubview: view3_5];
  [view3 addSubview: view4];

  NSLog(@"view wantsLayer value: %d", [view wantsLayer]);
  NSLog(@"view2 wantsLayer value: %d", [view2 wantsLayer]);
  NSLog(@"view3 wantsLayer value: %d", [view3 wantsLayer]);
  NSLog(@"view3_5 wantsLayer value: %d", [view3_5 wantsLayer]);
  NSLog(@"view4 wantsLayer value: %d", [view4 wantsLayer]);

  NSLog(@"Setting view2 wantsLayer to true");
  [view2 setWantsLayer: YES];
  NSLog(@"view wantsLayer value: %d", [view wantsLayer]);
  NSLog(@"view2 wantsLayer value: %d", [view2 wantsLayer]);
  NSLog(@"view3 wantsLayer value: %d", [view3 wantsLayer]);
  NSLog(@"view3_5 wantsLayer value: %d", [view3_5 wantsLayer]);
  NSLog(@"view4 wantsLayer value: %d", [view4 wantsLayer]);

  CARenderer *renderer = [[CARenderer alloc] init];

  NSLog(@"addCARenderer on root layer %p", view2);
  NSLog(@"Success: %d", [view2 _gsAddCARenderer: renderer]); // Also creates OpenGL context
  NSLog(@"addCARenderer on non-root layer %p", view3);
  NSLog(@"Success: %d", [view3 _gsAddCARenderer: renderer]);

  NSLog(@"removeCARenderer from root layer %p", view2);
  NSLog(@"Success: %d", [view2 _gsRemoveCARenderer]);
  NSLog(@"removeCARenderer from non-root layer %p", view3);
  NSLog(@"Success: %d" ,[view3 _gsRemoveCARenderer]);
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed: (id)sender
{
  return YES;
}

-(void)dealloc
{
  [super dealloc];
}

@end
