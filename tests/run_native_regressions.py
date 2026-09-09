"""Compile production Objective-C helpers with native Foundation on macOS."""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def section(source, start, end):
    return source[source.index(start):source.index(end, source.index(start))]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--emit-only", type=Path)
    args = parser.parse_args()
    source = (ROOT / "src/Hooks/Timeline.x").read_text(encoding="utf8")
    unit = '''#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <string.h>
#import "Timeline/BHTForYouKeywordFilter.h"
#import "Likes/BHTLikesNavigationUtility.h"
#import "Compatibility/BHTCompatibilityReporter.h"
NSString* const BHTSettingsProfileDidApplyNotification = @"TestProfileChanged";
NSString* const TabPageKey = @"page";
NSString* const TabTitleKey = @"title";
NSString* const TabImageKey = @"image";
static char kBHTForYouKeywordDecisionKey;
static id unwrapDataViewItem(id item) { return item; }
void BHTRecordForYouFilterDiagnostic(BHTForYouFilterDiagnosticEvent event) {}
'''
    unit += section(source, "@interface BHTForYouKeywordDecisionCache", "static NSMutableArray<BHTHomeTimelineRegistryEntry*>")
    unit += section(source, "static const char* SkipObjCTypeQualifiers", "static UIViewController* NearestURTTimelineController")
    unit += section(source, "static BOOL BHTIsKeywordStatusViewModel", "static BOOL BHTShouldHideForYouKeywordItemInURTController")
    unit += (ROOT / "tests/TimelineKeywordTests.m").read_text(encoding="utf8")
    if args.emit_only:
        args.emit_only.write_text(unit, encoding="utf8")
        return
    with tempfile.TemporaryDirectory(prefix="nfb-native-tests-") as directory:
        base = Path(directory)
        test_source = base / "tests.m"
        test_source.write_text(unit, encoding="utf8")
        binary = base / "native-tests"
        subprocess.run(["xcrun", "clang", "-fobjc-arc", "-fblocks", "-Werror=implicit-function-declaration",
                        "-framework", "Foundation", "-I", str(ROOT / "src"), str(test_source),
                        str(ROOT / "src/Timeline/BHTForYouKeywordFilter.m"),
                        str(ROOT / "src/Likes/BHTLikesNavigationUtility.m"),
                        str(ROOT / "src/Core/BHTBundle.m"), "-o", str(binary)], check=True)
        subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    main()
