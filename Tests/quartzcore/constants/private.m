/* The value of each string constant that Apple exports but does not declare
   in its public headers, which is why this file is not compiled against them.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("string constants Apple does not publish")

  testHopeful = YES;

  PASS([kCAFillModeFrozen isEqualToString: @"frozen"],
       "kCAFillModeFrozen is \"frozen\"");
  PASS([kCAFilterClear isEqualToString: @"clear"],
       "kCAFilterClear is \"clear\"");
  PASS([kCAFilterColorBurnBlendMode isEqualToString: @"colorBurnBlendMode"],
       "kCAFilterColorBurnBlendMode is \"colorBurnBlendMode\"");
  PASS([kCAFilterColorDodgeBlendMode isEqualToString: @"colorDodgeBlendMode"],
       "kCAFilterColorDodgeBlendMode is \"colorDodgeBlendMode\"");
  PASS([kCAFilterColorHueRotate isEqualToString: @"colorHueRotate"],
       "kCAFilterColorHueRotate is \"colorHueRotate\"");
  PASS([kCAFilterColorInvert isEqualToString: @"colorInvert"],
       "kCAFilterColorInvert is \"colorInvert\"");
  PASS([kCAFilterColorMatrix isEqualToString: @"colorMatrix"],
       "kCAFilterColorMatrix is \"colorMatrix\"");
  PASS([kCAFilterColorMonochrome isEqualToString: @"colorMonochrome"],
       "kCAFilterColorMonochrome is \"colorMonochrome\"");
  PASS([kCAFilterColorSaturate isEqualToString: @"colorSaturate"],
       "kCAFilterColorSaturate is \"colorSaturate\"");
  PASS([kCAFilterCopy isEqualToString: @"copy"],
       "kCAFilterCopy is \"copy\"");
  PASS([kCAFilterDarkenBlendMode isEqualToString: @"darkenBlendMode"],
       "kCAFilterDarkenBlendMode is \"darkenBlendMode\"");
  PASS([kCAFilterDestAtop isEqualToString: @"destAtop"],
       "kCAFilterDestAtop is \"destAtop\"");
  PASS([kCAFilterDestIn isEqualToString: @"destIn"],
       "kCAFilterDestIn is \"destIn\"");
  PASS([kCAFilterDestOut isEqualToString: @"destOut"],
       "kCAFilterDestOut is \"destOut\"");
  PASS([kCAFilterDestOver isEqualToString: @"destOver"],
       "kCAFilterDestOver is \"destOver\"");
  PASS([kCAFilterDifferenceBlendMode isEqualToString: @"differenceBlendMode"],
       "kCAFilterDifferenceBlendMode is \"differenceBlendMode\"");
  PASS([kCAFilterExclusionBlendMode isEqualToString: @"exclusionBlendMode"],
       "kCAFilterExclusionBlendMode is \"exclusionBlendMode\"");
  PASS([kCAFilterGaussianBlur isEqualToString: @"gaussianBlur"],
       "kCAFilterGaussianBlur is \"gaussianBlur\"");
  PASS([kCAFilterHardLightBlendMode isEqualToString: @"hardLightBlendMode"],
       "kCAFilterHardLightBlendMode is \"hardLightBlendMode\"");
  PASS([kCAFilterLanczos isEqualToString: @"lanczos"],
       "kCAFilterLanczos is \"lanczos\"");
  PASS([kCAFilterLightenBlendMode isEqualToString: @"lightenBlendMode"],
       "kCAFilterLightenBlendMode is \"lightenBlendMode\"");
  PASS([kCAFilterLinear isEqualToString: @"linear"],
       "kCAFilterLinear is \"linear\"");
  PASS([kCAFilterMultiply isEqualToString: @"multiply"],
       "kCAFilterMultiply is \"multiply\"");
  PASS([kCAFilterMultiplyBlendMode isEqualToString: @"multiplyBlendMode"],
       "kCAFilterMultiplyBlendMode is \"multiplyBlendMode\"");
  PASS([kCAFilterMultiplyColor isEqualToString: @"multiplyColor"],
       "kCAFilterMultiplyColor is \"multiplyColor\"");
  PASS([kCAFilterNearest isEqualToString: @"nearest"],
       "kCAFilterNearest is \"nearest\"");
  PASS([kCAFilterNormalBlendMode isEqualToString: @"normalBlendMode"],
       "kCAFilterNormalBlendMode is \"normalBlendMode\"");
  PASS([kCAFilterOverlayBlendMode isEqualToString: @"overlayBlendMode"],
       "kCAFilterOverlayBlendMode is \"overlayBlendMode\"");
  PASS([kCAFilterPageCurl isEqualToString: @"pageCurl"],
       "kCAFilterPageCurl is \"pageCurl\"");
  PASS([kCAFilterPlusD isEqualToString: @"plusD"],
       "kCAFilterPlusD is \"plusD\"");
  PASS([kCAFilterPlusL isEqualToString: @"plusL"],
       "kCAFilterPlusL is \"plusL\"");
  PASS([kCAFilterScreenBlendMode isEqualToString: @"screenBlendMode"],
       "kCAFilterScreenBlendMode is \"screenBlendMode\"");
  PASS([kCAFilterSoftLightBlendMode isEqualToString: @"softLightBlendMode"],
       "kCAFilterSoftLightBlendMode is \"softLightBlendMode\"");
  PASS([kCAFilterSourceAtop isEqualToString: @"sourceAtop"],
       "kCAFilterSourceAtop is \"sourceAtop\"");
  PASS([kCAFilterSourceIn isEqualToString: @"sourceIn"],
       "kCAFilterSourceIn is \"sourceIn\"");
  PASS([kCAFilterSourceOut isEqualToString: @"sourceOut"],
       "kCAFilterSourceOut is \"sourceOut\"");
  PASS([kCAFilterSourceOver isEqualToString: @"sourceOver"],
       "kCAFilterSourceOver is \"sourceOver\"");
  PASS([kCAFilterTrilinear isEqualToString: @"trilinear"],
       "kCAFilterTrilinear is \"trilinear\"");
  PASS([kCAFilterXor isEqualToString: @"xor"],
       "kCAFilterXor is \"xor\"");

  testHopeful = NO;

  END_SET("string constants Apple does not publish")

  [pool release];
  return 0;
}
