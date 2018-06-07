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

NSString *const kCAFilterClear = @"kCAFilterClear";
NSString *const kCAFilterCopy = @"kCAFilterCopy";
NSString *const kCAFilterDestAtop = @"kCAFilterDestAtop";
NSString *const kCAFilterDestIn = @"kCAFilterDestIn";
NSString *const kCAFilterDestOut = @"kCAFilterDestOut";
NSString *const kCAFilterDestOver = @"kCAFilterDestOver";
NSString *const kCAFilterFog = @"kCAFilterFog";
NSString *const kCAFilterGaussianBlur = @"kCAFilterGaussianBlur";
NSString *const kCAFilterLanczos = @"kCAFilterLanczos";
NSString *const kCAFilterLighting = @"kCAFilterLighting";
NSString *const kCAFilterLinear = @"kCAFilterLinear";
NSString *const kCAFilterMultiply = @"kCAFilterMultiply";
NSString *const kCAFilterMultiplyColor = @"kCAFilterMultiplyColor";
NSString *const kCAFilterMultiplyGradient = @"kCAFilterMultiplyGradient";
NSString *const kCAFilterNearest = @"kCAFilterNearest";
NSString *const kCAFilterPageCurl = @"kCAFilterPageCurl";
NSString *const kCAFilterPlusL = @"kCAFilterPlusL";
NSString *const kCAFilterSourceAtop = @"kCAFilterSourceAtop";
NSString *const kCAFilterSourceIn = @"kCAFilterSourceIn";
NSString *const kCAFilterSourceOut = @"kCAFilterSourceOut";
NSString *const kCAFilterSourceOver = @"kCAFilterSourceOver";
NSString *const kCAFilterTrilinear = @"kCAFilterTrilinear";
NSString *const kCAFilterXor = @"kCAFilterXor";

NSString *const kCAFilterColorInvert = @"kCAFilterColorInvert";
NSString *const kCAFilterColorMatrix = @"kCAFilterColorMatrix";
NSString *const kCAFilterColorMonochrome = @"kCAFilterColorMonochrome";
NSString *const kCAFilterColorHueRotate = @"kCAFilterColorHueRotate";
NSString *const kCAFilterColorSaturate = @"kCAFilterColorSaturate";
NSString *const kCAFilterPlusD = @"kCAFilterPlusD";

NSString *const kCAFilterNormalBlendMode = @"kCAFilterNormalBlendMode";
NSString *const kCAFilterMultiplyBlendMode = @"kCAFilterMultiplyBlendMode";
NSString *const kCAFilterScreenBlendMode = @"kCAFilterScreenBlendMode";
NSString *const kCAFilterOverlayBlendMode = @"kCAFilterOverlayBlendMode";
NSString *const kCAFilterDarkenBlendMode = @"kCAFilterDarkenBlendMode";
NSString *const kCAFilterLightenBlendMode = @"kCAFilterLightenBlendMode";
NSString *const kCAFilterColorDodgeBlendMode = @"kCAFilterColorDodgeBlendMode";
NSString *const kCAFilterColorBurnBlendMode = @"kCAFilterColorBurnBlendMode";
NSString *const kCAFilterSoftLightBlendMode = @"kCAFilterSoftLightBlendMode";
NSString *const kCAFilterHardLightBlendMode = @"kCAFilterHardLightBlendMode";
NSString *const kCAFilterDifferenceBlendMode = @"kCAFilterDifferenceBlendMode";
NSString *const kCAFilterExclusionBlendMode = @"kCAFilterExclusionBlendMode";

@implementation CAFilter
@end
