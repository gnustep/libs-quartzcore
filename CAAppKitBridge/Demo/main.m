#import "../Headers/CAAppKitBridge/CAData.h"
#import "../Headers/CAAppKitBridge/NSView+CAmethods.h"
#import <Foundation/Foundation.h>


int main(void) {
    NSView * view = [[NSView alloc]init];
    NSView * view2 = [[NSView alloc]init];
    NSView * view3 = [[NSView alloc]init];
    NSView * view3_5 = [[NSView alloc]init];
    NSView * view4 = [[NSView alloc]init];

    NSLog(@"%p %p %p %p",view,view2,view3,view4);

    [view addSubview:view2];
    [view2 addSubview:view3];
    [view2 addSubview:view3_5];
    [view3 addSubview:view4];

    NSLog(@"All set up!");

    NSLog(@"view wantsLayer value: %d", [view wantsLayer]);
    NSLog(@"view2 wantsLayer value: %d", [view2 wantsLayer]);
    NSLog(@"view3 wantsLayer value: %d", [view3 wantsLayer]);
    NSLog(@"view3_5 wantsLayer value: %d", [view3_5 wantsLayer]);
    NSLog(@"view4 wantsLayer value: %d", [view4 wantsLayer]);

    NSLog(@"Setting view2 wantsLayer to true");
    [view2 setWantsLayer:TRUE];
    NSLog(@"view wantsLayer value: %d", [view wantsLayer]);
    NSLog(@"view2 wantsLayer value: %d", [view2 wantsLayer]);
    NSLog(@"view3 wantsLayer value: %d", [view3 wantsLayer]);
    NSLog(@"view3_5 wantsLayer value: %d", [view3_5 wantsLayer]);
    NSLog(@"view4 wantsLayer value: %d", [view4 wantsLayer]);
/* FIX:
  openGLView = [[DemoOpenGLView alloc] initWithFrame: [[_window contentView] frame]
                                         pixelFormat: [DemoOpenGLView defaultPixelFormat]];
from AppControler.m */
    
    CARenderer *renderer = [[CARenderer alloc]init];

    NSLog(@"addCARenderer on root layer %p", view2);
    NSLog(@"%d",[view2 addCARenderer:renderer]);
    // test faulty set
    NSLog(@"addCARenderer on non-root layer %p");
    NSLog(@"%d",[view3 addCARenderer:renderer]);

    NSLog(@"removeCARenderer from root layer %p", view2);
    NSLog(@"%d",[view2 removeCARenderer]);
    // test faulty set
    NSLog(@"removeCARenderer from non-root layer %p");
    NSLog(@"%d",[view3 removeCARenderer]);
}