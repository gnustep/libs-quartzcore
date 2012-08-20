README
======

This is GNUstep QuartzCore, an implementation of the Core Animation APIs
intended for use with GNUstep. It's implemented in Objective-C and C.

Current codebase was written as part of Google Summer of Code 2012 by
Ivan Vučica.

Requirements
------------

*Last updated: August 20, 2012*

* **Foundation**. You can use GNUstep Base or Apple Cocoa to get Foundation.
* **AppKit**. You can use GNUstep GUI or Apple Cocoa to get AppKit.
* **OpenGL 2.0**. Code makes use of framebuffers for offscreen rendering and
  of fragment shaders for shadows. By manually removing blocks of code that 
  require framebuffers and shaders, it's probably possible to run the code on
  OpenGL any 1.1+ GPU. OpenGL ES 1.1 was previously supported, and will
  be supported again in the future along with ES 2.0.
* **Objective-C 2.0-supporting compiler**. Code has been tested with clang
  3.0, but it should in theory be possible to compile it with GCC 4.6+.
  This is primarily because it makes extensive use of the `@property`
  and `@synthesize` keywords, and (in the future) of `@dynamic`.
* **libobjc2**. While it may be possible to use the code with stock GCC
  runtime, the "new" GNUstep runtime is the only runtime code is being
  tested with. If you use Cocoa, Apple's "64-bit runtime" is also supported.
* **Patched Opal**. Opal currently conflicts with AppKit. More specifically,
  it also implements an incompatible `NSFont`. An experimental patch is
  provided against r35173 of Opal in `opal-nsfonthacks.patch`.
    * Opal requires Cairo and may require corebase.

API status
----------

*Last updated: August 20, 2012*

Following is a list of implemented features, and more importantly, not
implemented features, in no particular order. List is woefully incomplete,
but it should give an idea on what is the current status of the
implementation.

* **`CALayer`**: The only supported layer type.
  
    * Supports shadows, but ignores `shadowRadius` and `shadowPath`.
    * Does not support masking.
    * Does not support `-convert*` methods for conversion of geometry.
      Time conversion is supported.
    * Supports `backgroundColor`.
    * Supports setting `contents` to `CGImageRef`.
    * Supports painting into `contents` via a delegate.
    * Supports transforms and sublayer transforms.
    * Partial support for offscreen rendering triggered by 
      `shadowOpacity > 0` or `shouldRasterize == YES`. Texture is currently
      always 512x512, so your total layer contents in its local coordinate
      system need to be at most of that size. 
    * Implicit animations are implemented via KVO.
    * Dynamic properties created by subclasses are currently not supported.
    * `presentationLayer` is created during update triggered by a call to
      `-[CARenderer beginFrameAtTime:timeStamp:`
    * Setting `contents` is not animated, since currently there is no
      support for `CATransition`s.
    * Hosting `CGImageRef`s with indexed colorspace, or any other aside from
      RGBA, is not supported.
    * No support for layouts
    * No support for autoresizing
    * `frame` property is unsupported.

* **`CABasicAnimation`**: The only supported animation type.

    * `fromValue` and `toValue` must be of the same type. 
    * Handles number types, `CGPoint`s, `NSPoint`s, `NSRect`s, `CGRect`s,
     `CGColorRef`s.
    * Does not support `fillMode`.
    * `toValue` is allowed to be nil, in which case it will be picked up from
      the layer's associated `modelLayer`.
    * `fromValue` is allowed to be nil, in which case `CALayer` will set it
      to `presentationLayer`'s value when it notices it is nil.
    * `byValue` is not supported.
    * Timing functions are supported.
    * Value functions are not supported at this time.
    * Animating a `CATransform3D` with a scale component is broken.

* **`CARenderer`**: The only supported way of rendering. This means layers
  cannot be hosted in an `NSView` at this time.

    * `timeStamp` argument in `-[CARenderer beginFrameAtTime:timeStamp:]` is
      ignored.
    * In place of `-[CARenderer rendererWithCGLContext:options:`, currently
      only `-[CARenderer rendererWithNSOpenGLContext:options:` is provided.
      This is because of lack of `CoreGL` implementation on non-Apple
      platforms.

* **`CAMediaTimingFunction`**: Implementation is considered complete. It
  could use performance improvements and mathematical double-checking to the
  evaluation function, but otherwise this works.

