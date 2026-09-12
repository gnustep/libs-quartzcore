/* CAShapeLayer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>

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

#import "QuartzCore/CAShapeLayer.h"
#import "CALayer+FrameworkPrivate.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

NSString *const kCAFillRuleNonZero = @"non-zero";
NSString *const kCAFillRuleEvenOdd = @"even-odd";
                                    
NSString *const kCALineJoinMiter = @"miter";
NSString *const kCALineJoinRound = @"round";
NSString *const kCALineJoinBevel = @"bevel";
                                    
NSString *const kCALineCapButt = @"butt";
NSString *const kCALineCapRound = @"round";
NSString *const kCALineCapSquare = @"square";

static CGLineCap
CAShapeLayerLineCap(NSString *name)
{
  if ([name isEqualToString: kCALineCapRound])
    return kCGLineCapRound;
  if ([name isEqualToString: kCALineCapSquare])
    return kCGLineCapSquare;
  return kCGLineCapButt;
}

static CGLineJoin
CAShapeLayerLineJoin(NSString *name)
{
  if ([name isEqualToString: kCALineJoinRound])
    return kCGLineJoinRound;
  if ([name isEqualToString: kCALineJoinBevel])
    return kCGLineJoinBevel;
  return kCGLineJoinMiter;
}

/* ******************** */
/* MARK: - Path trimming */

/* How many pieces a curve is cut into to measure how long it is.  A curve
   has no closed form for its length, so it is walked as this many chords. */
#define CAShapeCurveSteps 32

/* A path is walked as a list of segments: a line or a curve, each ending
   where the next one starts.  A quadratic curve is kept as the cubic that
   draws it.  A line leaves its two control points on its ends. */
typedef struct
{
  CGPoint points[4];
  BOOL curved;
  BOOL opensSubpath;
  CGFloat length;
} CAShapeSegment;

typedef struct
{
  CAShapeSegment *segments;
  NSUInteger count;
  NSUInteger capacity;
  CGPoint current;
  CGPoint subpathStart;
  BOOL moved;
} CAShapeSegments;

static CGPoint
CAShapePointBetween(CGPoint from, CGPoint to, CGFloat fraction)
{
  return CGPointMake(from.x + (to.x - from.x) * fraction,
                     from.y + (to.y - from.y) * fraction);
}

/* Where a curve is when it is FRACTION of the way through its parameter,
   which is not the same as that far along its length. */
static CGPoint
CAShapeCurvePoint(const CGPoint *p, CGFloat t)
{
  CGFloat u = 1.0 - t;

  return CGPointMake(u * u * u * p[0].x + 3 * u * u * t * p[1].x
                       + 3 * u * t * t * p[2].x + t * t * t * p[3].x,
                     u * u * u * p[0].y + 3 * u * u * t * p[1].y
                       + 3 * u * t * t * p[2].y + t * t * t * p[3].y);
}

/* Cut a curve in two at T, giving the curve up to that point and the curve
   from it.  Neither answer may be the curve that was passed in. */
static void
CAShapeSplitCurve(const CGPoint *p, CGFloat t, CGPoint *before, CGPoint *after)
{
  CGPoint ab = CAShapePointBetween(p[0], p[1], t);
  CGPoint bc = CAShapePointBetween(p[1], p[2], t);
  CGPoint cd = CAShapePointBetween(p[2], p[3], t);
  CGPoint abbc = CAShapePointBetween(ab, bc, t);
  CGPoint bccd = CAShapePointBetween(bc, cd, t);
  CGPoint middle = CAShapePointBetween(abbc, bccd, t);

  before[0] = p[0];
  before[1] = ab;
  before[2] = abbc;
  before[3] = middle;
  after[0] = middle;
  after[1] = bccd;
  after[2] = cd;
  after[3] = p[3];
}

/* The parameter at which a curve has covered DISTANCE of its length. */
static CGFloat
CAShapeCurveFractionForLength(const CGPoint *p, CGFloat distance)
{
  CGPoint previous = p[0];
  CGFloat walked = 0.0;
  int i;

  for (i = 1; i <= CAShapeCurveSteps; i++)
    {
      CGFloat t = (CGFloat)i / CAShapeCurveSteps;
      CGPoint point = CAShapeCurvePoint(p, t);
      CGFloat step = hypot(point.x - previous.x, point.y - previous.y);

      if (walked + step >= distance)
        {
          CGFloat within = step > 0.0 ? (distance - walked) / step : 0.0;

          return ((CGFloat)(i - 1) + within) / CAShapeCurveSteps;
        }
      walked += step;
      previous = point;
    }
  return 1.0;
}

