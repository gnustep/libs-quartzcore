/* 
   CARenderer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: March 2012

   This file is part of QuartzCore.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/Foundation.h>
#import "QuartzCore/CARenderer.h"
#import "QuartzCore/CATransform3D.h"
#import "QuartzCore/CALayer.h"
#import "CALayer+FrameworkPrivate.h"
#import "CATransaction+FrameworkPrivate.h"
#import "CABackingStore.h"
#if !(__APPLE__)
#import <GL/gl.h>
#import <GL/glu.h>
#else
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#endif
#import <AppKit/NSOpenGL.h>

#import "GLHelpers/CAGLTexture.h"
#import "GLHelpers/CAGLSimpleFramebuffer.h"
#import "GLHelpers/CAGLShader.h"
#import "GLHelpers/CAGLProgram.h"

#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

@interface CARenderer()
@property (assign) NSOpenGLContext *GLContext;
- (void) _determineAndScheduleRasterizationForLayer: (CALayer *) layer;
- (void) _scheduleRasterization: (CALayer *) layer;
- (void) _rasterize: (NSDictionary *) rasterizationSpec;
- (void) _rasterizeAll;
@end

@implementation CARenderer
@synthesize layer=_layer;
@synthesize bounds=_bounds;

@synthesize GLContext=_GLContext;

/* *** class methods *** */
/* Creates a renderer which renders into an OpenGL context. */
+ (CARenderer*) rendererWithNSOpenGLContext: (NSOpenGLContext*)ctx
                                    options: (NSDictionary*)options;
{
  return [[[self alloc] initWithNSOpenGLContext: ctx 
	                                options: options] autorelease];
}

/* *** methods *** */

- (id) initWithNSOpenGLContext: (NSOpenGLContext*)ctx
                       options: options
{
  if ((self = [super init]) != nil)
    {
      [self setGLContext: ctx];
      
      /* SHADER SETUP */
      [ctx makeCurrentContext];

      /* Simple, passthrough shader */
      CAGLVertexShader * simpleVS = [CAGLVertexShader alloc];
      simpleVS = [simpleVS initWithFile: @"simple"
                                 ofType: @"vsh"];
      CAGLFragmentShader * simpleFS = [CAGLFragmentShader alloc];
      simpleFS = [simpleFS initWithFile: @"simple"
                                 ofType: @"fsh"];
      NSArray * objectsForSimpleShader = [NSArray arrayWithObjects: simpleVS, simpleFS, nil];
      [simpleVS release];
      [simpleFS release];

      CAGLProgram * simpleProgram = [CAGLProgram alloc];
      simpleProgram = [simpleProgram initWithArrayOfShaders: objectsForSimpleShader];
      [simpleProgram link];
      _simpleProgram = simpleProgram;
      
      /* Horizontal and vertical blur shader */
      CAGLVertexShader * blurBaseVS = [CAGLVertexShader alloc];
      blurBaseVS = [blurBaseVS initWithFile: @"blurbase"
                                     ofType: @"vsh"];
      CAGLFragmentShader * blurHorizFS = [CAGLFragmentShader alloc];
      blurHorizFS = [blurHorizFS initWithFile: @"blurhoriz"
                                       ofType: @"fsh"];
      CAGLFragmentShader * blurVertFS = [CAGLFragmentShader alloc];
      blurVertFS = [blurVertFS initWithFile: @"blurvert"
                                     ofType: @"fsh"];
      NSArray * objectsForBlurHorizShader = [NSArray arrayWithObjects: blurBaseVS, blurHorizFS, nil];
      NSArray * objectsForBlurVertShader = [NSArray arrayWithObjects: blurBaseVS, blurVertFS, nil];
      [blurBaseVS release];
      [blurHorizFS release];
      [blurVertFS release];
      
      CAGLProgram * blurHorizProgram = [CAGLProgram alloc];
      blurHorizProgram = [blurHorizProgram initWithArrayOfShaders: objectsForBlurHorizShader];
      [blurHorizProgram link];
      _blurHorizProgram = blurHorizProgram;
      
      CAGLProgram * blurVertProgram = [CAGLProgram alloc];
      blurVertProgram = [blurVertProgram initWithArrayOfShaders: objectsForBlurVertShader];
      [blurVertProgram link];
      _blurVertProgram = blurVertProgram;
      
    }
  return self;
}

