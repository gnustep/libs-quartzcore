/* CAValueFunction.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: June 2012

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

#import "QuartzCore/CAValueFunction.h"

/* The functions, built once and keyed by name.  Building all of them up
   front leaves the table read-only afterwards, so a lookup needs no lock. */
static NSDictionary *functionsByName = nil;

@implementation CAValueFunction

+ (void) initialize
{
  if (self != [CAValueFunction class] || functionsByName != nil)
    {
      return;
    }

  NSArray *names = [NSArray arrayWithObjects:
    kCAValueFunctionRotateX, kCAValueFunctionRotateY,
    kCAValueFunctionRotateZ, kCAValueFunctionScale,
    kCAValueFunctionScaleX, kCAValueFunctionScaleY,
    kCAValueFunctionScaleZ, kCAValueFunctionTranslate,
    kCAValueFunctionTranslateX, kCAValueFunctionTranslateY,
    kCAValueFunctionTranslateZ, nil];
  NSMutableDictionary *table;
  NSEnumerator *e;
  NSString *name;

  table = [[NSMutableDictionary alloc] initWithCapacity: [names count]];
  e = [names objectEnumerator];
  while ((name = [e nextObject]) != nil)
    {
      CAValueFunction *function = [[CAValueFunction alloc] init];

      function->_name = [name copy];
      [table setObject: function forKey: name];
      [function release];
    }

  functionsByName = [table copy];
  [table release];
}

+ (id) functionWithName: (NSString *)name
{
  if (name == nil)
    {
      return nil;
    }

  return [functionsByName objectForKey: name];
}

- (void) dealloc
{
  [_name release];
  [super dealloc];
}

- (NSString *) name
{
  return _name;
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  self = [super init];
  if (self == nil)
    {
      return nil;
    }

  _name = [[aDecoder decodeObjectForKey: @"name"] copy];

  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeObject: _name forKey: @"name"];
}

@end

NSString *const kCAValueFunctionRotateX = @"rotateX";
NSString *const kCAValueFunctionRotateY = @"rotateY";
NSString *const kCAValueFunctionRotateZ = @"rotateZ";
                                            
NSString *const kCAValueFunctionScale = @"scale";
NSString *const kCAValueFunctionScaleX = @"scaleX";
NSString *const kCAValueFunctionScaleY = @"scaleY";
NSString *const kCAValueFunctionScaleZ = @"scaleZ";
                                            
NSString *const kCAValueFunctionTranslate = @"translate";
NSString *const kCAValueFunctionTranslateX = @"translateX";
NSString *const kCAValueFunctionTranslateY = @"translateY";
NSString *const kCAValueFunctionTranslateZ = @"translateZ";