static CGFloat
CAShapeSegmentLength(const CAShapeSegment *segment)
{
  CGPoint previous = segment->points[0];
  CGFloat length = 0.0;
  int i;

  if (!segment->curved)
    {
      return hypot(segment->points[3].x - previous.x,
                   segment->points[3].y - previous.y);
    }

  for (i = 1; i <= CAShapeCurveSteps; i++)
    {
      CGPoint point = CAShapeCurvePoint(segment->points,
                                        (CGFloat)i / CAShapeCurveSteps);

      length += hypot(point.x - previous.x, point.y - previous.y);
      previous = point;
    }
  return length;
}

static void
CAShapeAddSegment(CAShapeSegments *list, CAShapeSegment segment)
{
  if (list->count == list->capacity)
    {
      list->capacity = list->capacity ? list->capacity * 2 : 8;
      list->segments = realloc(list->segments,
                               list->capacity * sizeof(CAShapeSegment));
    }

  segment.opensSubpath = list->moved;
  segment.length = CAShapeSegmentLength(&segment);
  list->moved = NO;
  list->segments[list->count++] = segment;
  list->current = segment.points[3];
}

static void
CAShapeAddLine(CAShapeSegments *list, CGPoint end)
{
  CAShapeSegment segment;

  segment.points[0] = list->current;
  segment.points[1] = list->current;
  segment.points[2] = end;
  segment.points[3] = end;
  segment.curved = NO;
  CAShapeAddSegment(list, segment);
}

static void
CAShapeCollectSegment(void *info, const CGPathElement *element)
{
  CAShapeSegments *list = (CAShapeSegments *)info;
  CAShapeSegment segment;

  switch (element->type)
    {
      case kCGPathElementMoveToPoint:
        list->current = element->points[0];
        list->subpathStart = list->current;
        list->moved = YES;
        break;

      case kCGPathElementAddLineToPoint:
        CAShapeAddLine(list, element->points[0]);
        break;

      case kCGPathElementAddQuadCurveToPoint:
        {
          CGPoint control = element->points[0];
          CGPoint end = element->points[1];

          segment.points[0] = list->current;
          segment.points[1] = CGPointMake(
            list->current.x + 2.0 / 3.0 * (control.x - list->current.x),
            list->current.y + 2.0 / 3.0 * (control.y - list->current.y));
          segment.points[2] = CGPointMake(
            end.x + 2.0 / 3.0 * (control.x - end.x),
            end.y + 2.0 / 3.0 * (control.y - end.y));
          segment.points[3] = end;
          segment.curved = YES;
          CAShapeAddSegment(list, segment);
          break;
        }

      case kCGPathElementAddCurveToPoint:
        segment.points[0] = list->current;
        segment.points[1] = element->points[0];
        segment.points[2] = element->points[1];
        segment.points[3] = element->points[2];
        segment.curved = YES;
        CAShapeAddSegment(list, segment);
        break;

      case kCGPathElementCloseSubpath:
        CAShapeAddLine(list, list->subpathStart);
        break;
    }
}

/* The piece of PATH between the two fractions of its length, which is what a
   stroke covers when strokeStart and strokeEnd are not the whole of it.  The
   answer belongs to the caller, and is an empty path where the two leave
   nothing between them. */
