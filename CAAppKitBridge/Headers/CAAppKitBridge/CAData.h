#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

@interface  CAData : NSView
{
    @public
    BOOL            _wantsLayer;
    BOOL            _isRootLayer; // is this NSView the "root"?
    CARenderer *    _renderer; // NIL if _isOriginalReciever == NO
    CALayer    *    _layer;


    /* from libs-gui/Headers/AppKit/NSOpenGlView.h */

    NSOpenGLContext 	*_glcontext;
  	NSOpenGLPixelFormat	*_pixel_format; //<- Check Apple behavior for propagating this
  	BOOL				_prepared;
}
@end
