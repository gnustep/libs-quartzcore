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

#endif /* Testing_h */