static CGPathRef
CAShapeLayerTrimmedPath(CGPathRef path, CGFloat start, CGFloat end)
{
  CAShapeSegments list;
  CGMutablePathRef trimmed;
  CGFloat total = 0.0;
  CGFloat walked = 0.0;
  CGFloat from, to;
  BOOL open = NO;
  NSUInteger i;

  memset(&list, 0, sizeof(list));
  CGPathApply(path, &list, CAShapeCollectSegment);
  for (i = 0; i < list.count; i++)
    {
      total += list.segments[i].length;
    }
  if (total <= 0.0)
    {
      free(list.segments);
      return NULL;
    }

  start = start < 0.0 ? 0.0 : (start > 1.0 ? 1.0 : start);
  end = end < 0.0 ? 0.0 : (end > 1.0 ? 1.0 : end);
  from = total * start;
  to = total * end;

  trimmed = CGPathCreateMutable();
  for (i = 0; i < list.count && from < to; i++)
    {
      CAShapeSegment *segment = &list.segments[i];
      CGFloat segmentStart = walked;
      CGFloat segmentEnd = walked + segment->length;
      CGFloat first, last, t0, t1;
      CGPoint piece[4], head[4], rest[4];

      walked = segmentEnd;
      if (segment->length <= 0.0 || segmentEnd <= from || segmentStart >= to)
        {
          open = NO;
          continue;
        }

      first = from > segmentStart ? from - segmentStart : 0.0;
      last = to < segmentEnd ? to - segmentStart : segment->length;

      if (segment->curved)
        {
          t0 = CAShapeCurveFractionForLength(segment->points, first);
          t1 = CAShapeCurveFractionForLength(segment->points, last);
          CAShapeSplitCurve(segment->points, t1, head, rest);
          CAShapeSplitCurve(head, t1 > 0.0 ? t0 / t1 : 0.0, rest, piece);
        }
      else
        {
          t0 = first / segment->length;
          t1 = last / segment->length;
          piece[0] = CAShapePointBetween(segment->points[0],
                                         segment->points[3], t0);
          piece[3] = CAShapePointBetween(segment->points[0],
                                         segment->points[3], t1);
        }

      if (!open || segment->opensSubpath)
        {
          CGPathMoveToPoint(trimmed, NULL, piece[0].x, piece[0].y);
          open = YES;
        }
      if (segment->curved)
        {
          CGPathAddCurveToPoint(trimmed, NULL, piece[1].x, piece[1].y,
                                piece[2].x, piece[2].y,
                                piece[3].x, piece[3].y);
        }
      else
        {
          CGPathAddLineToPoint(trimmed, NULL, piece[3].x, piece[3].y);
        }
    }

  free(list.segments);
  return trimmed;
}

@implementation CAShapeLayer
@synthesize path = _path;
@synthesize fillColor = _fillColor;
@synthesize fillRule = _fillRule;
@synthesize strokeColor = _strokeColor;
@synthesize strokeStart = _strokeStart;
@synthesize strokeEnd = _strokeEnd;
@synthesize lineWidth = _lineWidth;
@synthesize miterLimit = _miterLimit;
@synthesize lineCap = _lineCap;
@synthesize lineJoin = _lineJoin;
@synthesize lineDashPhase = _lineDashPhase;
@synthesize lineDashPattern = _lineDashPattern;

/* The three setters below notify by hand, as CALayer's colour setters do. */
+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *)key
{
  if ([key isEqualToString: @"path"]
      || [key isEqualToString: @"fillColor"]
      || [key isEqualToString: @"strokeColor"])
    {
      return NO;
    }

  return [super automaticallyNotifiesObserversForKey: key];
}

+ (id) defaultValueForKey: (NSString *)key
{
  if ([key isEqualToString: @"fillColor"])
    {
      /* opaque black, as for the colours CALayer hands out */
      return [(id)CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0) autorelease];
    }
  if ([key isEqualToString: @"fillRule"])
    {
      return kCAFillRuleNonZero;
    }
  if ([key isEqualToString: @"strokeEnd"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString: @"lineWidth"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString: @"miterLimit"])
    {
      return [NSNumber numberWithFloat: 10.0];
    }
  if ([key isEqualToString: @"lineCap"])
    {
      return kCALineCapButt;
    }
  if ([key isEqualToString: @"lineJoin"])
    {
      return kCALineJoinMiter;
    }

  return [super defaultValueForKey: key];
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      Class cls = [self class];

      [self setFillColor: (CGColorRef)[cls defaultValueForKey: @"fillColor"]];
      [self setFillRule: [cls defaultValueForKey: @"fillRule"]];
      [self setStrokeEnd:
        [[cls defaultValueForKey: @"strokeEnd"] floatValue]];
      [self setLineWidth:
        [[cls defaultValueForKey: @"lineWidth"] floatValue]];
      [self setMiterLimit:
        [[cls defaultValueForKey: @"miterLimit"] floatValue]];
      [self setLineCap: [cls defaultValueForKey: @"lineCap"]];
      [self setLineJoin: [cls defaultValueForKey: @"lineJoin"]];
    }
  return self;
}

/* Core Graphics types are not KVC-compliant, so the three below are reached
   by key the same way CALayer reaches its own colours. */