- (void) dealloc
{
  [_layer release];
  [_rasterizationSchedule release];
  
  /* Release all GL programs */
  [_simpleProgram release];
  [_blurHorizProgram release];
  [_blurVertProgram release];
  
  [super dealloc];
}

- (void)setBounds: (CGRect)bounds
{
  _bounds = bounds;
  
  /* This value is returned from -updateBounds in case nothing has changed */
  _updateBounds = CGRectMake(__builtin_inf(), __builtin_inf(), 0, 0);
  
  [self addUpdateRect: bounds];
}
/* Adds a rectangle to the update region. */
- (void) addUpdateRect: (CGRect)updateRect
{
  if(isinf(_updateBounds.origin.x) && isinf(_updateBounds.origin.y))
    _updateBounds = updateRect;
  else
    _updateBounds = CGRectUnion(_updateBounds, updateRect);
}

/* Begins rendering a frame at the specified time.
   Timestamp is currently ignored. */
- (void) beginFrameAtTime: (CFTimeInterval)timeInterval
                timeStamp: (CVTimeStamp *)timeStamp
{
  if (!_firstRender)
    {
      _firstRender = timeInterval;
    }
  if([[CATransaction topTransaction] isImplicit])
    {
      [CATransaction commit];
    }
  _nextFrameTime = __builtin_inf();
  
  /* Prepare for rasterization */
  [_rasterizationSchedule release];
  _rasterizationSchedule = [[NSMutableArray alloc] init];
  
  /* Update layers (including determining and scheduling rasterization) */
  [self _updateLayer: _layer atTime: timeInterval];
  
}

/* Ends rendering the frame, releasing any temporary data. */
- (void) endFrame
{
  /* This value is returned from -updateBounds in case nothing has changed */
  _updateBounds = CGRectMake(__builtin_inf(), __builtin_inf(), 0, 0);
}
/* Returns time at which next update should be performed.
   Current time denotes continuous animation and next update
   should be scheduled as soon as appropriate. Infinity denotes
   that no update should be scheduled. */
- (CFTimeInterval) nextFrameTime
{
  return _nextFrameTime;
}

/* Renders a frame to the target context. Best case scenario, it 
   should be rendering the update region only. */
- (void) render
{
  /* If we have nothing to render, just skip rendering */
  CGRect updateBounds = [self updateBounds];
  if (isinf(updateBounds.origin.x) &&
      isinf(updateBounds.origin.y))
    return;

  [_GLContext makeCurrentContext];

  glMatrixMode(GL_MODELVIEW);
  
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  
  [self _rasterizeAll];
  
  /* Perform render */
  [self _renderLayer: [[self layer] presentationLayer]
       withTransform: CATransform3DIdentity];
       
  /* Restore defaults */
  glMatrixMode(GL_MODELVIEW);
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ZERO);
  glLoadIdentity();
}

/* Returns rectangle containing all pixels that should be updated. */
- (CGRect) updateBounds
{
  /* TODO: This one is important to implement, and then make use of,
     in order to keep the number of layers that are rendered to a
     minimum. This is the method Apple seems to use to keep down the
     amount of content rendered upon screen refresh.
     
     https://mail.mozilla.org/pipermail/plugin-futures/2010-March/000023.html

     This quote: "A -render with nothing to do is cheap." leads me to
     believe that -render is actually repeatedly ran, but that it's counted
     on that most often, nothing will be painted. 
     
     Value of -updateBounds is apparently calculated in -beginFrameAtTime:timeStamp:.
     This makes sense and we'll do the same.
     */

  if (isinf(_nextFrameTime))
    return _updateBounds;

  /* for the time being, we return entire renderer as needing a redraw. */
  return [self bounds];
}