* **`CATransaction`**: Complete for the most part. Used in implementation of
  implicit animations. Currently, the implicit transaction is not flushed
  nor created via `CFRunLoopObserver`s since GNUstep lacks them.

View-hosted layers
------------------

*Last updated: August 20, 2012*

Currently, there is no support for view-hosted layers. This can probably be
implemented as a category on `NSView`, aside from an i-var for storing the
layer (and perhaps `CARenderer` and a timer). It should be possible to attach
an `NSOpenGLContext` to any view.

Relationship to Opal
--------------------

*Last updated: August 20, 2012*

Due to large dependency of Core Animation and QuartzCore on Core Graphics,
implemented in GNUstep by Opal, code depends in large part on Opal and its
correct functioning. This means a few things need to be considered when using
Opal correctly.

Note that this is the state of the code at the time of writing of this
readme. Some problems may be resolved by the time you're reading this.

* **Conflicts between AppKit and Opal**: Surprisingly, Opal conflicts with
  AppKit. This is primarily in a single class: `NSFont`, which Opal also
  implements. Since QuartzCore currently also depends on `AppKit`
  due to its use of `NSOpenGLContext` -- otherwise it doesn't care about the
  UI framework used -- an experimental patch is provided. See
  `opal-nsfonthacks.patch`.

* **Opal sometimes returns 3 color components instead of 4**: Simply setting
  the alpha to 1 in that case seems to work correctly.

* **Opal's bitmap contexts are picky**: Number of supported argument
  combinations is somewhat small, and in some cases apparently buggy.
  For example, `kCGImageAlphaPremultipliedLast` is unsupported, but
  `kCGImageAlphaPremultipliedFirst` provides RGBA instead of ARGB.
  Also, colorspace created with `CGColorSpaceCreateDeviceRGB()` will not
  function, but `CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB)` will
  do just fine.

    This, naturally,  does not matter to you as long as you use contexts
  provided by `CALayer` to your delegate or subclass.

* **Opal's `CGImage` loading code may fail**: You may have to provide a
  hint on which image format you're feeding into Opal in the `options`
  argument of the `CGImageSource`.

* **QuartzCore supports only RGBA colors**: Wherever you are tempted to use
  another colorspace or RGB without the alpha -- well, don't, at least if the 
  data will be fed into QuartzCore. Whatever Opal and Cocoa Core Graphics may
  support, note that QuartzCore is currently only tested with RGBA colorspace.
  That means, no greyscale, no indexed colors, and no CMYK.

How to use
----------

*Last updated: August 20, 2012*

It's recommended that you take a look at the existing code in `Tests/` and
other online resources. This will be a quick overview of how to use the
currently available classes to spice up your application with a few
effects.

### Basic rendering

Core Animation is most commonly used under OS X and iOS. Under OS X, a view
can be "layer-backed"; that is, an `NSView` can host a layer. Either a layer
is provided by a view, or it's manually set in a view; alternatively, it can
also be added as a sublayer of another layer (for example, a view-hosted
layer). You typically turn on layer-backing by calling 
`[view setWantsLayer:YES];`. Under iOS, a layer hierarchy is magically
provided by the framework, and views exist only to provide layer content
and handle events. Once again, we can add our own sublayers to a particular
layer, without simultaneously creating a new view.

Under GNUstep, we currently have neither of these most commonly used ways
to access Core Animation. Instead, we create our own layer hierarchy from
the root downwards, and paint it inside an OpenGL context we also created.
This method of rendering using `CARenderer` is also available under OS X.
Primary difference is that the low-level Core GL context is not available
under GNUstep. Instead, we use AppKit's `NSOpenGLContext` (hence creating
our dependency on AppKit).

Creating an `NSOpenGLContext` (and `NSOpenGLView`, if you want one) is
already well documented. The easiest way is creation of `NSOpenGLView` and
adding it into the view hierarchy. It's created the same way an `NSView`
is. It's possible to subclass `NSOpenGLView`. Initialization code can be
placed in subclass's override of `-prepareOpenGL`. (Don't forget to call
superclass's implementation, though!) We place it there because we want to
be sure that OpenGL is initialized by the time we create any Core Animation
objects.

First thing we do during initialization is creation of a `CARenderer` object.
We also retain it in an i-var. Note that since this code is placed inside an 
`NSOpenGLView` subclass, `self` refers to an instance of an `NSOpenGLView` 
subclass.

    _renderer = [CARenderer rendererWithNSOpenGLContext: [self openGLContext]
                                                options: nil];
    [_renderer retain];

