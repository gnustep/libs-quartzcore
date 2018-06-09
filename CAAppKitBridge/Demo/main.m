#import "../Headers/CAAppKitBridge/CAData.h"
#import "../Headers/CAAppKitBridge/NSView+CAmethods.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

int main(void) {
    NSView * vju = [[NSView alloc]init];
    NSView * vju2 = [[NSView alloc]init];
    NSView * vju3 = [[NSView alloc]init];
    NSView * vju3ipol = [[NSView alloc]init];
    NSView * vju4 = [[NSView alloc]init];

    [vju addSubview:vju2];
    [vju2 addSubview:vju3];
    [vju2 addSubview:vju3ipol];
    [vju3 addSubview:vju4];

    NSLog(@"All set up!");

    NSLog(@"vju wantsLayer value: %d", [vju wantsLayer]);
    NSLog(@"vju2 wantsLayer value: %d", [vju2 wantsLayer]);
    NSLog(@"vju3 wantsLayer value: %d", [vju3 wantsLayer]);
    NSLog(@"vju3ipol wantsLayer value: %d", [vju3ipol wantsLayer]);
    NSLog(@"vju4 wantsLayer value: %d", [vju4 wantsLayer]);

    NSLog(@"Setting vju2 wantsLayer to true");
    [vju2 setWantsLayer:TRUE];
    NSLog(@"vju wantsLayer value: %d", [vju wantsLayer]);
    NSLog(@"vju2 wantsLayer value: %d", [vju2 wantsLayer]);
    NSLog(@"vju3 wantsLayer value: %d", [vju3 wantsLayer]);
    NSLog(@"vju3ipol wantsLayer value: %d", [vju3ipol wantsLayer]);
    NSLog(@"vju4 wantsLayer value: %d", [vju4 wantsLayer]);

}
