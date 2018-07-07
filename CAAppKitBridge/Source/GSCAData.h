/* GSCAData.h

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

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

@interface  GSCAData : NSObject
{
  @public
  BOOL            _wantsLayer;
  BOOL            _isRootLayer;
  CARenderer     *_renderer; /* NIL if _isOriginalReciever == NO */
  CALayer        *_layer;

  /* from libs-gui/Headers/AppKit/NSOpenGLView.h */

  NSOpenGLContext 	    *_GLContext;
	NSOpenGLPixelFormat	  *_pixelFormat; /* <- TODO: Check Apple behavior for propagating this */
	BOOL		              _prepared;
}

@end
