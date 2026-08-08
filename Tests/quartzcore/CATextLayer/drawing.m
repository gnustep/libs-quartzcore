/* What a text layer draws when it is rendered into a context.  Every
   expected value here was measured against Apple QuartzCore, with a 160 by
   60 layer at the origin of a 200 by 100 context.

   CoreText and cairo rasterise a glyph differently in every particular, so
   what is asserted is which region is covered, where it sits in the bounds
   and what colour it is, never a pixel count or an exact box. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CATextLayer.h>
#import <CoreGraphics/CoreGraphics.h>
#include <CoreText/CoreText.h>
#include <string.h>

#define W 200
#define H 100
#define LAYER_W 160
#define LAYER_H 60

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef context;

  context = CGBitmapContextCreate(NULL, W, H, 8, W * 4, space,
#if GNUSTEP
                                  kCGImageAlphaPremultipliedFirst);
#else
                                  kCGImageAlphaPremultipliedLast);
#endif
  CGColorSpaceRelease(space);
  if (context)
    {
      memset(CGBitmapContextGetData(context), 0, W * H * 4);
    }
  return context;
}

/* Whether the pixel at (x, y) had anything drawn on it.  y counts up from
   the bottom, the way the layer geometry does. */
static BOOL painted(CGContextRef context, int x, int y)
{
  unsigned char *data = CGBitmapContextGetData(context);
  unsigned char *pixel;

  if (!data || x < 0 || y < 0 || x >= W || y >= H)
    return NO;
  pixel = data + ((H - 1 - y) * W + x) * 4;
  return pixel[0] || pixel[1] || pixel[2] || pixel[3];
}

static int paintedCount(CGContextRef context)
{
  int x, y, n = 0;

  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      if (painted(context, x, y))
        n++;
  return n;
}

/* The box of everything painted.  Answers NO where nothing was. */
static BOOL paintedBox(CGContextRef context, int *x0, int *y0,
                       int *x1, int *y1)
{
  int x, y;

  *x0 = W; *y0 = H; *x1 = -1; *y1 = -1;
  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      if (painted(context, x, y))
        {
          if (x < *x0) *x0 = x;
          if (y < *y0) *y0 = y;
          if (x > *x1) *x1 = x;
          if (y > *y1) *y1 = y;
        }
  return *x1 >= 0;
}

static CGColorRef opaque(CGFloat r, CGFloat g, CGFloat b)
{
  return CGColorCreateGenericRGB(r, g, b, 1.0);
}

/* Which byte of a pixel each colour lands in, since the two platforms order
   them differently. */
static int chR, chG, chB;

static int channelOf(CGFloat r, CGFloat g, CGFloat b)
{
  CGContextRef context = newContext();
  CGColorRef colour = CGColorCreateGenericRGB(r, g, b, 1.0);
  unsigned char *p;
  int i, found = 0;

  CGContextSetFillColorWithColor(context, colour);
  CGContextFillRect(context, CGRectMake(0, 0, 20, 20));
  p = (unsigned char *)CGBitmapContextGetData(context)
      + ((H - 1 - 10) * W + 10) * 4;

  /* Half strength, so the channel is the one byte near 128 rather than one
     of the several at 255. */
  for (i = 0; i < 4; i++)
    if (p[i] > 100 && p[i] < 160)
      found = i;

  CGColorRelease(colour);
  CGContextRelease(context);
  return found;
}

static void findTheChannels(void)
{
  chR = channelOf(0.5, 0, 0);
  chG = channelOf(0, 0.5, 0);
  chB = channelOf(0, 0, 0.5);
  PASS(chR != chG && chG != chB && chR != chB,
       "red, green and blue are each in a byte of their own");
}

static void channels(CGContextRef context, int x, int y,
                     int *r, int *g, int *b)
{
  unsigned char *data = CGBitmapContextGetData(context);
  unsigned char *p = data + ((H - 1 - y) * W + x) * 4;

  *r = p[chR];
  *g = p[chG];
  *b = p[chB];
}

static CGImageRef greenImage(int w, int h)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, w, h, 8, w * 4, space,
#if GNUSTEP
                                         kCGImageAlphaPremultipliedFirst);
