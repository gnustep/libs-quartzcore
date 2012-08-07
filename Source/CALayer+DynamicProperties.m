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

@implementation CALayer (DynamicProperties)

+ (void) _dynamicallyCreateProperty: (objc_property_t)property
{
    
    NSString* name = [NSString stringWithCString:property_getName(property)
                                        encoding:NSASCIIStringEncoding];
    
    NSDictionary* attributes = [self _dynamicPropertyProcessAttributes: property];
    
    // create the method names
    NSString* getterName = [attributes valueForKey:@"getter"];
    
    if (getterName == nil)
      {
        getterName = name;
      }
    
    NSString* setterName = [attributes valueForKey:@"setter"];
    
    if (setterName == nil)
      {
        setterName = [NSString stringWithFormat:@"set%@%@:",
                      [[name substringToIndex: 1] uppercaseString],
                      [name substringFromIndex: 1]];
      }
    
    
    // Set the types
    NSString* type = [attributes valueForKey:@"type"];
    NSString* getterTypes = [NSString stringWithFormat:@"%@@:", type];
    NSString* setterTypes = [NSString stringWithFormat:@"v@:%@", type];
    
    NSString* key = [NSString stringWithFormat:@"dynamicproperty_%@_%@",
                     NSStringFromClass([self class]),
                     name];
        
    IMP getter =  [self _getterForKey: key type: type];
    IMP setter = [self _setterForKey: key type: type];
    
    // Add getter
    BOOL success;
    success = class_addMethod([self class],
                              NSSelectorFromString(getterName),
                              getter,
                              [getterTypes cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if (!success)
      {
        [NSException raise:NSGenericException 
                    format:@"Could not add method %@", getterName];

      }
    
    // Add setter
    success = class_addMethod([self class],
                              NSSelectorFromString(setterName),
                              setter,
                              [setterTypes cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if (!success)
      {
        [NSException raise:NSGenericException 
                    format:@"Could not add method %@", setterName];
        
      }
    
}


+ (NSDictionary *) _dynamicPropertyProcessAttributes: (objc_property_t)property {
    
    NSString * attributes = [NSString stringWithCString: property_getAttributes(property)
                                               encoding: NSASCIIStringEncoding];
    
    NSArray * components = [attributes componentsSeparatedByString:@","];
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    for (NSString* attribute in components)
      {
        if ([attribute hasPrefix:@"T"])
          {
            [dict setObject: [attribute substringFromIndex:1]
                     forKey: @"type"];
          }
        else if ([attribute hasPrefix:@"G"])
          {
            [dict setObject: [attribute substringFromIndex:1]
                     forKey: @"getter"];
          }
        else if ([attribute hasPrefix:@"S"]) {
            
            [dict setObject:[attribute substringFromIndex:1]
                     forKey:@"setter"];
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
  
  [NSException raise: NSGenericException
              format: @"%@ is not a supported data type for dynamic synthesis", type];
  
  return nil;
}

- (id) _dynamicPropertyGetterForObjects
{
#if 0
  return [dynamicPropertyValueDict valueForKey: NSStringFromSelector(_cmd)];
#else
  return 0;
#endif
}

- (void) _dynamicPropertySetterForObjects: (id)object
{
#if 0
  [dynamicPropertyValueDict setValue: object forKey: NSStringFromSelector(_cmd)];
#else
  return;
#endif
}
@end
