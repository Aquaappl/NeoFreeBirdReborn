#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, BHTTimelineCleanupKind) {
    BHTTimelineCleanupKindNone = 0,
    BHTTimelineCleanupKindWhoToFollow = 1 << 0,
    BHTTimelineCleanupKindPrompt = 1 << 1,
    BHTTimelineCleanupKindDiscoverMore = 1 << 2,
    BHTTimelineCleanupKindTopicPost = 1 << 3,
    BHTTimelineCleanupKindTopicSuggestion = 1 << 4,
};

// Classifies X's stable URT identifiers. This is intentionally separate from
// visible labels so localization and wording changes cannot bypass cleanup.
FOUNDATION_EXPORT BHTTimelineCleanupKind
BHTTimelineCleanupKindsForIdentifiers(nullable NSString* className,
                                      nullable NSString* scribeComponent,
                                      nullable NSString* entryID);

// Classifies a live timeline item, including topic metadata stored on the
// underlying TFNTwitterStatus in current X builds.
FOUNDATION_EXPORT BHTTimelineCleanupKind
BHTTimelineCleanupKindsForItem(nullable id item);

FOUNDATION_EXPORT BHTTimelineCleanupKind
BHTEnabledTimelineCleanupKinds(void);

FOUNDATION_EXPORT BOOL BHTShouldHideTimelineCleanupItemForKinds(
    nullable id item, BHTTimelineCleanupKind enabledKinds);
FOUNDATION_EXPORT BOOL
BHTShouldHideTimelineCleanupItem(nullable id item);

NS_ASSUME_NONNULL_END