#else
                                         kCGImageAlphaPremultipliedLast);
#endif
  CGColorRef green = opaque(0, 1, 0);
  CGImageRef image;

  CGColorSpaceRelease(space);
  memset(CGBitmapContextGetData(c), 0, w * h * 4);
  CGContextSetFillColorWithColor(c, green);
  CGContextFillRect(c, CGRectMake(0, 0, w, h));
  image = CGBitmapContextCreateImage(c);
  CGColorRelease(green);
  CGContextRelease(c);
  return image;
}

/* CoreFoundation is not linked here on GNUstep, so a CoreText object is
   released the way the framework releases one. */
static void releaseCoreTextObject(const void *object)
{
  if (object == NULL)
    return;
#if GNUSTEP
  [(id)object release];
#else
  CFRelease(object);
#endif
}

/* A build whose CoreText typesets no runs draws no glyphs at all, so there is
   nothing to check the drawing against. */
static BOOL textIsTypeset(void)
{
  CTFontRef font = CTFontCreateWithName((CFStringRef)@"Helvetica", 24, NULL);
  NSAttributedString *as;
  CTLineRef line;
  NSArray *runs;
  BOOL ok;

  if (font == NULL)
    return NO;

  as = [[NSAttributedString alloc]
         initWithString: @"H"
             attributes: [NSDictionary dictionaryWithObject: (id)font
                                       forKey: (id)kCTFontAttributeName]];
  line = CTLineCreateWithAttributedString((CFAttributedStringRef)as);
  runs = line ? (NSArray *)CTLineGetGlyphRuns(line) : nil;
  ok = (runs != nil && [runs count] > 0 && CTLineGetGlyphCount(line) > 0);

  releaseCoreTextObject(line);
  [as release];
  releaseCoreTextObject(font);
  return ok;
}

/* A build whose CoreText answers nothing for a truncated line cannot truncate
   at all, so there is nothing to check the drawing against. */
static BOOL lineCanBeTruncated(void)
{
  CTFontRef font = CTFontCreateWithName((CFStringRef)@"Helvetica", 24, NULL);
  NSDictionary *attributes;
  NSAttributedString *string, *ellipsis;
  CTLineRef line, token, cut;
  BOOL ok;

  if (font == NULL)
    return NO;

  attributes = [NSDictionary dictionaryWithObject: (id)font
                                           forKey: (id)kCTFontAttributeName];
  string = [[NSAttributedString alloc] initWithString: @"HHHHHHHH"
                                           attributes: attributes];
  ellipsis = [[NSAttributedString alloc] initWithString: @"…"
                                             attributes: attributes];
  line = CTLineCreateWithAttributedString((CFAttributedStringRef)string);
  token = CTLineCreateWithAttributedString((CFAttributedStringRef)ellipsis);
  cut = CTLineCreateTruncatedLine(line,
                                  CTLineGetTypographicBounds(line, NULL, NULL,
                                                             NULL) / 2.0,
                                  kCTLineTruncationEnd, token);
  ok = (cut != NULL && CTLineGetGlyphCount(cut) < CTLineGetGlyphCount(line));

  releaseCoreTextObject(cut);
  releaseCoreTextObject(token);
  releaseCoreTextObject(line);
  [string release];
  [ellipsis release];
  releaseCoreTextObject(font);
  return ok;
}

static CATextLayer *text(id string)
{
  CATextLayer *t = [CATextLayer layer];

  [t setBounds: CGRectMake(0, 0, LAYER_W, LAYER_H)];
  [t setString: string];
  return t;
}