A renderer needs a root layer. Let's create one.

    CALayer * layer = [CALayer layer];
    [_renderer setLayer: layer];

Layer needs some setup. We'll keep it slightly smaller than the OpenGL view.
At the same time, we'll inform the renderer that the viewport it will be
rendering into is the same size as the OpenGL view. Background color is a
`CGColor` object, created using a Core Graphics method.

    [_renderer setBounds: NSRectToCGRect([self bounds])];
    [layer setBounds: CGRectMake(0, 0,
                                 [self frame].size.width*0.7, 
                                 [self frame].size.height*0.7)];
    CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);
    [layer setBackgroundColor: yellowColor];
    CGColorRelease(yellowColor);

Let's provide the layer with an opportunity to render some content by
providing a delegate. First we must implement the delegate class.
While we may determine the size in another way, e.g. via clipping area
of the `CGContext`, we'll simplify things by simply telling the delegate
how large the content it draws should be.

    @interface TheGreatDelegate : NSObject
    {
      CGSize _size;
    }
    @property (assign) CGSize size;
    - (void) drawLayer: (CALayer *)layer inContext: (CGContextRef) context;
    @end
    @implementation TheGreatDelegate
    @synthesize size=_size;
    - (void) drawLayer: (CALayer *)layer inContext: (CGContextRef) context;
    {
      float width = [self size].width;
      float height = [self size].height;
      
      /* Draw some content into the context */
      CGRect rect = CGRectMake(50, 50, width/2.0, height/2.0);
      CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
      CGContextSetRGBFillColor(context, 1, 0, 0, 1);
      CGContextSetLineWidth(context, 4.0);
      CGContextStrokeRect(context, rect);
      CGContextFillRect(context, rect);
    }
    @end

    // ... back in -prepareOpenGL
    
    TheGreatDelegate * delegate = [TheGreatDelegate new];
    [layer setDelegate: delegate];
    // We need to release the delegate ourselves at a later time.
    // As usual with delegates, this one is not retained by its owner
    // either.

Whenever we want a request to be sent to the delegate for painting content,
we need to inform the layer to do so via `-setNeedsDisplay`. We'll do so
after setting the delegate.

    [layer setNeedsDisplay];

(This would not be necessary if image was set as the layer contents.)

That's about it! We still need to do a few things before leaving
`-prepareOpenGL`, however, such as clearing out the render area. We want
to do this because this might be the last time we'll do it. We don't need to
clear the contents of the OpenGL viewport before drawing every frame. In fact,
we don't want to, because `CGRenderer` may in the future be intelligent
enough to tell us which area will be redrawn. (Cocoa's renderer already does
so.) Also, even now we don't want to clear the entire viewport before each
frame, because `CGRenderer` can already determine if it needs to redraw or
not.

So let's clear out the viewport.

    glViewport(0, 0, [self frame].size.width, [self frame].size.height);
    glClear(GL_COLOR_BUFFER_BIT);

Let's also set a timer. We'll have it autorepeat 60 times per second. While
in the future it may be possible to further optimize the rendering via
`-[CARenderer nextFrameTime]`, it currently is not possible because there is
no API for notifying the main app code about changes to `nextFrameTime` value.

    _timer = [NSTimer scheduledTimerWithTimeInterval: 1./60
                                              target: self
                                            selector: @selector(timerAnimation:)
                                            userInfo: nil
                                             repeats: YES];

(You could separate this into `-startAnimation`, and timer invalidation into
`-stopAnimation`.)

That's it for `-prepareOpenGL`! There is no need to release the `layer`,
since it's autoreleased already. If you wanted to keep it in an i-var,
you may want to `retain` it. (But strictly speaking, it's not necessary,
since the renderer will retain it for you.) what about releasing the delegate?
You'll want to save the delegate in an i-var and release it in your subclass's 
`-dealloc`. Or if you like messy code, just pull it out by using 
`[[_renderer layer] delegate]` in `-dealloc` and release it that way without
using an i-var.

