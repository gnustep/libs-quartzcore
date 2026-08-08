/* CAConstraint.m

   Copyright (C) 2026 Free Software Foundation, Inc.

   Author: Todd White <todd.white@thalion.global>
   Date: August 2026

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
#import "QuartzCore/CAConstraint.h"
#import "QuartzCore/CALayer.h"
#import <stdlib.h>

@implementation CAConstraint
@synthesize attribute=_attribute;
@synthesize sourceAttribute=_sourceAttribute;
@synthesize sourceName=_sourceName;
@synthesize scale=_scale;
@synthesize offset=_offset;

+ (id) constraintWithAttribute: (CAConstraintAttribute)attr
                    relativeTo: (NSString *)srcId
                     attribute: (CAConstraintAttribute)srcAttr
{
  return [self constraintWithAttribute: attr
                            relativeTo: srcId
                             attribute: srcAttr
                                 scale: 1.0
                                offset: 0.0];
}

+ (id) constraintWithAttribute: (CAConstraintAttribute)attr
                    relativeTo: (NSString *)srcId
                     attribute: (CAConstraintAttribute)srcAttr
                        offset: (CGFloat)c
{
  return [self constraintWithAttribute: attr
                            relativeTo: srcId
                             attribute: srcAttr
                                 scale: 1.0
                                offset: c];
}

+ (id) constraintWithAttribute: (CAConstraintAttribute)attr
                    relativeTo: (NSString *)srcId
                     attribute: (CAConstraintAttribute)srcAttr
                         scale: (CGFloat)m
                        offset: (CGFloat)c
{
  return [[[self alloc] initWithAttribute: attr
                               relativeTo: srcId
                                attribute: srcAttr
                                    scale: m
                                   offset: c] autorelease];
}

- (id) initWithAttribute: (CAConstraintAttribute)attr
              relativeTo: (NSString *)srcId
               attribute: (CAConstraintAttribute)srcAttr
                   scale: (CGFloat)m
                  offset: (CGFloat)c
{
  self = [super init];
  if (!self)
    return nil;

  _attribute = attr;
  _sourceAttribute = srcAttr;
  _sourceName = [srcId copy];
  _scale = m;
  _offset = c;

  return self;
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  self = [super init];
  if (!self)
    return nil;

  _attribute = [aDecoder decodeIntForKey: @"attribute"];
  _sourceAttribute = [aDecoder decodeIntForKey: @"sourceAttribute"];
  _sourceName = [[aDecoder decodeObjectForKey: @"sourceName"] copy];
  _scale = [aDecoder decodeDoubleForKey: @"scale"];
  _offset = [aDecoder decodeDoubleForKey: @"offset"];

  return self;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeInt: _attribute forKey: @"attribute"];
  [aCoder encodeInt: _sourceAttribute forKey: @"sourceAttribute"];
  [aCoder encodeObject: _sourceName forKey: @"sourceName"];
  [aCoder encodeDouble: _scale forKey: @"scale"];
  [aCoder encodeDouble: _offset forKey: @"offset"];
}

- (void) dealloc
{
  [_sourceName release];

  [super dealloc];
}

@end

/* *********************************** */

/* The attributes of an axis in the order they are preferred when an axis
   carries more than the two relationships it needs. */
typedef enum
{
  GSConstraintMin = 0,
  GSConstraintMid = 1,
  GSConstraintMax = 2,
  GSConstraintSize = 3
} GSConstraintRank;

static BOOL isVerticalAttribute(CAConstraintAttribute attribute)
{
  return attribute >= kCAConstraintMinY;
}

static GSConstraintRank rankOfAttribute(CAConstraintAttribute attribute)
{
  if (isVerticalAttribute(attribute))
    return (GSConstraintRank)(attribute - kCAConstraintMinY);

  return (GSConstraintRank)attribute;
}

static CGFloat valueOfAttribute(CGRect rect, CAConstraintAttribute attribute)
{
  switch (rankOfAttribute(attribute))
    {
      case GSConstraintMin:
        return isVerticalAttribute(attribute) ? CGRectGetMinY(rect)
                                              : CGRectGetMinX(rect);
      case GSConstraintMid:
        return isVerticalAttribute(attribute) ? CGRectGetMidY(rect)
                                              : CGRectGetMidX(rect);
      case GSConstraintMax:
        return isVerticalAttribute(attribute) ? CGRectGetMaxY(rect)
                                              : CGRectGetMaxX(rect);
      case GSConstraintSize:
        return isVerticalAttribute(attribute) ? CGRectGetHeight(rect)
                                              : CGRectGetWidth(rect);
    }

  return 0.0;
}

