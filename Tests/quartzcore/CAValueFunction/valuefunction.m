/* CAValueFunction: what each name answers, what an unknown name answers,
   and that a function survives being archived.
   Expected values checked against Apple QuartzCore.

   The names are read through the constants rather than written out, so this
   checks the lookup and not the value of any constant. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAValueFunction.h>
#import <QuartzCore/CAAnimation.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  NSArray *names = [NSArray arrayWithObjects:
    kCAValueFunctionRotateX, kCAValueFunctionRotateY,
    kCAValueFunctionRotateZ, kCAValueFunctionScale,
    kCAValueFunctionScaleX, kCAValueFunctionScaleY,
    kCAValueFunctionScaleZ, kCAValueFunctionTranslate,
    kCAValueFunctionTranslateX, kCAValueFunctionTranslateY,
    kCAValueFunctionTranslateZ, nil];

  START_SET("the function of each name")

  NSEnumerator *e = [names objectEnumerator];
  NSString *name;
  unsigned found = 0;
  unsigned named = 0;

  while ((name = [e nextObject]) != nil)
    {
      CAValueFunction *f = [CAValueFunction functionWithName: name];

      if (f != nil)
        {
          found++;
          if ([[f name] isEqualToString: name])
            {
              named++;
            }
        }
    }

  PASS([names count] == 11, "there are eleven value function names");
  PASS(found == 11, "every name answers a function");
  PASS(named == 11, "every function answers the name it was asked for");

  END_SET("the function of each name")

  START_SET("a name with no function")

  PASS([CAValueFunction functionWithName: @"notAValueFunction"] == nil,
       "a name that is not a function answers nothing");
  PASS([CAValueFunction functionWithName: @""] == nil,
       "an empty name answers nothing");

  END_SET("a name with no function")

  START_SET("the same name answers the same function")

  CAValueFunction *first = [CAValueFunction functionWithName:
                              kCAValueFunctionRotateX];
  CAValueFunction *second = [CAValueFunction functionWithName:
                               kCAValueFunctionRotateX];
  CAValueFunction *other = [CAValueFunction functionWithName:
                              kCAValueFunctionRotateY];

  PASS(first == second, "asking twice answers the same object");
  PASS(first != other, "two names answer two objects");

  END_SET("the same name answers the same function")

  START_SET("archiving a function")

  CAValueFunction *f = [CAValueFunction functionWithName:
                          kCAValueFunctionScale];

  PASS([f conformsToProtocol: @protocol(NSCoding)],
       "a value function can be archived");

  NSData *d = [NSKeyedArchiver archivedDataWithRootObject: f];
  CAValueFunction *back = [NSKeyedUnarchiver unarchiveObjectWithData: d];

  PASS([d length] > 0, "archiving a value function writes something");
  PASS([[back name] isEqualToString: kCAValueFunctionScale],
       "an unarchived function keeps its name");

  END_SET("archiving a function")

  START_SET("a function on an animation")

  CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:
                              @"transform"];

  PASS([anim valueFunction] == nil,
       "an animation starts with no value function");
  [anim setValueFunction: [CAValueFunction functionWithName:
                             kCAValueFunctionRotateZ]];
  PASS([[[anim valueFunction] name] isEqualToString:
          kCAValueFunctionRotateZ],
       "an animation keeps the value function it is given");

  END_SET("a function on an animation")

  [pool release];
  return 0;
}
