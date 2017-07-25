/* CAFilter.h

   Copyright (C) 2017 Free Software Foundation, Inc.

   Author: Daniel Ferreira <dtf@stanford.edu>
   Date: July 2017

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

extern NSString *const kCAFilterClear;
extern NSString *const kCAFilterCopy;
extern NSString *const kCAFilterDestAtop;
extern NSString *const kCAFilterDestIn;
extern NSString *const kCAFilterDestOut;
extern NSString *const kCAFilterDestOver;
extern NSString *const kCAFilterFog;
extern NSString *const kCAFilterGaussianBlur;
extern NSString *const kCAFilterLanczos;
extern NSString *const kCAFilterLighting;
extern NSString *const kCAFilterLinear;
extern NSString *const kCAFilterMultiply;
extern NSString *const kCAFilterMultiplyColor;
extern NSString *const kCAFilterMultiplyGradient;
extern NSString *const kCAFilterNearest;
extern NSString *const kCAFilterPageCurl;
extern NSString *const kCAFilterPlusL;
extern NSString *const kCAFilterSourceAtop;
extern NSString *const kCAFilterSourceIn;
extern NSString *const kCAFilterSourceOut;
extern NSString *const kCAFilterSourceOver;
extern NSString *const kCAFilterTrilinear;
extern NSString *const kCAFilterXor;

/* Private API Filters */
extern NSString *const kCAFilterColorInvert;
extern NSString *const kCAFilterColorMatrix;
extern NSString *const kCAFilterColorMonochrome;
extern NSString *const kCAFilterColorHueRotate;
extern NSString *const kCAFilterColorSaturate;
extern NSString *const kCAFilterGaussianBlur;
extern NSString *const kCAFilterPlusD;
extern NSString *const kCAFilterPlusL;

extern NSString *const kCAFilterNormalBlendMode;
extern NSString *const kCAFilterMultiplyBlendMode;
extern NSString *const kCAFilterScreenBlendMode;
extern NSString *const kCAFilterOverlayBlendMode;
extern NSString *const kCAFilterDarkenBlendMode;
extern NSString *const kCAFilterLightenBlendMode;
extern NSString *const kCAFilterColorDodgeBlendMode;
extern NSString *const kCAFilterColorBurnBlendMode;
extern NSString *const kCAFilterSoftLightBlendMode;
extern NSString *const kCAFilterHardLightBlendMode;
extern NSString *const kCAFilterDifferenceBlendMode;
extern NSString *const kCAFilterExclusionBlendMode;

@interface CAFilter : NSObject
@end
