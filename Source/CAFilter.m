/* CAFilter.m

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
#import "QuartzCore/CAFilter.h"

NSString *const kCAFilterClear = @"clear";
NSString *const kCAFilterCopy = @"copy";
NSString *const kCAFilterDestAtop = @"destAtop";
NSString *const kCAFilterDestIn = @"destIn";
NSString *const kCAFilterDestOut = @"destOut";
NSString *const kCAFilterDestOver = @"destOver";
NSString *const kCAFilterFog = @"kCAFilterFog";
NSString *const kCAFilterGaussianBlur = @"gaussianBlur";
NSString *const kCAFilterLanczos = @"lanczos";
NSString *const kCAFilterLighting = @"kCAFilterLighting";
NSString *const kCAFilterLinear = @"linear";
NSString *const kCAFilterMultiply = @"multiply";
NSString *const kCAFilterMultiplyColor = @"multiplyColor";
NSString *const kCAFilterMultiplyGradient = @"kCAFilterMultiplyGradient";
NSString *const kCAFilterNearest = @"nearest";
NSString *const kCAFilterPageCurl = @"pageCurl";
NSString *const kCAFilterPlusL = @"plusL";
NSString *const kCAFilterSourceAtop = @"sourceAtop";
NSString *const kCAFilterSourceIn = @"sourceIn";
NSString *const kCAFilterSourceOut = @"sourceOut";
NSString *const kCAFilterSourceOver = @"sourceOver";
NSString *const kCAFilterTrilinear = @"trilinear";
NSString *const kCAFilterXor = @"xor";

NSString *const kCAFilterColorInvert = @"colorInvert";
NSString *const kCAFilterColorMatrix = @"colorMatrix";
NSString *const kCAFilterColorMonochrome = @"colorMonochrome";
NSString *const kCAFilterColorHueRotate = @"colorHueRotate";
NSString *const kCAFilterColorSaturate = @"colorSaturate";
NSString *const kCAFilterPlusD = @"plusD";

NSString *const kCAFilterNormalBlendMode = @"normalBlendMode";
NSString *const kCAFilterMultiplyBlendMode = @"multiplyBlendMode";
NSString *const kCAFilterScreenBlendMode = @"screenBlendMode";
NSString *const kCAFilterOverlayBlendMode = @"overlayBlendMode";
NSString *const kCAFilterDarkenBlendMode = @"darkenBlendMode";
NSString *const kCAFilterLightenBlendMode = @"lightenBlendMode";
NSString *const kCAFilterColorDodgeBlendMode = @"colorDodgeBlendMode";
NSString *const kCAFilterColorBurnBlendMode = @"colorBurnBlendMode";
NSString *const kCAFilterSoftLightBlendMode = @"softLightBlendMode";
NSString *const kCAFilterHardLightBlendMode = @"hardLightBlendMode";
NSString *const kCAFilterDifferenceBlendMode = @"differenceBlendMode";
NSString *const kCAFilterExclusionBlendMode = @"exclusionBlendMode";

@implementation CAFilter
@end
