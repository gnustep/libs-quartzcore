/* A minimal, self-contained reimplementation of the GNUstep test macros, used
   only when compiling the QuartzCore test suite against Apple's frameworks on
   macOS (the real Testing.h comes from gnustep-make and is not available
   there).  It emits the same "Passed test:" / "Failed test:" / "Dashed hope:"
   lines that gnustep-tests produces, so the same test files run in both
   environments. */
#ifndef Testing_h
#define Testing_h

#include <stdio.h>
#include <stdarg.h>

#ifndef YES
#define YES 1
#define NO  0
#endif

static int testHopeful __attribute__((unused)) = 0;
static int testPassed __attribute__((unused)) = 1;

static void testResult__(int passed, const char *fmt, ...)
  __attribute__((unused, format(printf, 2, 3)));
static void testResult__(int passed, const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  if (passed)
    {
      fputs("Passed test:     ", stderr);
      testPassed = 1;
    }
  else if (testHopeful)
    {
      fputs("Dashed hope:     ", stderr);
      testPassed = 0;
    }
  else
    {
      fputs("Failed test:     ", stderr);
      testPassed = 0;
    }
  vfprintf(stderr, fmt, ap);
  fputc('\n', stderr);
  va_end(ap);
}

#define PASS(expr__, fmt__, ...) \
  testResult__((expr__) ? 1 : 0, "%s:%d ... " fmt__, \
    __FILE__, __LINE__, ##__VA_ARGS__)

/* START_SET opens a scope and saves the hopeful flag, END_SET restores it,
   matching gnustep-tests (the exception handling it does is not needed for the
   pure-value tests that run on Apple). */
#define START_SET(name__) { \
  int _save_hopeful__ = testHopeful; \
  fprintf(stderr, "Start set: %s\n", (name__));

#define END_SET(name__) \
  fprintf(stderr, "End set: %s\n", (name__)); \
  testHopeful = _save_hopeful__; \
  }

#define SKIP(msg__) { fprintf(stderr, "Skipped test:    %s\n", (msg__)); }

/* PASS_RUNS passes when the code completes without raising; PASS_EXCEPTION
   passes when it raises, and when an expected name is given, only for that
   name.  Both report through testResult__, so a hopeful one dashes rather
   than fails, exactly as in gnustep-tests. */
#define PASS_RUNS(code__, fmt__, ...) \
  do { \
    int _ran__ = 1; \
    @try { code__; } \
    @catch (NSException *_e__) { \
      _ran__ = 0; \
      fprintf(stderr, "%s: %s\n", [[_e__ name] UTF8String], \
        [[_e__ reason] UTF8String]); \
    } \
    testResult__(_ran__, "%s:%d ... " fmt__, \
      __FILE__, __LINE__, ##__VA_ARGS__); \
  } while (0)

#define PASS_EXCEPTION(code__, expect__, fmt__, ...) \
  do { \
    int _matched__ = 0; \
    @try { code__; } \
    @catch (NSException *_e__) { \
      _matched__ = (nil == (expect__) || [[_e__ name] isEqual: (expect__)]); \
      if (!_matched__) \
        fprintf(stderr, "Expected '%s' and got '%s'\n", \
          [(expect__) UTF8String], [[_e__ name] UTF8String]); \
    } \
    testResult__(_matched__, "%s:%d ... " fmt__, \
      __FILE__, __LINE__, ##__VA_ARGS__); \
  } while (0)

#endif /* Testing_h */
