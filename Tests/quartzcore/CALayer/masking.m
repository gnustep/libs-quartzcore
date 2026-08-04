/* The layer properties that describe masking, filtering and edge
   antialiasing.  Every expected value here was measured against Apple
   QuartzCore, including the ones that are not obvious: a layer allows both
   edge antialiasing and group opacity from the start, all four edges are in
   the antialiasing mask, the contents centre is the unit rectangle, and a
   layer used as a mask takes the masking layer as its superlayer without
   becoming one of its sublayers. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

static BOOL eq(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

static BOOL req(CGRect r, CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
  return eq(r.origin.x, x) && eq(r.origin.y, y)
      && eq(r.size.width, w) && eq(r.size.height, h);
}

static void defaults(void)
{
  CALayer *l = [CALayer layer];

  PASS([l allowsEdgeAntialiasing] == YES,
       "a new layer allows edge antialiasing");
  PASS([l allowsGroupOpacity] == YES, "a new layer allows group opacity");
  PASS([l edgeAntialiasingMask] == (kCALayerLeftEdge | kCALayerRightEdge
                                    | kCALayerBottomEdge | kCALayerTopEdge),
       "all four edges are antialiased to begin with");
  PASS([l drawsAsynchronously] == NO, "a new layer does not draw off thread");
  PASS(eq([l minificationFilterBias], 0),
       "a new layer has no minification filter bias");
  PASS([l filters] == nil, "a new layer has no filters");
  PASS([l compositingFilter] == nil, "a new layer has no compositing filter");
  PASS([l backgroundFilters] == nil, "a new layer has no background filters");
  PASS([l mask] == nil, "a new layer has no mask");
  PASS(req([l contentsCenter], 0, 0, 1, 1),
       "the contents centre starts as the whole unit rectangle");
}

static void edgeConstants(void)
{
  PASS(kCALayerLeftEdge == 1, "the left edge is bit zero");
  PASS(kCALayerRightEdge == 2, "the right edge is bit one");
  PASS(kCALayerBottomEdge == 4, "the bottom edge is bit two");
  PASS(kCALayerTopEdge == 8, "the top edge is bit three");
}

static void roundTrips(void)
{
  CALayer *l = [CALayer layer];

  [l setAllowsEdgeAntialiasing: NO];
  PASS([l allowsEdgeAntialiasing] == NO, "edge antialiasing can be turned off");
  [l setAllowsGroupOpacity: NO];
  PASS([l allowsGroupOpacity] == NO, "group opacity can be turned off");
  [l setDrawsAsynchronously: YES];
  PASS([l drawsAsynchronously] == YES, "asynchronous drawing can be asked for");
  [l setEdgeAntialiasingMask: kCALayerLeftEdge | kCALayerTopEdge];
  PASS([l edgeAntialiasingMask] == (kCALayerLeftEdge | kCALayerTopEdge),
       "the edge mask reads back the edges it was given");
  [l setMinificationFilterBias: 0.25];
  PASS(eq([l minificationFilterBias], 0.25),
       "the minification filter bias reads back what was set");

  [l setContentsCenter: CGRectMake(0.25, 0.25, 0.5, 0.5)];
  PASS(req([l contentsCenter], 0.25, 0.25, 0.5, 0.5),
       "the contents centre reads back what was set");
  [l setContentsCenter: CGRectMake(-1, -1, 4, 4)];
  PASS(req([l contentsCenter], -1, -1, 4, 4),
       "a contents centre outside the unit rectangle is kept unchecked");
}

static void filters(void)
{
  CALayer *l = [CALayer layer];
  NSMutableArray *given = [NSMutableArray arrayWithObject: @"one"];

  [l setFilters: given];
  PASS([[l filters] count] == 1, "the filter array holds what it was given");
  PASS([l filters] != given, "setting the filters copies the array");
  [given addObject: @"two"];
  PASS([[l filters] count] == 1,
       "so a later change to the original does not reach the layer");
  [l setFilters: nil];
  PASS([l filters] == nil, "the filters can be taken away again");

  [l setBackgroundFilters: [NSArray arrayWithObject: @"one"]];
  PASS([[l backgroundFilters] count] == 1,
       "the background filter array holds what it was given");

  id filter = [NSObject new];
  [l setCompositingFilter: filter];
  PASS([l compositingFilter] == filter,
       "the compositing filter is the object it was given");
  [filter release];
  [l setCompositingFilter: nil];
  PASS([l compositingFilter] == nil,
       "the compositing filter can be taken away again");
}

static void mask(void)
{
  CALayer *host = [CALayer layer];
  CALayer *m = [CALayer layer];

  [host setMask: m];
  PASS([host mask] == m, "the mask is the layer it was given");
  PASS([m superlayer] == host, "a mask takes the masked layer as superlayer");
  PASS([[host sublayers] count] == 0, "but it does not become a sublayer");

  [host setMask: nil];
  PASS([host mask] == nil, "the mask can be taken away");
  PASS([m superlayer] == nil, "which leaves the old mask with no superlayer");

  CALayer *parent = [CALayer layer];
  CALayer *child = [CALayer layer];
  [parent addSublayer: child];
  CALayer *other = [CALayer layer];
  [other setMask: child];
  PASS([child superlayer] == other,
       "a layer already in a tree takes the masking layer as superlayer");
  PASS([[parent sublayers] count] == 0, "and leaves the tree it was in");
}

static void classDefaults(void)
{
  id v;

  v = [CALayer defaultValueForKey: @"allowsEdgeAntialiasing"];
  PASS(v != nil && [v boolValue] == YES,
       "the class default allows edge antialiasing");
  v = [CALayer defaultValueForKey: @"allowsGroupOpacity"];
  PASS(v != nil && [v boolValue] == YES,
       "the class default allows group opacity");
  v = [CALayer defaultValueForKey: @"edgeAntialiasingMask"];
  PASS(v != nil && [v unsignedIntValue] == 15,
       "the class default antialiases all four edges");
  v = [CALayer defaultValueForKey: @"drawsAsynchronously"];
  PASS(v != nil && [v boolValue] == NO,
       "the class default does not draw off thread");
  v = [CALayer defaultValueForKey: @"contentsCenter"];
  PASS(v != nil, "the class has a default contents centre");

  PASS([CALayer defaultValueForKey: @"minificationFilterBias"] == nil,
       "the class has no default minification filter bias");
  PASS([CALayer defaultValueForKey: @"filters"] == nil,
       "the class has no default filters");
  PASS([CALayer defaultValueForKey: @"compositingFilter"] == nil,
       "the class has no default compositing filter");
  PASS([CALayer defaultValueForKey: @"backgroundFilters"] == nil,
       "the class has no default background filters");
  PASS([CALayer defaultValueForKey: @"mask"] == nil,
       "the class has no default mask");
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("layer masking and filtering")

  defaults();
  edgeConstants();
  roundTrips();
  filters();
  mask();
  classDefaults();

  END_SET("layer masking and filtering")

  [pool release];
  return 0;
}
