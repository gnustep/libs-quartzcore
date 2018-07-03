/* NSView+CAMethods.m

   Copyright (C) 2018 Free Software Foundation, Inc.

   Author: Stjepan Brkic <stjepanbrkicc@gmail.com>
   Date: June 2018

   This file is part of QuartzCore/CAAppKitBridge.

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

#import "GSCAData.h"
#import "NSView+CAMethods.h"

@implementation NSView (NSViewCAmethods)
- (BOOL) wantsLayer
{
  if (self->_coreAnimationData == nil)
    {
      return NO;
    }
  GSCAData * GSCAData = self->_coreAnimationData;
  return GSCAData->_wantsLayer;
}

- (void) setWantsLayer:(BOOL)newValue
  {
  if (newValue == NO)
    {
      return;
    }

  /* Initialise new GSCAData if setWantsLayer:YES */
  GSCAData * currGSCAData = [[GSCAData alloc]init];
  currGSCAData->_wantsLayer = YES;
  currGSCAData->_isRootLayer = YES;
  currGSCAData->_layer = [self makeBackingLayer];
  self->_coreAnimationData = currGSCAData;

  /* Further prep of CARenderer */
  [currGSCAData->_renderer setLayer: currGSCAData->_layer];           // Set root layer
  [currGSCAData->_renderer setBounds: NSRectToCGRect([self bounds])]; // Set bounds
  [self openGLContext];                                               // Create OpenGL context

  /* Call _recursiveSubviewPropagation recursively on all the subviews */
  for (NSView *currView in [self subviews])
    {
      [currView _recursiveSubviewPropagation];
    }
}

- (void) _recursiveSubviewPropagation
{
  /* Initialise new GSCAData instance */
  GSCAData * currGSCAData = [[GSCAData alloc]init];
  currGSCAData->_wantsLayer = NO;
  currGSCAData->_isRootLayer = NO;
  currGSCAData->_layer = [self makeBackingLayer];

  /* Attach GSCAData to self */
  self->_coreAnimationData = currGSCAData;

  /* Attach our CALayer to its superView CALayer */
  NSView * superView = [self superview];
  if(superView != nil)
    {
      GSCAData * superGSCAData = superView->_coreAnimationData;
      [superGSCAData->_layer addSublayer:currGSCAData->_layer];
    }

  /* Call wantsLayer recursively on all the subviews */
  for (NSView *currView in [self subviews])
    {
      [currView _recursiveSubviewPropagation];
    }

}

- (BOOL) addCARenderer: (CARenderer*)customCARenderer 
{
  GSCAData *currGSCAData = self->_coreAnimationData;
  if (!currGSCAData->_isRootLayer)
    {
      NSLog(@"Cannot add CARenderer to a non-root layer");
      return NO;
    }
  currGSCAData->_renderer = customCARenderer;
  return YES;
}

- (BOOL) removeCARenderer
{
  GSCAData *currGSCAData = self->_coreAnimationData;
  if (!currGSCAData->_isRootLayer)
    {
      NSLog(@"Cannot remove CARenderer from a non-root layer");
      return NO;
    }
  currGSCAData->_renderer = nil;
  return YES;
}

- (CALayer *) makeBackingLayer
{
  return [CALayer layer];
}


/* methods from libs-gui/Headers/AppKit/NSOpenGLView.h */


/**
 detach from the current context.  You should call it before releasing this 
 object.
*/
- (void) clearGLContext
{
  if (self->_coreAnimationData == nil) {
      return;
  }
  GSCAData *currGSCAData = self->_coreAnimationData;
  NSOpenGLContext *currGlContext = currGSCAData->_GLContext;
if (currGlContext)
  {
    [currGlContext clearDrawable];
    DESTROY(currGlContext);
    currGSCAData->_prepared = NO;
  }
}

- (void) setOpenGLContext: (NSOpenGLContext*)context
{
  GSCAData *currGSCAData = self->_coreAnimationData;
  NSOpenGLContext *currGlContext = currGSCAData->_GLContext;
  if ( context != currGlContext )
      {
      [self clearGLContext];
      ASSIGN(currGlContext, context);
      }
}

- (NSOpenGLContext*) openGLContext
{
  GSCAData *currGSCAData = self->_coreAnimationData;
  NSOpenGLContext *currGlContext = currGSCAData->_GLContext;
  if (currGlContext == nil)
  {
    NSOpenGLContext *context = [[NSOpenGLContext alloc] 
                                   initWithFormat: currGSCAData->_pixelFormat
                                   shareContext: nil];

    [self setOpenGLContext: context];
    [context setView: self];

    RELEASE(context);
  }
  return currGlContext;
}

- (NSOpenGLPixelFormat*) pixelFormat
{
  GSCAData *currGSCAData = self->_coreAnimationData;
  return currGSCAData->_pixelFormat;
}


- (void) reshape
{
}

- (void) update
{
  NSOpenGLContext *context;
  context = [self openGLContext];
  if ([context view] == self)
    {
      [context update];
    }
}

- (BOOL) isOpaque
{
  return YES;
}

/* TODO:(stjepanbrkicc) Implement custom dealloc */

@end