static void aLineOfText(void)
{
  CGContextRef context = newContext();
  CGContextRef taller = newContext();
  CGContextRef none = newContext();
  CGContextRef empty = newContext();
  CATextLayer *tall = [CATextLayer layer];
  int x0, y0, x1, y1;
  int tx0, ty0, tx1, ty1;

  [text(@"Hg") renderInContext: context];
  PASS(paintedBox(context, &x0, &y0, &x1, &y1),
       "a text layer draws its string");
  PASS(x0 >= 0 && x1 < LAYER_W && y0 >= 0 && y1 < LAYER_H,
       "inside its own bounds");
  PASS(y1 > LAYER_H / 2,
       "in the top half of them, since the first line sits at the top");

  /* The same string in a taller layer moves up with the top of the bounds. */
  [tall setBounds: CGRectMake(0, 0, LAYER_W, 90)];
  [tall setString: @"Hg"];
  [tall renderInContext: taller];
  PASS(paintedBox(taller, &tx0, &ty0, &tx1, &ty1) && ty1 > y1 + 20,
       "and follows the top of the bounds when the layer grows");

  [text(nil) renderInContext: none];
  PASS(paintedCount(none) == 0, "with no string it draws nothing");

  [text(@"") renderInContext: empty];
  PASS(paintedCount(empty) == 0, "and an empty string draws nothing");

  CGContextRelease(context);
  CGContextRelease(taller);
  CGContextRelease(none);
  CGContextRelease(empty);
}

/* A string too wide for the layer is cut to it.  Apple leaves the line short
   of the right edge: the same string that runs to x 159 of 160 untruncated
   ends at 147 truncated at the end and at 135 truncated in the middle.  How
   much shorter the middle is comes out of where the glyphs fall, so only that
   each mode leaves the line short of the edge is asserted. */
static void truncation(void)
{
  CGContextRef plain = newContext();
  CGContextRef cut = newContext();
  CGContextRef middle = newContext();
  CATextLayer *a = text(@"HHHHHHHHHHHHHHHHHHHHHHHH");
  CATextLayer *b = text(@"HHHHHHHHHHHHHHHHHHHHHHHH");
  CATextLayer *c = text(@"HHHHHHHHHHHHHHHHHHHHHHHH");
  int ax0, ay0, ax1, ay1, bx0, by0, bx1, by1, cx0, cy0, cx1, cy1;

  [b setTruncationMode: kCATruncationEnd];
  [c setTruncationMode: kCATruncationMiddle];
  [a renderInContext: plain];
  [b renderInContext: cut];
  [c renderInContext: middle];

  paintedBox(plain, &ax0, &ay0, &ax1, &ay1);
  paintedBox(cut, &bx0, &by0, &bx1, &by1);
  paintedBox(middle, &cx0, &cy0, &cx1, &cy1);

  PASS(bx1 < ax1, "truncating at the end stops the line short of the edge");
  PASS(paintedCount(cut) < paintedCount(plain), "and draws fewer glyphs");
  PASS(bx0 == ax0, "while it starts where the whole string started");
  PASS(cx1 < ax1 && paintedCount(middle) < paintedCount(plain),
       "and truncating in the middle stops short of it too");

  CGContextRelease(plain);
  CGContextRelease(cut);
  CGContextRelease(middle);
}

static void theSizeOfIt(void)
{
  CGContextRef big = newContext();
  CGContextRef small = newContext();
  CGContextRef shortText = newContext();
  CGContextRef longText = newContext();
  CATextLayer *s = text(@"Hg");
  int sx0, sy0, sx1, sy1, lx0, ly0, lx1, ly1;

  [text(@"Hg") renderInContext: big];
  [s setFontSize: 12];
  [s renderInContext: small];
  PASS(paintedCount(big) > paintedCount(small),
       "a bigger font size covers more of the layer");

  [text(@"H") renderInContext: shortText];
  [text(@"HHHH") renderInContext: longText];
  paintedBox(shortText, &sx0, &sy0, &sx1, &sy1);
  paintedBox(longText, &lx0, &ly0, &lx1, &ly1);
  PASS(lx1 > sx1, "and a longer string reaches further across it");

  CGContextRelease(big);
  CGContextRelease(small);
  CGContextRelease(shortText);
  CGContextRelease(longText);
}

