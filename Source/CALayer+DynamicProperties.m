/* CALayer+DynamicProperties.m

   Copyright (C) 2012 Free Software Foundation, Inc.
   
   Author: Ivan Vučica <ivan@vucica.net>
   Date: August 2012

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

/* Based in part on work by Rich Warren:
   http://www.freelancemadscience.com/fmslabs_blog/2012/1/25/automatically-syncing-user-defaults.html
   */
#import <Foundation/Foundation.h>
#import "CALayer+DynamicProperties.h"
#import <objc/runtime.h>

static NSMutableDictionary *accessorNameToPropertyNameDict;

@implementation CALayer (DynamicProperties)

// TODO: look into switching to Dynamic Method Resolution and using +resolveInstanceMethod:.
+ (void) _dynamicallyCreateProperty: (objc_property_t)property
{
  if(!accessorNameToPropertyNameDict)
    {
      accessorNameToPropertyNameDict = [[NSMutableDictionary alloc] init];
    }

  NSString* name = [NSString stringWithCString: property_getName(property)
                                      encoding: NSASCIIStringEncoding];

  NSDictionary* attributes = [self _dynamicPropertyProcessAttributes: property];

  // create the method names
  NSString* getterName = [attributes valueForKey: @"getter"];
  if (getterName == nil)
    {
      getterName = name;
    }

  [accessorNameToPropertyNameDict setValue: name forKey: getterName];

  NSString* setterName = [attributes valueForKey: @"setter"];

  if (setterName == nil)
    {
      setterName = [NSString stringWithFormat: @"set%@%@:",
                    [[name substringToIndex: 1] uppercaseString],
                    [name substringFromIndex: 1]];
    }
  [accessorNameToPropertyNameDict setValue: name forKey: setterName];

  // Set the types
  NSString* type = [attributes valueForKey: @"type"];
  NSString* getterTypes = [NSString stringWithFormat: @"%@@:", type];
  NSString* setterTypes = [NSString stringWithFormat: @"v@:%@", type];

  NSString* key = [NSString stringWithFormat: @"dynamicproperty_%@_%@",
                   NSStringFromClass([self class]),
                   name];

  IMP getter =  [self _getterForKey: key type: type];
  IMP setter = [self _setterForKey: key type: type];

  // Add getter
  BOOL success;
  success = class_addMethod([self class],
                            NSSelectorFromString(getterName),
                            getter,
                            [getterTypes cStringUsingEncoding: NSASCIIStringEncoding]);

  if (!success)
    {
      [NSException raise: NSGenericException
                  format: @"Could not add method %@", getterName];
    }

  // Add setter
  success = class_addMethod([self class],
                            NSSelectorFromString(setterName),
                            setter,
                            [setterTypes cStringUsingEncoding: NSASCIIStringEncoding]);

  if (!success)
    {
      [NSException raise: NSGenericException
                  format: @"Could not add method %@", setterName];
    }
}

+ (NSDictionary *) _dynamicPropertyProcessAttributes: (objc_property_t)property
{
    NSString * attributes = [NSString stringWithCString: property_getAttributes(property)
                                               encoding: NSASCIIStringEncoding];

    NSArray * components = [attributes componentsSeparatedByString:@","];
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:3];

    for (NSString* attribute in components)
      {
        if ([attribute hasPrefix: @"T"])
          {
            [dict setObject: [attribute substringFromIndex: 1]
                     forKey: @"type"];
          }
        else if ([attribute hasPrefix: @"G"])
          {
            [dict setObject: [attribute substringFromIndex: 1]
                     forKey: @"getter"];
          }
        else if ([attribute hasPrefix: @"S"])
          {
            [dict setObject: [attribute substringFromIndex: 1]
                     forKey: @"setter"];
          }
      }

    return [NSDictionary dictionaryWithDictionary:dict];
}

