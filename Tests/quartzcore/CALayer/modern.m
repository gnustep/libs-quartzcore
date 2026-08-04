/* The layer properties that describe corner shape, pixel format and dynamic
   range.  Every value here was measured against Apple QuartzCore on a
   macOS 26 runner.

   The framework reads none of them: it rounds no corners, chooses no pixel
   format for its backing store, and has no notion of a display brighter than
   white.  What is testable is what Apple does with the values it is given,
   and that turns out to be more than storing them: each of the four names
   validates against the set it knows and falls back to its default, and the
   corner mask drops the bits that are not corners. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

static BOOL eq(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

static void constants(void)
{
  PASS([kCACornerCurveCircular isEqualToString: @"circular"],
       "the circular corner curve is named circular");
  PASS([kCACornerCurveContinuous isEqualToString: @"continuous"],
       "and the continuous one continuous");

  PASS([kCAContentsFormatAutomatic isEqualToString: @"Automatic"],
       "the automatic contents format is named Automatic");
  PASS([kCAContentsFormatRGBA8Uint isEqualToString: @"RGBA8"],
       "eight bit colour is RGBA8");
  PASS([kCAContentsFormatRGBA16Float isEqualToString: @"RGBAh"],
       "half float colour is RGBAh");
  PASS([kCAContentsFormatGray8Uint isEqualToString: @"Gray8"],
       "and eight bit grey is Gray8");

  PASS([CADynamicRangeStandard isEqualToString: @"standard"],
       "the standard dynamic range is named standard");
  PASS([CADynamicRangeConstrainedHigh isEqualToString: @"constrainedHigh"],
       "the constrained one constrainedHigh");
  PASS([CADynamicRangeHigh isEqualToString: @"high"], "and the high one high");

  PASS([CAToneMapModeAutomatic isEqualToString: @"automatic"],
       "tone mapping is named automatic");
  PASS([CAToneMapModeNever isEqualToString: @"never"], "never");
  PASS([CAToneMapModeIfSupported isEqualToString: @"ifSupported"],
       "and ifSupported");

  PASS(kCALayerMinXMinYCorner == 1, "the first corner is bit zero");
  PASS(kCALayerMaxXMinYCorner == 2, "the second is bit one");
  PASS(kCALayerMinXMaxYCorner == 4, "the third is bit two");
  PASS(kCALayerMaxXMaxYCorner == 8, "the fourth is bit three");
}

static void defaults(void)
{
  CALayer *l = [CALayer layer];

  PASS([[l cornerCurve] isEqualToString: kCACornerCurveCircular],
       "a new layer rounds its corners circularly");
  PASS([l maskedCorners] == (kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner
                             | kCALayerMinXMaxYCorner
                             | kCALayerMaxXMaxYCorner),
       "and rounds all four of them");
  PASS([[l contentsFormat] isEqualToString: kCAContentsFormatRGBA8Uint],
       "a new layer asks for eight bit colour");
  PASS([[l preferredDynamicRange] isEqualToString: CADynamicRangeStandard],
       "a new layer asks for the standard dynamic range");
  PASS([[l toneMapMode] isEqualToString: CAToneMapModeAutomatic],
       "and leaves tone mapping to be decided");
  PASS(eq([l contentsHeadroom], 0), "a new layer has no headroom");
  PASS([l wantsExtendedDynamicRangeContent] == NO,
       "a new layer does not want an extended range");
  PASS([l wantsDynamicContentScaling] == NO,
       "and does not want its contents scaled dynamically");
}

static void classDefaults(void)
{
  id v;

  v = [CALayer defaultValueForKey: @"cornerCurve"];
  PASS(v != nil && [v isEqualToString: kCACornerCurveCircular],
       "the class default corner curve is circular");
  v = [CALayer defaultValueForKey: @"maskedCorners"];
  PASS(v != nil && [v unsignedIntValue] == 15,
       "the class default masks all four corners");
  v = [CALayer defaultValueForKey: @"contentsFormat"];
  PASS(v != nil && [v isEqualToString: kCAContentsFormatRGBA8Uint],
       "the class default contents format is eight bit colour");
  v = [CALayer defaultValueForKey: @"preferredDynamicRange"];
  PASS(v != nil && [v isEqualToString: CADynamicRangeStandard],
       "the class default dynamic range is standard");
  v = [CALayer defaultValueForKey: @"toneMapMode"];
  PASS(v != nil && [v isEqualToString: CAToneMapModeAutomatic],
       "the class default tone map mode is automatic");
  v = [CALayer defaultValueForKey: @"contentsHeadroom"];
  PASS(v != nil && eq([v floatValue], 0),
       "the class default headroom is zero");
  v = [CALayer defaultValueForKey: @"wantsExtendedDynamicRangeContent"];
  PASS(v != nil && [v boolValue] == NO,
       "the class does not want an extended range by default");
  PASS([CALayer defaultValueForKey: @"wantsDynamicContentScaling"] == nil,
       "and has no default at all for dynamic content scaling");
}

static void roundTrips(void)
{
  CALayer *l = [CALayer layer];

  [l setCornerCurve: kCACornerCurveContinuous];
  PASS([[l cornerCurve] isEqualToString: kCACornerCurveContinuous],
       "a corner curve reads back what it was given");
  [l setMaskedCorners: kCALayerMinXMinYCorner | kCALayerMaxXMaxYCorner];
  PASS([l maskedCorners] == 9, "so does a pair of corners");
  [l setContentsFormat: kCAContentsFormatRGBA16Float];
  PASS([[l contentsFormat] isEqualToString: kCAContentsFormatRGBA16Float],
       "and a contents format");
  [l setPreferredDynamicRange: CADynamicRangeHigh];
  PASS([[l preferredDynamicRange] isEqualToString: CADynamicRangeHigh],
       "and a dynamic range");
  [l setToneMapMode: CAToneMapModeNever];
  PASS([[l toneMapMode] isEqualToString: CAToneMapModeNever],
       "and a tone map mode");
  [l setContentsHeadroom: 2.5];
  PASS(eq([l contentsHeadroom], 2.5), "and a headroom");
  [l setWantsExtendedDynamicRangeContent: YES];
  PASS([l wantsExtendedDynamicRangeContent] == YES,
       "and an extended range");
  [l setWantsDynamicContentScaling: YES];
  PASS([l wantsDynamicContentScaling] == YES,
       "and dynamic content scaling");

  [l setContentsHeadroom: -3];
  PASS(eq([l contentsHeadroom], -3),
       "a headroom below zero is kept as it is");
}

static void namesItDoesNotKnow(void)
{
  CALayer *l = [CALayer layer];

  [l setCornerCurve: kCACornerCurveContinuous];
  [l setCornerCurve: @"not a curve"];
  PASS([[l cornerCurve] isEqualToString: kCACornerCurveCircular],
       "a corner curve it does not know puts the layer back to circular");

  [l setContentsFormat: kCAContentsFormatGray8Uint];
  [l setContentsFormat: @"not a format"];
  PASS([[l contentsFormat] isEqualToString: kCAContentsFormatRGBA8Uint],
       "a contents format it does not know goes back to eight bit colour");

  [l setPreferredDynamicRange: CADynamicRangeHigh];
  [l setPreferredDynamicRange: @"not a range"];
  PASS([[l preferredDynamicRange] isEqualToString: CADynamicRangeStandard],
       "a dynamic range it does not know goes back to standard");

  [l setToneMapMode: CAToneMapModeNever];
  [l setToneMapMode: @"not a mode"];
  PASS([[l toneMapMode] isEqualToString: CAToneMapModeAutomatic],
       "a tone map mode it does not know goes back to automatic");

  [l setMaskedCorners: 255];
  PASS([l maskedCorners] == 15,
       "and bits that are not corners are dropped from the corner mask");
}

static void expansionFactor(void)
{
  PASS(eq([CALayer cornerCurveExpansionFactor: kCACornerCurveCircular], 1),
       "a circular corner is not expanded");
  PASS(eq([CALayer cornerCurveExpansionFactor: kCACornerCurveContinuous],
          1.528665),
       "a continuous one reaches about half as far again");
  PASS(eq([CALayer cornerCurveExpansionFactor: @"not a curve"], 1),
       "a name it does not know is not expanded");
  PASS(eq([CALayer cornerCurveExpansionFactor: nil], 1),
       "and neither is no name at all");
}

static void archiving(void)
{
  CALayer *l = [CALayer layer];

  PASS([l shouldArchiveValueForKey: @"cornerCurve"] == YES,
       "a new layer archives its corner curve");
  PASS([l shouldArchiveValueForKey: @"contentsFormat"] == YES,
       "and its contents format");
  PASS([l shouldArchiveValueForKey: @"maskedCorners"] == NO,
       "but not a corner mask nobody set");
  PASS([l shouldArchiveValueForKey: @"preferredDynamicRange"] == NO,
       "nor a dynamic range nobody set");
  PASS([l shouldArchiveValueForKey: @"toneMapMode"] == NO,
       "nor a tone map mode nobody set");

  [l setMaskedCorners: kCALayerMinXMinYCorner];
  [l setPreferredDynamicRange: CADynamicRangeHigh];
  [l setToneMapMode: CAToneMapModeNever];
  [l setContentsHeadroom: 2];
  [l setWantsExtendedDynamicRangeContent: YES];
  PASS([l shouldArchiveValueForKey: @"maskedCorners"] == YES,
       "a corner mask it was given is archived");
  PASS([l shouldArchiveValueForKey: @"preferredDynamicRange"] == YES,
       "and a dynamic range");
  PASS([l shouldArchiveValueForKey: @"toneMapMode"] == YES,
       "and a tone map mode");
  PASS([l shouldArchiveValueForKey: @"contentsHeadroom"] == YES,
       "and a headroom");
  PASS([l shouldArchiveValueForKey: @"wantsExtendedDynamicRangeContent"]
       == YES, "and an extended range");

  [l setWantsDynamicContentScaling: YES];
  PASS([l shouldArchiveValueForKey: @"wantsDynamicContentScaling"] == NO,
       "while dynamic content scaling is never archived, set or not");
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("corners, pixel format and dynamic range")

  constants();
  defaults();
  classDefaults();
  roundTrips();
  namesItDoesNotKnow();
  expansionFactor();
  archiving();

  END_SET("corners, pixel format and dynamic range")

  [pool release];
  return 0;
}