So let's implement our `timerAnimation:` - the actual rendering code. It's
constantly repeating because that's the way we will achieve animation: by
allowing `CARenderer` a chance to paint the updated layer hierarchy with
applied animations (advanced for the animation step, as calculated from
the value of current time from `CACurrentMediaTime()`).

    - (void) timerAnimation: (NSTimer *)aTimer
    {
      [[self openGLContext] makeCurrentContext];
      
      glViewport(0, 0, [self frame].size.width, [self frame].size.height);

      glMatrixMode(GL_PROJECTION);
      glLoadIdentity();
      glOrtho(0, [self frame].size.width, 0, [self frame].size.height, -1, 1);
      
      glMatrixMode(GL_MODELVIEW);
      glLoadIdentity();

      /* */
      [_renderer beginFrameAtTime: CACurrentMediaTime()
                        timeStamp: NULL];
      [self clearBounds: [_renderer updateBounds]];
      [_renderer render];
      [_renderer endFrame];
      /* */
      
      glFlush();
      
      [[self openGLContext] flushBuffer];
    }

`CARenderer` expects most of OpenGL to be in the default state, except for
the projection matrix (which should be set to an ortographic projection with
renderer's bounds rectangle) and the viewport (also set to renderer's bounds
rectangle).

We need to begin rendering the frame and pass the current media time.
`timeStamp` can be NULL (and should be, since we currently don't support
Core Video). In GNUstep implementation, this line also executes the animations
and thus updates the `presentationLayer`, making possible for animations to
occur at all.

Then we can clear the background behind the area that the renderer will
paint into, let the renderer execute its painting code, and finally end
the frame, allowing the renderer to clean any mess it may have left behind.
At this point, OpenGL should be in the same state you were supposed to leave
it in before calling `-render`: everything default, except projection matrix
and the viewport. If anything is not at the default state, send a bug report.
The only thing that can be non-default is the existence of texture,
framebuffer and shader objects, or any such OpenGL object. (Caching is good!)

What about `clearBounds:`?