/* Solve an axis from the two relationships it was given.  'a' holds the
   lower ranked of the two. */
static void solveAxis(GSConstraintRank rankA, CGFloat valueA,
                      GSConstraintRank rankB, CGFloat valueB,
                      CGFloat *origin, CGFloat *size)
{
  if (rankA == GSConstraintMin && rankB == GSConstraintMid)
    {
      *size = 2 * (valueB - valueA);
      *origin = valueA;
    }
  else if (rankA == GSConstraintMin && rankB == GSConstraintMax)
    {
      *size = valueB - valueA;
      *origin = valueA;
    }
  else if (rankA == GSConstraintMin && rankB == GSConstraintSize)
    {
      *size = valueB;
      *origin = valueA;
    }
  else if (rankA == GSConstraintMid && rankB == GSConstraintMax)
    {
      *size = 2 * (valueB - valueA);
      *origin = valueB - *size;
    }
  else if (rankA == GSConstraintMid && rankB == GSConstraintSize)
    {
      *size = valueB;
      *origin = valueA - *size / 2;
    }
  else if (rankA == GSConstraintMax && rankB == GSConstraintSize)
    {
      *size = valueB;
      *origin = valueA - *size;
    }
}

/* One relationship, with the size the layer already has as the other. */
static void solveAxisFromOne(GSConstraintRank rank, CGFloat value,
                             CGFloat *origin, CGFloat size)
{
  switch (rank)
    {
      case GSConstraintMin: *origin = value; break;
      case GSConstraintMid: *origin = value - size / 2; break;
      case GSConstraintMax: *origin = value - size; break;
      case GSConstraintSize: break;
    }
}

/* What is known about one sublayer while its superlayer is being laid out. */
typedef struct
{
  CGRect frame;
  BOOL constrainedHorizontally;
  BOOL constrainedVertically;
  BOOL laidOutHorizontally;
  BOOL laidOutVertically;
} GSConstraintLayoutState;

static BOOL axisIsLaidOut(GSConstraintLayoutState *state, BOOL vertical)
{
  return vertical ? state->laidOutVertically : state->laidOutHorizontally;
}

static BOOL axisIsConstrained(GSConstraintLayoutState *state, BOOL vertical)
{
  return vertical ? state->constrainedVertically : state->constrainedHorizontally;
}

/* The sublayer of that name, or nil.  Where two carry the same name the
   later one answers. */
static NSUInteger indexOfSublayerNamed(NSArray *sublayers, NSString *name,
                                       NSUInteger except)
{
  NSUInteger index;
  NSUInteger found = NSNotFound;

  for (index = 0; index < [sublayers count]; index++)
    {
      if (index == except)
        continue;
      if ([name isEqualToString: [[sublayers objectAtIndex: index] name]])
        found = index;
    }

  return found;
}

/* Try to lay one axis of one sublayer out.  Answers NO while it is waiting
   for a sibling the axis is measured against. */
