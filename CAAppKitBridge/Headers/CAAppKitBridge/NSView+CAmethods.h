#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

@interface  NSView (NSViewCAmethods)
@property BOOL wantsLayer;
- (CALayer *) makeBackingLayer;
@end