`clearBounds:` simply paints a black quad (the same color as the background,
so it looks like it's clearing out the existing contents).

    - (void)clearBounds:(CGRect)bounds
    {
      glBegin(GL_QUADS);
      glColor4f(0,0,0,1);
      glVertex2f(bounds.origin.x, bounds.origin.y);
      glVertex2f(bounds.origin.x+bounds.size.width, bounds.origin.y);
      glVertex2f(bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height);
      glVertex2f(bounds.origin.x, bounds.origin.y+bounds.size.height);
      glEnd();
    }

(Yes, `glBegin()`/`glEnd()` code written in 2012 or later. Does it matter? :-)


### Sublayers and animation

First let's add a sublayer. Let's go back to `-prepareOpenGL`.

    CGColorRef greenColor = CGColorCreateGenericRGB(0, 1, 0, 1);
    CALayer * layer2 = [CALayer layer];
    [layer2 setDelegate: delegate];
    [layer2 setBounds: CGRectMake (0, 0, 100, 100)];
    [layer2 setBackgroundColor: greenColor];
    [layer2 setNeedsDisplay];
    [layer addSublayer: layer2];
    CGColorRelease(greenColor);

    _layer = [layer retain];
    _layer2 = [layer2 retain];

We're reusing the old delegate. It'll use the same size to draw `layer2`'s
contents, but it doesn't matter as long as we see some content.

Also, note that we're using two new i-vars: `_layer` and `_layer2`. This is
because we'll be referring to our layers somewhere in the user interface
handling code. (You do know how to add the i-vars, right?)

Now you'll want to create some sort of a user interface that user can interact
with to trigger the animation. You can add a menu with two menu items, or
you can add two buttons; the choice is yours.

Now let's take a look at the two ways to create an animation.

    - (IBAction) animation1: (id)sender
    {
      CABasicAnimation *animation = 
        [CABasicAnimation animationWithKeyPath:@"position"];
      
      [animation setRemovesOnCompletion: YES];
      [animation setFromValue: 
        [[layer2 presentationLayer] valueForKeyPath:@"position]];
      [animation setToValue: 
        [NSValue valueWithPoint: NSMakePoint(50, 50)]];
      [animation setDuration: 0.25];
      [animation setTimingFunction: [CAMediaTimingFunction 
        functionWithName: kCAMediaTimingFunctionDefault]];
      
      [_layer2 addAnimation: animation forKey: @"someKey"];
    }

First line creates a so-called 'basic animation', the one that has a single
from-value and a single to-value (as opposed to a keyframe animation which
has multiple values). It'll be affecting the `position` key path of whatever
layer it is attached to.

Next line makes sure the animation gets removed from the layer upon
completion. You'll want to do this, since the animations created this way
don't affect actual `position` value of the object, but instead the value
that is displayed on screen.

How is that possible? Next line offers some insight. Every model layer has
an associated presentation layer; every presentation layer has an associated
model layer. For the `fromValue`, we'll take whatever is currently presented
on screen. This is also the default behavior in case `fromValue` is nil.

`toValue` would behave the other way around; it'd take the model layer value
and fill itself with it in. But in our case, we're filling the position with
a point `NSValue`. You may be wondering how come we're filling the position
with an `NSPoint` instead of a `CGPoint`. This is because although internally
Core Animation works with `CGPoint`s, it also supports `NSPoint` values.
If that line doesn't work, try this one (and report the issue):

    CGPoint pt = CGPointMake(50, 50);
    [animation setToValue: [NSValue valueWithBytes: &pt
                                          objCType: @encode(CGPoint)]];

Next line sets the duration. This is the default value of 0.25, that would
ordinarily be picked up from the nearest `CATransaction`. (Yes, there is an
implicitly created transaction, especially needed for implicitly created
animations.)

Timing function would also be picked up from the transaction, except the
default value is nil. And nil is not the same as the object identified with
`kCAMediaTimingFunctionDefault`; nil means a linear progression of time
in the specified animation, while `...Default` behaves the same way various
animations on iOS devices do. (Take a closer look, and look online for a
graph that displays progression of this timing function -- it's a bezier
curve that starts fast and slows down, but not in the same way `...EaseOut`
slows down.) Try skipping this line to see what happens. Also, try setting
nil and seeing what happens. 

Finally, we need to attach the animation to our smaller layer, the sublayer.
When we do this, as soon as the next frame starts rendering, we'll see the
animation taking effect.

The sublayer will appear to jump to its starting position... except it's not
actually jumping back. It was always there! The animation was affecting the
presentation layer, and as soon as the animation ended, so did its effect
upon the layer.

### Implicit animation

That was all nice, but how about simply telling an object to move to the
new position and observing it animate there?

As you can guess, the layer will actually jump there immediately. What will
actually make it appear to slowly go there is an animation that will be
implicitly attached to it.

    - (IBAction) animation2: (id)sender
    {
      static BOOL toggle = NO;
      if (!toggle)
        [layer2 setPosition: CGPointMake(50, 50)];
      else
        [layer2 setPosition: CGPointMake(0, 0)];
      toggle = !toggle;
    }

That's it! It would be a one-liner if we didn't want to be able to actually
go back to the original position.

### Complex animation

What about something crazier -- like having two animations applied to a
layer at once?

    CABasicAnimation * animation = [CABasicAnimation
      animationWithKeyPath:@"transform"];
    [animation setFromValue: [NSValue valueWithCATransform3D: 
      [_layer2 transform]]];
    [animation setToValue: [NSValue valueWithCATransform3D:
       CATransform3DTranslate(CATransform3DRotate([_layer2 transform],
       M_PI, 0, 0, 1), -150, 0, 0)]];
    [animation setDuration: 2];
    [animation setAutoreverses: YES];
    [_layer2 addAnimation: animation forKey: @"doABarrelRoll"];

    CABasicAnimation * opacity = [CABasicAnimation
      animationWithKeyPath:@"opacity"];
    [opacity setFromValue: [NSNumber numberWithFloat: [_layer2 opacity]]];
    [opacity setToValue: [NSNumber numberWithFloat: 0.5]];
    [opacity setDuration: 2];
    [opacity setAutoreverses: YES];
    [_layer2 addAnimation: opacity forKey: @"pulse"];

This attaches two animations that also automatically reverse to their initial
value. One of the animations is affecting the 4x4 transformation matrix that
transforms the layer in 3D space, in our case by translating it and rotating
it.

### What next?

Take a look at `Tests/` subdirectory, particularly at the `hello_animation.m`,
`hello_carenderer.m` and `offscreen_render.m` demos. Also, look online for 
more Core Animation and Core Graphics examples. There are also some awesome
books about these subjects; look around for them. Apple's documentation is
also nice for understanding what's happening.

There are many parts of the implementation that are still missing. If you 
you can contribute, please look at the procedure for assigning copyright to
the Free Software Foundation (a requirement for contributing to a GNU
project); it comes down to signing an agreement and sending it via snail mail
to FSF.