- (id) valueForUndefinedKey: (NSString *)key
{
  if ([key isEqualToString: @"path"])
    {
      return (id)[self path];
    }
  if ([key isEqualToString: @"fillColor"])
    {
      return (id)[self fillColor];
    }
  if ([key isEqualToString: @"strokeColor"])
    {
      return (id)[self strokeColor];
    }

  return [super valueForUndefinedKey: key];
}

- (void) setValue: (id)value forUndefinedKey: (NSString *)key
{
  if ([key isEqualToString: @"path"])
    {
      [self setPath: (CGPathRef)value];
      return;
    }
  if ([key isEqualToString: @"fillColor"])
    {
      [self setFillColor: (CGColorRef)value];
      return;
    }
  if ([key isEqualToString: @"strokeColor"])
    {
      [self setStrokeColor: (CGColorRef)value];
      return;
    }

  [super setValue: value forUndefinedKey: key];
}

- (void) dealloc
{
  CGPathRelease(_path);
  CGColorRelease(_fillColor);
  CGColorRelease(_strokeColor);
  [_fillRule release];
  [_lineCap release];
  [_lineJoin release];
  [_lineDashPattern release];

  [super dealloc];
}

/* The two colours and the path are owned by the layer, as they are on
   CALayer, so the caller may release its own reference. */
- (void) setPath: (CGPathRef)path
{
  if (path == _path)
    return;

  [self willChangeValueForKey: @"path"];
  CGPathRetain(path);
  CGPathRelease(_path);
  _path = path;
  [self didChangeValueForKey: @"path"];
}

- (void) setFillColor: (CGColorRef)fillColor
{
  if (fillColor == _fillColor)
    return;

  [self willChangeValueForKey: @"fillColor"];
  CGColorRetain(fillColor);
  CGColorRelease(_fillColor);
  _fillColor = fillColor;
  [self didChangeValueForKey: @"fillColor"];
}

- (void) setStrokeColor: (CGColorRef)strokeColor
{
  if (strokeColor == _strokeColor)
    return;

  [self willChangeValueForKey: @"strokeColor"];
  CGColorRetain(strokeColor);
  CGColorRelease(_strokeColor);
  _strokeColor = strokeColor;
  [self didChangeValueForKey: @"strokeColor"];
}

/* The path is drawn in the layer's own bounds coordinates, and is not cut to
   the bounds unless the layer masks to them. */
- (void) drawContentInContext: (CGContextRef)context
{
  if (_path == NULL)
    return;

  if (_fillColor)
    {
      CGContextAddPath(context, _path);
      CGContextSetFillColorWithColor(context, _fillColor);
      if ([_fillRule isEqualToString: kCAFillRuleEvenOdd])
        {
          CGContextEOFillPath(context);
        }
      else
        {
          CGContextFillPath(context);
        }
    }

  if (_strokeColor && _lineWidth > 0.0)
    {
      CGPathRef stroked = _path;
      CGPathRef trimmed = NULL;

      /* strokeStart and strokeEnd take a part of the path, which is built by
         walking it and keeping the piece between the two. */
      if (_strokeStart > 0.0 || _strokeEnd < 1.0)
        {
          trimmed = CAShapeLayerTrimmedPath(_path, _strokeStart, _strokeEnd);
          if (trimmed)
            {
              stroked = trimmed;
            }
        }

      CGContextAddPath(context, stroked);
      CGContextSetStrokeColorWithColor(context, _strokeColor);
      CGContextSetLineWidth(context, _lineWidth);
      CGContextSetMiterLimit(context, _miterLimit);
      CGContextSetLineCap(context, CAShapeLayerLineCap(_lineCap));
      CGContextSetLineJoin(context, CAShapeLayerLineJoin(_lineJoin));

      /* lineDashPattern holds the on and off lengths in user space, and
         lineDashPhase is how far into that pattern the stroke starts.  It is
         set on the context and left there, as Apple leaves it: a sublayer
         stroked after this one is dashed the same way. */
      if ([_lineDashPattern count] > 0)
        {
          NSUInteger count = [_lineDashPattern count];
          CGFloat *lengths = malloc(sizeof(CGFloat) * count);
          NSUInteger i;

          if (lengths != NULL)
            {
              for (i = 0; i < count; i++)
                {
                  lengths[i] = [[_lineDashPattern objectAtIndex: i]
                                 floatValue];
                }
              CGContextSetLineDash(context, _lineDashPhase, lengths, count);
              free(lengths);
            }
        }

      CGContextStrokePath(context);

      CGPathRelease(trimmed);
    }
}

@end