+ (IMP) _getterForKey: (NSString *)key type: (NSString *)type
{
  if ([type hasPrefix: @"@"])
    {
      /* Objects */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertyGetterForObjects));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"c"] || [type hasPrefix: @"C"])
    {
      /* BOOL */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertyGetterForBooleans));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"d"])
    {
      /* doubles */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertyGetterForDoubles));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"f"])
    {
      /* floats */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertyGetterForFloats));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"i"])
    {
      /* signed integers */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertyGetterForIntegers));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"I"])
    {
      /* unsigned integers */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertyGetterForUnsignedIntegers));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"s"])
    {
      /* short integers */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertyGetterForShortIntegers));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"l"])
    {
      /* long integers */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertyGetterForLongIntegers));
      return method_getImplementation(method);
    }

  [NSException raise: NSGenericException
              format: @"%@ is not a supported data type for dynamic synthesis", type];

  return nil;
}

+ (IMP) _setterForKey: (NSString *)key type: (NSString *)type
{
  if ([type hasPrefix: @"@"])
    {
      /* Objects */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertySetterForObjects:));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"c"] || [type hasPrefix: @"C"])
    {
      /* BOOL */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertySetterForBooleans:));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"d"])
    {
      /* doubles */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertySetterForDoubles:));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"f"])
    {
      /* floats */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertySetterForFloats:));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"i"])
    {
      /* signed integers */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertySetterForIntegers:));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"I"])
    {
      /* unsigned integers */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertySetterForUnsignedIntegers:));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"s"])
    {
      /* short integers */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertySetterForShortIntegers:));
      return method_getImplementation(method);
    }

  if ([type hasPrefix: @"l"])
    {
      /* long integers */
      Method method = class_getInstanceMethod([self class],
                                              @selector(_dynamicPropertySetterForLongIntegers:));
      return method_getImplementation(method);
    }

  [NSException raise: NSGenericException
              format: @"%@ is not a supported data type for dynamic synthesis", type];

  return nil;
}

- (id) _dynamicPropertyGetterForObjects
{
  return [_dynamicPropertyValueDict valueForKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]];
}

- (void) _dynamicPropertySetterForObjects: (id)object
{
  [_dynamicPropertyValueDict setValue: object forKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]];
}

- (BOOL) _dynamicPropertyGetterForBooleans
{
  return [[_dynamicPropertyValueDict valueForKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]] boolValue];
}

- (void) _dynamicPropertySetterForBooleans: (BOOL)object
{
  [_dynamicPropertyValueDict setValue: [NSNumber numberWithBool: object] forKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]];
}

- (double) _dynamicPropertyGetterForDoubles
{
  return [[_dynamicPropertyValueDict valueForKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]] doubleValue];
}

- (void) _dynamicPropertySetterForDoubles: (double)number
{
  [_dynamicPropertyValueDict setValue: [NSNumber numberWithDouble: number] forKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]];
}

- (float) _dynamicPropertyGetterForFloats
{
  return [[_dynamicPropertyValueDict valueForKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]] floatValue];
}

- (void) _dynamicPropertySetterForFloats: (float)number
{
  [_dynamicPropertyValueDict setValue: [NSNumber numberWithFloat: number] forKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]];
}

- (int) _dynamicPropertyGetterForIntegers
{
  return [[_dynamicPropertyValueDict valueForKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]] intValue];
}

- (void) _dynamicPropertySetterForIntegers: (int)number
{
  [_dynamicPropertyValueDict setValue: [NSNumber numberWithInt: number] forKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]];
}

- (unsigned int) _dynamicPropertyGetterForUnsignedIntegers
{
  return [[_dynamicPropertyValueDict valueForKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]] unsignedIntValue];
}

- (void) _dynamicPropertySetterForUnsignedIntegers: (unsigned int)number
{
  [_dynamicPropertyValueDict setValue: [NSNumber numberWithUnsignedInt: number] forKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]];
}

- (short int) _dynamicPropertyGetterForShortIntegers
{
  return [[_dynamicPropertyValueDict valueForKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]] shortValue];
}

- (void) _dynamicPropertySetterForShortIntegers: (short int)number
{
  [_dynamicPropertyValueDict setValue: [NSNumber numberWithShort: number] forKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]];
}

- (long int) _dynamicPropertyGetterForLongIntegers
{
  return [[_dynamicPropertyValueDict valueForKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]] longValue];
}

- (void) _dynamicPropertySetterForLongIntegers: (long int)number
{
  [_dynamicPropertyValueDict setValue: [NSNumber numberWithLong: number] forKey: [accessorNameToPropertyNameDict valueForKey: NSStringFromSelector(_cmd)]];
}
@end