/* *********************** */
/* MARK: - Private methods */

/* Internal method that updates a single presentation layer and then proceeds by recursing, updating its children. */
- (void) _updateLayer: (CALayer *)layer
               atTime: (CFTimeInterval)theTime
{
  if ([layer modelLayer])
    layer = [layer modelLayer];

  [CALayer setCurrentFrameBeginTime: theTime];
  
  /* Destroy and then recreate the presentation layer.
     This is the easiest way to reset it to default values. */
  [layer discardPresentationLayer];
  CALayer * presentationLayer = [layer presentationLayer];
  
  /* Tell the presentation layer to apply animations. */
  /* Also, determine nextFrameTime */
  _nextFrameTime = MIN(_nextFrameTime, [presentationLayer applyAnimationsAtTime: theTime]);
  _nextFrameTime = MAX(_nextFrameTime, theTime);
  
  /* Tell all children to update themselves. */
  for (CALayer * sublayer in [layer sublayers])
    {
      [self _updateLayer: sublayer
                  atTime: theTime];
    }

  /* Now that children have had a chance to determine
     whether they need to be rendered offscreen, the layer itself
     can determine it, too. */
  /* (Order is important, because the deeper the layer is, earlier
     it needs to be offscreen-rendered.) */
     
  /* TODO: */
  /* First, allow mask layer to determine this, since it's deeper than
     the current layer. */
  #if 0
  [self _determineAndScheduleRasterizationForLayer: [layer mask]];
  #endif
  
  /* Then permit current layer to determine rasterization */
  [self _determineAndScheduleRasterizationForLayer: layer];
}
/* Internal method that renders a single layer and then proceeds by recursing, rendering its children. */
- (void) _renderLayer: (CALayer *)layer
        withTransform: (CATransform3D)transform
{
  if (![layer isPresentationLayer])
    layer = [layer presentationLayer];
  
      
  // if the layer was offscreen-rendered, render just the texture
  CAGLTexture * texture = [[layer backingStore] offscreenRenderTexture];
  if (texture)
    {
      transform = CATransform3DTranslate(transform, [layer position].x, [layer position].y, 0);
      if (sizeof(transform.m11) == sizeof(GLdouble))
        glLoadMatrixd((GLdouble*)&transform);
      else
        glLoadMatrixf((GLfloat*)&transform);

      /* have to paint shadow? */
      if ([layer shadowOpacity] > 0.0)
        {
          /* first paint shadow */
          
          /* TODO: we might be able to skip blurring in case radius == 1. */
          /* TODO: shouldRasterize means that shadow should be included in
                   rasterized bitmap. Currently, we still render shadow separately */
          
          /* here, we do blurring in two passes. first horizontal, then vertical. */
          /* IDEA: perform blurring during offscreen-rendering, so we group all
                   FBO operations in once place? */
          
          /* TODO: these not correct sizes for shadow rasterization */
          const GLuint shadow_rasterize_w = 512, shadow_rasterize_h = 512;
          
          CATransform3D shadowRasterizeTransform = CATransform3DMakeTranslation(shadow_rasterize_w/2.0, shadow_rasterize_h/2.0, 0);
          CATransform3D rasterizedTextureTransform = CATransform3DMakeTranslation([texture width]/2.0, [texture height]/2.0, 0);
          
          
          /* Setup transform for first pass */
          if (sizeof(rasterizedTextureTransform.m11) == sizeof(GLdouble))
            glLoadMatrixd((GLdouble*)&rasterizedTextureTransform);
          else
            glLoadMatrixf((GLfloat*)&rasterizedTextureTransform);

          /* Setup FBO for first pass */
          CAGLSimpleFramebuffer * framebuffer = [[CAGLSimpleFramebuffer alloc] initWithWidth: shadow_rasterize_w height: shadow_rasterize_h];
          [framebuffer bind];
          
          glClearColor(0.0, 0.0, 0.0, 0.0);
          glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

          /* Render first pass */
          [_blurHorizProgram use];
          GLint loc = [_blurHorizProgram locationForUniform:@"RTScene"];
          [_blurHorizProgram bindUniformAtLocation: loc
                                     toUnsignedInt: 0];
          
          // TODO: replace use of glBegin()/glEnd()
          [texture bind];
          
          GLfloat textureMaxX = 1.0, textureMaxY = 1.0;
          if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
            {
              textureMaxX = [texture width];
              textureMaxY = [texture height];
            }
          else
            {
              glTexParameteri([texture textureTarget], GL_TEXTURE_MIN_FILTER, GL_LINEAR);
              glTexParameteri([texture textureTarget], GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            }
          
          glBegin(GL_QUADS);
          glTexCoord2f(0, 0);
          glVertex2f(-[texture width]/2.0, -[texture height]/2.0);
          glTexCoord2f(0, textureMaxY);
          glVertex2f(-[texture width]/2.0, [texture height]/2.0);
          glTexCoord2f(textureMaxX, textureMaxY);
          glVertex2f([texture width]/2.0, [texture height]/2.0);
          glTexCoord2f(textureMaxX, 0);
          glVertex2f([texture width]/2.0, -[texture height]/2.0);
          glEnd();
          glDisable([texture textureTarget]);
          
          
          glUseProgram(0);

          [texture unbind];
          [framebuffer unbind];
                        
          /* Preserve the FBO texture and discard framebuffer */
          CAGLTexture * firstPassTexture = [[framebuffer texture] retain];
          [framebuffer release];
          
          /************************************/
          
          /* Setup transform for second pass */
          if (sizeof(shadowRasterizeTransform.m11) == sizeof(GLdouble))
            glLoadMatrixd((GLdouble*)&shadowRasterizeTransform);
          else
            glLoadMatrixf((GLfloat*)&shadowRasterizeTransform);
           
          
          /* Setup FBO for second pass */
          framebuffer = [[CAGLSimpleFramebuffer alloc] initWithWidth: shadow_rasterize_w height: shadow_rasterize_h];
          [framebuffer bind];
          
          glDisable([[framebuffer texture] textureTarget]);

          glClearColor(0.0, 0.0, 0.0, 0.0);
          glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);


          /* Render second pass */
          [_blurVertProgram use];
          loc = [_blurVertProgram locationForUniform: @"RTBlurH"];
          [_blurVertProgram bindUniformAtLocation: loc
                                     toUnsignedInt: 0];
          loc = [_blurVertProgram locationForUniform: @"shadowColor"];
          GLfloat components[4] = { 0 };
          if (CGColorGetNumberOfComponents([layer shadowColor]) == 4)
            {
              const CGFloat * componentsOrig = CGColorGetComponents([layer shadowColor]);
              components[0] = componentsOrig[0];
              components[1] = componentsOrig[1];
              components[2] = componentsOrig[2];
              components[3] = componentsOrig[3];
              components[3] *= [layer shadowOpacity];
            }
          else
            {
              NSLog(@"Invalid number of color components in shadowColor");
            }

          [_blurVertProgram bindUniformAtLocation: loc
                                        toFloat4v: components];
                                        
          // TODO: replace use of glBegin()/glEnd()
          [firstPassTexture bind];
          
          GLfloat firstPassTextureMaxX = 1.0, firstPassTextureMaxY = 1.0;
          if ([firstPassTexture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
            {
              firstPassTextureMaxX = [firstPassTexture width];
              firstPassTextureMaxY = [firstPassTexture height];
            }
          else
            {
              glTexParameteri([firstPassTexture textureTarget], GL_TEXTURE_MIN_FILTER, GL_LINEAR);
              glTexParameteri([firstPassTexture textureTarget], GL_TEXTURE_MAG_FILTER, GL_LINEAR);

            }
          glBegin(GL_QUADS);
          glTexCoord2f(0, 0);
          glVertex2f(-[firstPassTexture width]/2.0, -[firstPassTexture height]/2.0);
          glTexCoord2f(0, firstPassTextureMaxY);
          glVertex2f(-[firstPassTexture width]/2.0, [firstPassTexture height]/2.0);
          glTexCoord2f(firstPassTextureMaxX, firstPassTextureMaxY);
          glVertex2f([firstPassTexture width]/2.0, [firstPassTexture height]/2.0);
          glTexCoord2f(firstPassTextureMaxX, 0);
          glVertex2f([firstPassTexture width]/2.0, -[firstPassTexture height]/2.0);
          glEnd();
          glDisable([firstPassTexture textureTarget]);
          
          glUseProgram(0);

          [firstPassTexture unbind];
          [framebuffer unbind];
          
          /* Preserve the FBO texture and discard framebuffer */
          CAGLTexture * secondPassTexture = [[framebuffer texture] retain];
          [framebuffer release];
          
          /************************************/
          
          /* Finally! Draw shadow into draw buffer */
          if (sizeof(transform.m11) == sizeof(GLdouble))
            glLoadMatrixd((GLdouble*)&transform);
          else
            glLoadMatrixf((GLfloat*)&transform);
          glTranslatef([layer shadowOffset].width, [layer shadowOffset].height, 0);

          [secondPassTexture bind];

          GLfloat secondPassTextureMaxX = 1.0, secondPassTextureMaxY = 1.0;
          if ([secondPassTexture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
            {
              secondPassTextureMaxX = [secondPassTexture width];
              secondPassTextureMaxY = [secondPassTexture height];
            }
          else
            {
              glTexParameteri([secondPassTexture textureTarget], GL_TEXTURE_MIN_FILTER, GL_LINEAR);
              glTexParameteri([secondPassTexture textureTarget], GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            }
          glBegin(GL_QUADS);
          glTexCoord2f(0, 0);
          glVertex2f(-[secondPassTexture width]/2.0, -[secondPassTexture height]/2.0);
          glTexCoord2f(0, secondPassTextureMaxY);
          glVertex2f(-[secondPassTexture width]/2.0, [secondPassTexture height]/2.0);
          glTexCoord2f(secondPassTextureMaxX, secondPassTextureMaxY);
          glVertex2f([secondPassTexture width]/2.0, [secondPassTexture height]/2.0);
          glTexCoord2f(secondPassTextureMaxX, 0);
          glVertex2f([secondPassTexture width]/2.0, -[secondPassTexture height]/2.0);
          glEnd();
          glDisable([secondPassTexture textureTarget]);
          
          [firstPassTexture release];
          [secondPassTexture release];
          
          /* Without shadow offset */
          if (sizeof(transform.m11) == sizeof(GLdouble))
            glLoadMatrixd((GLdouble*)&transform);
          else
            glLoadMatrixf((GLfloat*)&transform);

        }

      #warning Intentionally coloring offscreen-rendered layer
      glColor3f(0.4, 1.0, 1.0);
      
      #warning Intentionally applying shader to offscreen-rendered layer
      [_simpleProgram use];
      GLint loc;
      if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
        loc = [_simpleProgram locationForUniform:@"texture_2drect"];
      else
        loc = [_simpleProgram locationForUniform:@"texture_2d"];
      
      [_simpleProgram bindUniformAtLocation: loc
                              toUnsignedInt: 0];
      
      
      // TODO: replace use of glBegin()/glEnd()
      [texture bind];
      
      GLfloat textureMaxX = 1.0, textureMaxY = 1.0;
      if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
        {
          textureMaxX = [texture width];
          textureMaxY = [texture height];
        }
      else
        {
          glTexParameteri([texture textureTarget], GL_TEXTURE_MIN_FILTER, GL_LINEAR);
          glTexParameteri([texture textureTarget], GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        }
            
      glBegin(GL_QUADS);
      glTexCoord2f(0, 0);
      glVertex2f(-256, -256);
      glTexCoord2f(0, textureMaxY);
      glVertex2f(-256, 256);
      glTexCoord2f(textureMaxX, textureMaxY);
      glVertex2f(256, 256);
      glTexCoord2f(textureMaxX, 0);
      glVertex2f(256, -256);
      glEnd();
      glDisable([texture textureTarget]);
      
      #warning Intentionally coloring offscreen-rendered layer
      glColor3f(1.0, 1.0, 1.0);
      #warning Intentionally applying shader to offscreen-rendered layer
      glUseProgram(0);
      
      return;
    }


  
  // apply transform and translate to position
  transform = CATransform3DTranslate(transform, [layer position].x, [layer position].y, 0);
  transform = CATransform3DConcat([layer transform], transform);
  
  if (sizeof(transform.m11) == sizeof(GLdouble))
    glLoadMatrixd((GLdouble*)&transform);
  else
    glLoadMatrixf((GLfloat*)&transform);

  [layer displayIfNeeded];

  // fill vertex arrays
  GLfloat vertices[] = {
    0.0, 0.0,
    [layer bounds].size.width, 0.0,
    [layer bounds].size.width, [layer bounds].size.height,
    
    [layer bounds].size.width, [layer bounds].size.height,
    0.0, [layer bounds].size.height,
    0.0, 0.0,
  };
  CGRect cr = [layer contentsRect];
  GLfloat texCoords[] = {
    cr.origin.x,                 1.0 - (cr.origin.y),
    cr.origin.x + cr.size.width, 1.0 - (cr.origin.y),
    cr.origin.x + cr.size.width, 1.0 - (cr.origin.y + cr.size.height),
    
    cr.origin.x + cr.size.width, 1.0 - (cr.origin.y + cr.size.height),
    cr.origin.x,                 1.0 - (cr.origin.y + cr.size.height),
    cr.origin.x,                 1.0 - (cr.origin.y),
  };
  GLfloat whiteColor[] = {
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
  };
  GLfloat backgroundColor[] = {
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
  };
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
  
  // apply anchor point
  for (int i = 0; i < 6; i++)
    {
      vertices[i*2 + 0] -= [layer anchorPoint].x * [layer bounds].size.width;
      vertices[i*2 + 1] -= [layer anchorPoint].y * [layer bounds].size.height;
    }

  // apply opacity to white color
  for (int i = 0; i < 6; i++)
    {
        whiteColor[i*4 + 3] *= [layer opacity];
    }

  // apply background color
  if ([layer backgroundColor] && CGColorGetAlpha([layer backgroundColor]) > 0)
    {
      const CGFloat * componentsCG = CGColorGetComponents([layer backgroundColor]);
      GLfloat components[4];
      
      // convert
      components[0] = componentsCG[0];
      components[1] = componentsCG[1];
      components[2] = componentsCG[2];
      components[3] = componentsCG[3];
      
      // apply opacity
      components[3] *= [layer opacity];
      
      // FIXME: here we presume that color contains RGBA channels.
      // However this may depend on colorspace, number of components et al
      memcpy(backgroundColor + 0*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 1*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 2*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 3*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 4*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 5*4, components, sizeof(GLfloat)*4);
      glColorPointer(4, GL_FLOAT, 0, backgroundColor);
      
      glDrawArrays(GL_TRIANGLES, 0, 6);
    }

  // if there are some contents, draw them
  if ([layer contents])
    {
      CAGLTexture * texture = nil;
      id layerContents = [layer contents];
      
      if ([layerContents isKindOfClass: [CABackingStore class]])
        {
          CABackingStore * backingStore = layerContents;

          texture = [backingStore contentsTexture];
        }
#if GNUSTEP
      else if ([layerContents isKindOfClass: [CGImage class]])
#else
      else if ([layerContents isKindOfClass: NSClassFromString(@"__NSCFType")] &&
               CFGetTypeID(layerContents) == CGImageGetTypeID())
#endif
        {
          CGImageRef image = (CGImageRef)layerContents;
          
          texture = [CAGLTexture texture];
          [texture loadImage: image];
        }
      
      if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
        {
          /* Rectangle textures use non-normalized coordinates. */
          
          for (int i = 0; i < 6; i++)
            {
              texCoords[i*2 + 0] *= [texture width];
              texCoords[i*2 + 1] *= [texture height];
            }
        }
      
      [texture bind];
      glColorPointer(4, GL_FLOAT, 0, whiteColor);
      glDrawArrays(GL_TRIANGLES, 0, 6);
      [texture unbind];

    }

  transform = CATransform3DConcat ([layer sublayerTransform], transform);
  transform = CATransform3DTranslate (transform, -[layer bounds].size.width/2, -[layer bounds].size.height/2, 0);
  for (CALayer * sublayer in [layer sublayers])
    {
      [self _renderLayer: sublayer withTransform: transform];
    }
}

- (void) _determineAndScheduleRasterizationForLayer: (CALayer*)layer
{
  BOOL shouldRasterize = NO;
  /* Whether a layer needs to be rasterized is complex to determine,
     but the first thing to check is user-specifiable property
     'shouldRasterize'. */
  if (!shouldRasterize && [[layer presentationLayer] shouldRasterize])
    {
      shouldRasterize = YES;
    }
    
  if (!shouldRasterize && [[layer presentationLayer] shadowOpacity] > 0.0)
    {
      shouldRasterize = YES;
    }
  
  /* Now, based on results, either rasterize or invalidate rasterization */
  if (shouldRasterize)
    [self _scheduleRasterization: layer];
  else
    [[layer backingStore] setOffscreenRenderTexture: nil];
  
}

- (void) _scheduleRasterization: (CALayer *)layer
{
  NSMutableDictionary * rasterizationSpec = [NSMutableDictionary new];
  
  [rasterizationSpec setValue: layer forKey: @"layer"];
  [_rasterizationSchedule addObject: rasterizationSpec];
  [rasterizationSpec release];
}

- (void) _rasterize: (NSDictionary*) rasterizationSpec
{
  CALayer * layer = [rasterizationSpec valueForKey: @"layer"];
  
  /* we need to render the presentationLayer */
  if (![layer isPresentationLayer])
    layer = [layer presentationLayer];

  /* Empty the cache so redraw gets performed in -[CARenderer _renderLayer:withTransform:] */
  [[layer backingStore] setOffscreenRenderTexture: nil];

  // TODO: 512x512 is NOT correct, we need to determine the actual layer size together with sublayers
  const GLuint rasterize_w = 512, rasterize_h = 512;
  CAGLSimpleFramebuffer * framebuffer = [[CAGLSimpleFramebuffer alloc] initWithWidth: rasterize_w height: rasterize_h];
  [framebuffer setDepthBufferEnabled: YES];
  [framebuffer bind];
    
  glDisable([[framebuffer texture] textureTarget]);

  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  [self _renderLayer: layer withTransform: CATransform3DMakeTranslation(rasterize_w/2.0 - [layer position].x, rasterize_h/2.0 - [layer position].y, 0)];
  
  [framebuffer unbind];
  
  if (![layer backingStore])
    [layer setBackingStore: [CABackingStore backingStoreWithWidth: rasterize_w height: rasterize_h]];
  [[layer backingStore] setOffscreenRenderTexture: [framebuffer texture]];
  
  [framebuffer release];
}


- (void) _rasterizeAll
{
  /* Rasterize */
  for (NSDictionary * rasterizationSpec in _rasterizationSchedule)
  {
    [self _rasterize: rasterizationSpec];
  }
  
  /* Release rasterization schedule */
  [_rasterizationSchedule release];
  _rasterizationSchedule = nil;
}



@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