static BOOL layOutAxis(NSArray *sublayers, GSConstraintLayoutState *state,
                       NSUInteger index, CGRect bounds, BOOL vertical)
{
  CALayer *layer = [sublayers objectAtIndex: index];
  NSArray *constraints = [layer constraints];
  NSUInteger count = [constraints count];
  GSConstraintRank *ranks;
  CGFloat *values;
  NSUInteger found = 0;
  NSUInteger i;
  BOOL waiting = NO;
  CGRect frame = state[index].frame;
  CGFloat origin;
  CGFloat size;

  ranks = calloc(count ? count : 1, sizeof(*ranks));
  values = calloc(count ? count : 1, sizeof(*values));
  if (!ranks || !values)
    {
      free(ranks);
      free(values);
      return YES;
    }

  for (i = 0; i < count && !waiting; i++)
    {
      CAConstraint *constraint = [constraints objectAtIndex: i];
      CAConstraintAttribute attribute = [constraint attribute];
      CAConstraintAttribute sourceAttribute;
      NSUInteger source;
      CGFloat value;

      if (isVerticalAttribute(attribute) != vertical)
        continue;

      sourceAttribute = [constraint sourceAttribute];
      if ([[constraint sourceName] isEqualToString: @"superlayer"])
        {
          value = valueOfAttribute(bounds, sourceAttribute);
        }
      else
        {
          BOOL sourceVertical = isVerticalAttribute(sourceAttribute);

          source = indexOfSublayerNamed(sublayers, [constraint sourceName],
                                        index);
          /* A layer nothing answers to, and a layer that is not laid out on
             the axis being read, leave the relationship out altogether. */
          if (source == NSNotFound
              || !axisIsConstrained(&state[source], sourceVertical))
            continue;

          if (!axisIsLaidOut(&state[source], sourceVertical))
            {
              waiting = YES;
              continue;
            }

          value = valueOfAttribute(state[source].frame, sourceAttribute);
        }

      ranks[found] = rankOfAttribute(attribute);
      values[found] = value * [constraint scale] + [constraint offset];
      found++;
    }

  if (waiting)
    {
      free(ranks);
      free(values);
      return NO;
    }

  origin = vertical ? CGRectGetMinY(frame) : CGRectGetMinX(frame);
  size = vertical ? CGRectGetHeight(frame) : CGRectGetWidth(frame);

  /* The same attribute twice describes no layout at all. */
  for (i = 0; i < found; i++)
    {
      NSUInteger j;

      for (j = i + 1; j < found; j++)
        {
          if (ranks[i] == ranks[j])
            {
              found = 0;
              i = 0;
              break;
            }
        }
    }

  if (found > 0)
    {
      /* The relationship given last decides the axis; where there are others
         it is paired with the lowest ranked of them. */
      NSUInteger last = found - 1;
      NSUInteger partner = NSNotFound;

      for (i = 0; i < last; i++)
        {
          if (partner == NSNotFound || ranks[i] < ranks[partner])
            partner = i;
        }

      if (partner == NSNotFound)
        {
          /* A size on its own leaves the layer where it is. */
          solveAxisFromOne(ranks[last], values[last], &origin, size);
        }
      else if (ranks[partner] < ranks[last])
        {
          solveAxis(ranks[partner], values[partner], ranks[last], values[last],
                    &origin, &size);
        }
      else
        {
          solveAxis(ranks[last], values[last], ranks[partner], values[partner],
                    &origin, &size);
        }
    }

  if (vertical)
    {
      frame.origin.y = origin;
      frame.size.height = size;
    }
  else
    {
      frame.origin.x = origin;
      frame.size.width = size;
    }
  state[index].frame = frame;

  free(ranks);
  free(values);
  return YES;
}

@implementation CAConstraintLayoutManager

+ (id) layoutManager
{
  static CAConstraintLayoutManager *shared = nil;

  if (!shared)
    shared = [[self alloc] init];

  return shared;
}

- (void) layoutSublayersOfLayer: (CALayer *)layer
{
  NSArray *sublayers = [layer sublayers];
  NSUInteger count = [sublayers count];
  CGRect bounds = [layer bounds];
  GSConstraintLayoutState *state;
  NSUInteger index;
  BOOL settling = YES;

  if (count == 0)
    return;

  state = calloc(count, sizeof(*state));
  if (!state)
    return;

  for (index = 0; index < count; index++)
    {
      CALayer *sublayer = [sublayers objectAtIndex: index];
      NSEnumerator *enumerator = [[sublayer constraints] objectEnumerator];
      CAConstraint *constraint;

      state[index].frame = [sublayer frame];
      while ((constraint = [enumerator nextObject]) != nil)
        {
          if (isVerticalAttribute([constraint attribute]))
            state[index].constrainedVertically = YES;
          else
            state[index].constrainedHorizontally = YES;
        }
      state[index].laidOutHorizontally = !state[index].constrainedHorizontally;
      state[index].laidOutVertically = !state[index].constrainedVertically;
    }

  /* A layer measured against a sibling waits for that sibling, whatever
     order the two are in.  Constraints that lead in a circle never settle,
     and those layers are left as they are. */
  while (settling)
    {
      settling = NO;
      for (index = 0; index < count; index++)
        {
          if (!state[index].laidOutHorizontally
              && layOutAxis(sublayers, state, index, bounds, NO))
            {
              state[index].laidOutHorizontally = YES;
              settling = YES;
            }
          if (!state[index].laidOutVertically
              && layOutAxis(sublayers, state, index, bounds, YES))
            {
              state[index].laidOutVertically = YES;
              settling = YES;
            }
        }
    }

  for (index = 0; index < count; index++)
    {
      CALayer *sublayer = [sublayers objectAtIndex: index];

      if (!CGRectEqualToRect(state[index].frame, [sublayer frame]))
        [sublayer setFrame: state[index].frame];
    }

  free(state);
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
