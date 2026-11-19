/* CATiledLayer: what a fresh tiled layer holds and what its setters keep.
   Expected values checked against Apple QuartzCore.

   This covers the properties.  A tiled layer does not draw its tiles here
   yet. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CATiledLayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a tiled layer starts with")

  CATiledLayer *t = [CATiledLayer layer];

  PASS([t isKindOfClass: [CALayer class]], "a tiled layer is a layer");
  PASS([t levelsOfDetail] == 1, "a tiled layer has one level of detail");
  PASS([t levelsOfDetailBias] == 0, "a tiled layer has no level of detail bias");
  PASS([t tileSize].width == 256 && [t tileSize].height == 256,
       "a tile is 256 by 256");
  PASS([t opacity] == 1.0, "a tiled layer keeps what a layer starts with");

  END_SET("what a tiled layer starts with")

  START_SET("how long a tile takes to appear")

  PASS([CATiledLayer fadeDuration] == 0.25,
       "a tile fades in over a quarter of a second");

  END_SET("how long a tile takes to appear")

  START_SET("what the setters keep")

  CATiledLayer *t = [CATiledLayer layer];

  [t setLevelsOfDetail: 3];
  PASS([t levelsOfDetail] == 3, "the levels of detail read back");

  [t setLevelsOfDetailBias: 2];
  PASS([t levelsOfDetailBias] == 2, "the level of detail bias reads back");

  [t setTileSize: CGSizeMake(64, 32)];
  PASS([t tileSize].width == 64 && [t tileSize].height == 32,
       "the tile size reads back as it was set");

  END_SET("what the setters keep")

  [pool release];
  return 0;
}