static void theColourOfIt(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGContextRef context = newContext();
  CATextLayer *t = text(@"Hg");
  int x, y, r, g, b;
  BOOL sawRed = NO;

  [t setForegroundColor: red];
  [t renderInContext: context];
  for (y = 0; y < H && !sawRed; y++)
    for (x = 0; x < W; x++)
      if (painted(context, x, y))
        {
          channels(context, x, y, &r, &g, &b);
          if (r > g && r > b)
            {
              sawRed = YES;
              break;
            }
        }
  PASS(sawRed, "the text is drawn in the layer's foreground colour");

  CGColorRelease(red);
  CGContextRelease(context);
}

/* Apple draws the string under the layer's contents. */
static void underTheContents(void)
{
  CGImageRef image = greenImage(LAYER_W, LAYER_H);
  CGContextRef context = newContext();
  CATextLayer *t = text(@"Hg");
  int x, y, r, g, b;
  BOOL sawText = NO;

  [t setContents: (id)image];
  [t setContentsGravity: kCAGravityResize];
  [t renderInContext: context];
  for (y = 0; y < LAYER_H && !sawText; y++)
    for (x = 0; x < LAYER_W; x++)
      {
        channels(context, x, y, &r, &g, &b);
        if (g < r || g < b)
          {
            sawText = YES;
            break;
          }
      }
  PASS(!sawText, "the contents are drawn over the string, hiding it");

  CGImageRelease(image);
  CGContextRelease(context);
}

static void alignment(void)
{
  CGContextRef left = newContext();
  CGContextRef right = newContext();
  CGContextRef centre = newContext();
  CGContextRef natural = newContext();
  CATextLayer *l = text(@"Hg");
  CATextLayer *r = text(@"Hg");
  CATextLayer *c = text(@"Hg");
  CATextLayer *n = text(@"Hg");
  int lx0, ly0, lx1, ly1, rx0, ry0, rx1, ry1;
  int cx0, cy0, cx1, cy1, nx0, ny0, nx1, ny1;

  [l setAlignmentMode: kCAAlignmentLeft];
  [r setAlignmentMode: kCAAlignmentRight];
  [c setAlignmentMode: kCAAlignmentCenter];
  [l renderInContext: left];
  [r renderInContext: right];
  [c renderInContext: centre];
  paintedBox(left, &lx0, &ly0, &lx1, &ly1);
  paintedBox(right, &rx0, &ry0, &rx1, &ry1);
  paintedBox(centre, &cx0, &cy0, &cx1, &cy1);

  PASS(lx0 < 10, "left alignment starts the line at the left edge");
  PASS(rx1 > 150, "right alignment ends it at the right edge");
  PASS(cx0 > lx0 && cx1 < rx1, "and center puts it between the two");

  /* natural is left for a single line of Latin text. */
  [n setAlignmentMode: kCAAlignmentNatural];
  [n renderInContext: natural];
  paintedBox(natural, &nx0, &ny0, &nx1, &ny1);
  PASS(nx0 == lx0 && nx1 == lx1, "natural alignment is the same as left");

  CGContextRelease(left);
  CGContextRelease(right);
  CGContextRelease(centre);
  CGContextRelease(natural);
}

/* This one needs no glyphs, so it runs whatever CoreText does. */
static void askingForADisplay(void)
{
  CATextLayer *t = text(@"Hg");

  [t display];
  PASS([t needsDisplay] == NO, "a layer that has just displayed is settled");
  [t setString: @"Other"];
  PASS([t needsDisplay], "changing the string asks for a display");

  [t display];
  [t setFontSize: 12];
  PASS([t needsDisplay], "and so does changing the font size");
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  findTheChannels();

  START_SET("what a text layer draws")

  if (!textIsTypeset())
    {
      SKIP("this build's CoreText typesets no runs")
    }

  aLineOfText();
  theSizeOfIt();
  theColourOfIt();
  underTheContents();
  alignment();

  END_SET("what a text layer draws")

  START_SET("truncating a string that does not fit")

  if (!textIsTypeset())
    {
      SKIP("this build's CoreText typesets no runs")
    }
  if (!lineCanBeTruncated())
    {
      SKIP("this build's CoreText answers no truncated line")
    }

  truncation();

  END_SET("truncating a string that does not fit")

  START_SET("asking for a display")

  askingForADisplay();

  END_SET("asking for a display")

  [pool release];
  return 0;
}
