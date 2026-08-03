/* The properties a CALayer subclass declares @dynamic: which types can be
   synthesised, what a fresh layer reads, and what the accessors keep.
   Expected values checked against Apple QuartzCore, which synthesises every
   type below.

   Each type gets its own subclass so that one type failing does not stop
   the rest from being checked.  The accessors are created the first time
   the class is messaged, so a type that cannot be synthesised raises there
   rather than at the set. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>

#define DYNAMIC_LAYER(name, type) \
@interface name : CALayer \
@property (nonatomic, assign) type p; \
@end \
@implementation name \
@dynamic p; \
@end

DYNAMIC_LAYER(DynBoolLayer, BOOL)
DYNAMIC_LAYER(DynCharLayer, char)
DYNAMIC_LAYER(DynUCharLayer, unsigned char)
DYNAMIC_LAYER(DynIntLayer, int)
DYNAMIC_LAYER(DynUIntLayer, unsigned int)
DYNAMIC_LAYER(DynShortLayer, short)
DYNAMIC_LAYER(DynUShortLayer, unsigned short)
DYNAMIC_LAYER(DynIntegerLayer, NSInteger)
DYNAMIC_LAYER(DynUIntegerLayer, NSUInteger)
DYNAMIC_LAYER(DynLongLongLayer, long long)
DYNAMIC_LAYER(DynFloatLayer, float)
DYNAMIC_LAYER(DynDoubleLayer, double)
DYNAMIC_LAYER(DynPointLayer, CGPoint)
DYNAMIC_LAYER(DynSizeLayer, CGSize)
DYNAMIC_LAYER(DynRectLayer, CGRect)
DYNAMIC_LAYER(DynTransformLayer, CATransform3D)

@interface DynObjectLayer : CALayer
@property (nonatomic, retain) NSString *p;
@end
@implementation DynObjectLayer
@dynamic p;
@end

/* Reads the fresh value and the value the setter kept.  A type that cannot
   be synthesised raises on the first message to the class, so both are
   reported as failures rather than stopping the file. */
#define ROUNDTRIP(cls, value, what) \
  @try \
    { \
      cls *l = [cls layer]; \
      PASS([l p] == 0, "a fresh " what " dynamic property is 0"); \
      [l setP: value]; \
      PASS([l p] == value, "a " what " dynamic property keeps what it is set to"); \
    } \
  @catch (NSException *e) \
    { \
      PASS(NO, "a fresh " what " dynamic property is 0"); \
      PASS(NO, "a " what " dynamic property keeps what it is set to"); \
    }

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the types a dynamic property can have")

  ROUNDTRIP(DynBoolLayer, YES, "BOOL")
  ROUNDTRIP(DynIntLayer, -42, "int")
  ROUNDTRIP(DynUIntLayer, 42u, "unsigned int")
  ROUNDTRIP(DynShortLayer, 7, "short")
  ROUNDTRIP(DynFloatLayer, 1.5f, "float")
  ROUNDTRIP(DynDoubleLayer, 2.25, "double")

  /* BOOL and unsigned char share an encoding where BOOL is a character
     type, so a character property has to keep its value rather than be
     reduced to 0 or 1. */
  testHopeful = YES;
  ROUNDTRIP(DynCharLayer, 'a', "char")
  ROUNDTRIP(DynUCharLayer, 200, "unsigned char")
  ROUNDTRIP(DynUShortLayer, 7u, "unsigned short")
  ROUNDTRIP(DynIntegerLayer, -1234567890123LL, "NSInteger")
  ROUNDTRIP(DynUIntegerLayer, 1234567890123ULL, "NSUInteger")
  ROUNDTRIP(DynLongLongLayer, -9007199254740993LL, "long long")
  testHopeful = NO;

  END_SET("the types a dynamic property can have")

  START_SET("a dynamic property holding an object")

  @try
    {
      DynObjectLayer *l = [DynObjectLayer layer];

      PASS([l p] == nil, "a fresh object dynamic property is nil");
      [l setP: @"hello"];
      PASS([[l p] isEqualToString: @"hello"],
           "an object dynamic property keeps what it is set to");
      [l setP: nil];
      PASS([l p] == nil, "an object dynamic property can be set back to nil");
    }
  @catch (NSException *e)
    {
      PASS(NO, "a fresh object dynamic property is nil");
      PASS(NO, "an object dynamic property keeps what it is set to");
      PASS(NO, "an object dynamic property can be set back to nil");
    }

  END_SET("a dynamic property holding an object")

  START_SET("dynamic properties through key-value coding")

  DynIntLayer *l = [DynIntLayer layer];

  [l setP: -42];
  PASS([[l valueForKey: @"p"] intValue] == -42,
       "valueForKey: reads a dynamic property");
  [l setValue: [NSNumber numberWithInt: 99] forKey: @"p"];
  PASS([l p] == 99, "setValue:forKey: writes a dynamic property");

  END_SET("dynamic properties through key-value coding")

  START_SET("dynamic properties belong to the layer")

  DynIntLayer *first = [DynIntLayer layer];
  DynIntLayer *second = [DynIntLayer layer];

  [first setP: 11];
  PASS([second p] == 0, "a second layer starts with its own value");
  [second setP: 22];
  PASS([first p] == 11, "setting one layer leaves the other alone");

  END_SET("dynamic properties belong to the layer")

  START_SET("a dynamic property holding a structure")

  DynPointLayer *point = [DynPointLayer layer];
  DynSizeLayer *size = [DynSizeLayer layer];
  DynRectLayer *rect = [DynRectLayer layer];
  DynTransformLayer *transform = [DynTransformLayer layer];

  PASS([point p].x == 0 && [point p].y == 0, "a fresh CGPoint property is 0");
  [point setP: CGPointMake(3, 4)];
  PASS([point p].x == 3 && [point p].y == 4,
       "a CGPoint dynamic property keeps what it is set to");

  PASS([size p].width == 0 && [size p].height == 0,
       "a fresh CGSize property is 0");
  [size setP: CGSizeMake(5, 6)];
  PASS([size p].width == 5 && [size p].height == 6,
       "a CGSize dynamic property keeps what it is set to");

  /* Not the zero rectangle: an unset one reads as the null rectangle. */
  PASS(CGRectIsNull([rect p]), "a fresh CGRect property is the null rectangle");
  [rect setP: CGRectMake(1, 2, 3, 4)];
  PASS(CGRectEqualToRect([rect p], CGRectMake(1, 2, 3, 4)),
       "a CGRect dynamic property keeps what it is set to");

  /* Nor the zero transform: an unset one reads as the identity. */
  PASS(CATransform3DIsIdentity([transform p]),
       "a fresh CATransform3D property is the identity");
  [transform setP: CATransform3DMakeScale(2, 3, 4)];
  PASS([transform p].m11 == 2 && [transform p].m22 == 3
       && [transform p].m33 == 4,
       "a CATransform3D dynamic property keeps what it is set to");

  END_SET("a dynamic property holding a structure")

  START_SET("a structure property set by its key")

  DynPointLayer *l = [DynPointLayer layer];
  CGPoint p = CGPointMake(7, 8);

  [l setValue: [NSValue valueWithBytes: &p objCType: @encode(CGPoint)]
       forKey: @"p"];
  PASS([l p].x == 7 && [l p].y == 8,
       "a structure set by its key reaches the property");
  PASS([l valueForKey: @"p"] != nil, "and can be read back by key");

  END_SET("a structure property set by its key")

  [pool release];
  return 0;
}
