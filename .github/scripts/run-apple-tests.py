#!/usr/bin/env python3

import pathlib
import subprocess
import sys
import tempfile

"""
Compiles and runs the QuartzCore test suite against Apple's QuartzCore instead
of the GNUstep implementation, so the expected values encoded in the tests are
checked against the reference framework.

1. Discovers all the test files under Tests/quartzcore
2. Iterate each test suite: files named in the `APPLE_SKIP_TESTS` environment
   variable (set in a suite's TestInfo) are skipped
3. Compile each test with Apple's Objective-C toolchain and run it
4. Aggregate the results, log to stdout and a separate log file
"""

script_dir = pathlib.Path(__file__).resolve().parent
repo = script_dir.parents[1]
test_root = repo / "Tests" / "quartzcore"
# A self-contained Testing.h so the gnustep-tests test files compile on macOS.
apple_include = repo / ".github" / "apple"
log_file = test_root / "apple-tests.log"
totals = {"passed": 0, "failed": 0, "hoped": 0, "failed_files": 0, "skipped": 0}


def die(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(2)


def sdkroot():
    return subprocess.check_output(
        ["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True
    ).strip()


def log(message=""):
    print(message)
    with log_file.open("a") as f:
        f.write(f"{message}\n")


def get_skipped_test_files(test_dir):
    test_info = test_dir / "TestInfo"
    if not test_info.exists():
        return set()
    result = subprocess.run(
        ["/bin/sh", "-c", '. "$1"; printf "%s\\n" "${APPLE_SKIP_TESTS-}"', "sh", str(test_info)],
        cwd=test_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        die(f"failed to read {test_info}:\n{result.stderr}")
    return set(result.stdout.split())


def count(lines, prefix):
    return sum(1 for line in lines if line.startswith(prefix))


def compile_test(src, binary, output, sdk):
    command = [
        "xcrun", "--sdk", "macosx", "clang",
        "-isysroot", sdk,
        "-I", str(apple_include),
        "-Wno-deprecated-declarations",
        "-framework", "QuartzCore",
        "-framework", "CoreGraphics",
        "-framework", "Foundation",
        "-fno-objc-arc",
        "-o", str(binary),
        str(src),
    ]
    with output.open("w") as f:
        return subprocess.run(command, stdout=f, stderr=subprocess.STDOUT).returncode


def run_test_binary(binary, output):
    with output.open("w") as f:
        try:
            subprocess.run([str(binary)], stdout=f, stderr=subprocess.STDOUT, timeout=15)
            return None
        except subprocess.TimeoutExpired:
            return "timeout"


def run_test(test_dir, src, work_dir, sdk):
    name = src.name
    base = src.stem
    output = work_dir / f"{base}.out"
    binary = work_dir / f"{base}.bin"

    if name in get_skipped_test_files(test_dir):
        line = f"Skipped file:    {name}"
        log(line)
        totals["skipped"] += 1
        return

    log(f"Testing {name}...")

    if compile_test(src, binary, output, sdk) != 0:
        line = f"Failed file:  {name} failed to compile!"
        print(line)
        with log_file.open("a") as log_out:
            log_out.write(f"{line}\n{output.read_text()}")
        totals["failed_files"] += 1
        return

    status = run_test_binary(binary, output)
    lines = output.read_text().splitlines()
    with log_file.open("a") as f:
        f.write(output.read_text())

    totals["passed"] += count(lines, "Passed test:")
    totals["failed"] += count(lines, "Failed test:")
    totals["hoped"] += count(lines, "Dashed hope:")

    if status == "timeout":
        line = f"Failed file:  {name} timed out!"
        print(line)
        with log_file.open("a") as log_out:
            log_out.write(f"{line}\n")
        totals["failed_files"] += 1


def run_dir(test_dir, work_dir, sdk):
    if not (test_dir / "TestInfo").exists():
        return
    rel = test_dir.relative_to(repo)
    log(f"--- Running tests in {rel} ---")
    for src in sorted(test_dir.iterdir()):
        if src.suffix in {".m", ".c"} and src.is_file():
            run_test(test_dir, src, work_dir, sdk)


def run_target(arg, work_dir, sdk):
    path = pathlib.Path(arg)
    if not path.is_absolute():
        path = repo / path
    if path.is_file():
        if not (path.parent / "TestInfo").exists():
            die(f"no TestInfo found for {arg}")
        run_test(path.parent, path, work_dir, sdk)
        return
    if not path.is_dir():
        die(f"path not found: {arg}")
    dirs = {src.parent for src in path.rglob("*") if src.suffix in {".m", ".c"}}
    for test_dir in sorted(dirs):
        run_dir(test_dir, work_dir, sdk)


def print_failures():
    lines = log_file.read_text().splitlines()
    if not any(line.startswith(("Failed test:", "Failed file:")) for line in lines):
        return
    print("\nFailure summary:")
    for line in lines:
        if line.startswith(("Failed test:", "Failed file:")):
            print(line)
    print("\n::group::Full Apple test log")
    print(log_file.read_text(), end="")
    print("::endgroup::")


def main():
    log_file.write_text("")
    sdk = sdkroot()
    with tempfile.TemporaryDirectory(prefix="quartzcore-apple-tests.") as tmp:
        work_dir = pathlib.Path(tmp)
        targets = sys.argv[1:] or [str(test_root)]
        for target in targets:
            run_target(target, work_dir, sdk)

    print(f"\n{totals['passed']:7d} Passed tests")
    print(f"{totals['failed']:7d} Failed tests")
    print(f"{totals['hoped']:7d} Dashed hopes")
    print(f"{totals['failed_files']:7d} Failed files")
    print(f"{totals['skipped']:7d} Skipped files")

    if totals["failed"] or totals["failed_files"]:
        print_failures()
        sys.exit(1)


if __name__ == "__main__":
    main()
