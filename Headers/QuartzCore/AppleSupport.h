/* 
   AppleSupport.h

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: June 2012

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

/* This file renames the Core Animation classes that we implement so they
   don't conflict with Apple's implementation when testing under Cocoa. This
   is desirable so the implementations can quickly and easily be compared.
   All top-level symbols that might conflict with Apple's implementation 
   should be renamed.

   All symbols are renamed by #define'ing their name, changing their prefix
   from CA (Core Animation) into GSCA (GNUstep Core Animation).

   This file should be #include'd and not #import'ed, since it needs to be
   possible to revert what's done here, and then re-apply it again. File
   contains #define guards, so there should be no bad consequences following
   this advice.

   To revert what's done in this file, companion file AppleSupportRevert.h
   is provided. 

   Note: despite this header being currently publicly available, it should
   be used stricly for testing purposes. Don't depend on it. */

#ifndef GSQUARTZCORE_APPLESUPPORT_H
#define GSQUARTZCORE_APPLESUPPORT_H

#ifndef GSIMPL_UNDER_COCOA
#define GSIMPL_UNDER_COCOA 1
#endif

/* CAAction.h */
#define CAAction GSCAAction

/* CAAnimation.h */
#define CAAnimation GSCAAnimation
#define CAPropertyAnimation GSCAPropertyAnimation
#define CABasicAnimation GSCABasicAnimation
#define CAKeyframeAnimation GSCAKeyframeAnimation
#define kCAAnimationDiscrete GSCAAnimationDiscrete
#define CATransition GSCATransition
#define kCATransitionMoveIn kGSCATransitionMoveIn
#define kCATransitionFromTop kGSCATransitionFromTop
#define kCATransitionFromBottom kGSCATransitionFromBottom
#define kCATransitionFromLeft kGSCATransitionFromLeft
#define kCATransitionFromRight kGSCATransitionFromRight

/* CABackingStore.h */
#define CABackingStore GSCABackingStore

/* CABase.h */
#define CACurrentMediaTime GSCACurrentMediaTime

/* CADisplayLink.h */

/* CAEAGLLayer.h */

/* CAGradientLayer.h */

/* CAImplicitAnimationObserver.h */
#define CAImplicitAnimationObserver GSCAImplicitAnimationObserver

/* CALayer.h */
#define kCAGravityResize kGSCAGravityResize
#define kCAGravityResizeAspect kGSCAGravityResizeAspect
#define kCAGravityResizeAspectFill kGSCAGravityResizeAspectFill
#define kCAGravityCenter kGSCAGravityCenter
#define kCAGravityTop kGSCAGravityTop
#define kCAGravityBottom kGSCAGravityBottom
#define kCAGravityLeft kGSCAGravityLeft
#define kCAGravityRight kGSCAGravityRight
#define kCAGravityTopLeft kGSCAGravityTopLeft
#define kCAGravityTopRight kGSCAGravityTopRight
#define kCAGravityBottomLeft kGSCAGravityBottomLeft
#define kCAGravityBottomRight kGSCAGravityBottomRight
#define kCATransition kGSCATransition

#define CALayer GSCALayer

/* CAMediaTiming.h */
#define CAMediaTiming GSCAMediaTiming
#define kCAFillModeRemoved kGSCAFillModeRemoved
#define kCAFillModeForwards kGSCAFillModeForwards
#define kCAFillModeBackwards kGSCAFillModeBackwards
#define kCAFillModeBoth kGSCAFillModeBoth
#define kCAFillModeFrozen kGSCAFillModeFrozen

/* CAMediaTimingFunction.h */
#define kCAMediaTimingFunctionDefault kGSCAMediaTimingFunctionDefault
#define kCAMediaTimingFunctionEaseInEaseOut kGSCAMediaTimingFunctionEaseInEaseOut
#define kCAMediaTimingFunctionEaseIn kGSCAMediaTimingFunctionEaseIn
#define kCAMediaTimingFunctionEaseOut kGSCAMediaTimingFunctionEaseOut
#define kCAMediaTimingFunctionLinear kGSCAMediaTimingFunctionLinear

#define CAMediaTimingFunction GSCAMediaTimingFunction

/* CARenderer.h */
#define _CVTimeStamp _GSCVTimeStamp
#define CVTimeStamp GSCVTimeStamp

#define CARenderer GSCARenderer

/* CAReplicatorLayer.h */

/* CAScrollLayer.h */

/* CAShapeLayer.h */

/* CATextLayer.h */

/* CATiledLayer.h */

/* CATransaction.h */
#define CATransaction GSCATransaction

/* CATransform3D.h */
#define CATransform3D GSCATransform3D
#define CATransform3DIsIdentity GSCATransform3DIsIdentity
#define CATransform3DEqualToTransform GSCATransform3DEqualToTransform
#define CATransform3DMakeTranslation GSCATransform3DMakeTranslation
#define CATransform3DMakeScale GSCATransform3DMakeScale
#define CATransform3DMakeRotation GSCATransform3DMakeRotation
#define CATransform3DTranslate GSCATransform3DTranslate
#define CATransform3DScale GSCATransform3DScale
#define CATransform3DRotate GSCATransform3DRotate
#define CATransform3DConcat GSCATransform3DConcat
#define CATransform3DInvert GSCATransform3DInvert

/* CATransformLayer.h */

/* CAValueFunction.h */
#define CAValueFunction GSCAValueFunction

/* CoreAnimation.h */

/* QuartzCore.h */

#endif
