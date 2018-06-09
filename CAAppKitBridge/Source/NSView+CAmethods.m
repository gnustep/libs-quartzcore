#import "CAAppKitBridge/CAData.h"
#import "CAAppKitBridge/NSView+CAmethods.h"
#import <Foundation/Foundation.h>

@implementation NSView (NSViewCAmethods)
- (BOOL) wantsLayer {
    if (self->_coreAnimationData == nil) {
        return NO;
    }
    CAData * cadata = self->_coreAnimationData;
    return cadata->_wantsLayer;
}
- (void) setWantsLayer:(BOOL) newValue{
    if (newValue == NO){
        return;
    }

    // Initialise new CAData if setWantsLayer:YES
    CAData * cadata = [[CAData alloc]init];
    cadata->_wantsLayer = YES;
    cadata->_isOriginalReciever = YES;
    cadata->_layer = [self makeBackingLayer];
    // Attach cadata to self
    self->_coreAnimationData = cadata;

    // Call _recursiveSubtreePropagation recursively on all the subviews
    for (NSView *currView in [self subviews])
    {
        [currView _recursiveSubviewsPropagation];
    }
}

-(void) _recursiveSubviewsPropagation {
    // Initialise new CAData instance
    CAData * cadata = [[CAData alloc]init];
    cadata->_wantsLayer = NO; // A bit unintuitive, but default Apple behaviour.
    cadata->_isOriginalReciever = NO;
    cadata->_layer = [self makeBackingLayer];
    // Attach cadata to self
    self->_coreAnimationData = cadata;

    // Attach our CALayer to its superView CALayer
    NSView * superView = [self superview];
    if(superView != nil){
        CAData * supercadata = superView->_coreAnimationData;
        [supercadata->_layer addSublayer:cadata->_layer];
    }

    // Call wantsLayer recursively on all the subviews
    for (NSView *currView in [self subviews])
    {
        [currView _recursiveSubviewsPropagation];
    }


}

-(CALayer *) makeBackingLayer {
    return [CALayer layer];
}
@end
