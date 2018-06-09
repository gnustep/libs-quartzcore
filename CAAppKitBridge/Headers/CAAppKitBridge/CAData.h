#import <AppKit/NSView.h>
#import <QuartzCore/QuartzCore.h>

@interface  CAData : NSView
{
    @public
    BOOL            _wantsLayer;
    BOOL            _isOriginalReciever; // is this NSView the "root"?
    CARenderer *    _renderer; // NIL if _isOriginalReciever == NO
    CALayer    *    _layer;
}
@end
