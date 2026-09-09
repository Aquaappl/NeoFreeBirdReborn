// Uses the production snapshot and feature-switch functions, extracted by
// run_native_regressions.py. No host binaries or private user data are loaded.
static BHTLikedMediaItem* media(NSString* identifier, double ratio, BOOL decoded) {
    BHTLikedMediaItem* item = [BHTLikedMediaItem new];
    item.identifier = identifier;
    item.aspectRatio = ratio;
    item.aspectRatioConfirmedByImage = decoded;
    return item;
}

static void testProfileMediaAndGrok(void) {
    BHTLikedMediaItem* old = media(@"photo-a", 0.5, YES);
    BHTLikedMediaItem* refreshed = media(@"photo-a", 1.0, NO);
    BHTLikedMediaItem* added = media(@"photo-b", 1.8, NO);
    NSArray* page = BHTProfileMediaSnapshot(@[refreshed, added], @[old]);
    NSCAssert(page.count == 2 && page[0] == refreshed && page[1] == added,
              @"Pagination preserves the current native ordering and metadata objects");
    NSCAssert(refreshed.aspectRatio == 0.5 && refreshed.aspectRatioConfirmedByImage,
              @"A refreshed snapshot must not turn an already decoded portrait square");
    NSCAssert(added.aspectRatio == 1.8, @"New media uses its own dimensions");
    NSCAssert([BHTProfileMediaSnapshot(@[added], page) isEqualToArray:@[added]],
              @"Deleted photos must not reappear from an old cached snapshot");
    NSCAssert(BHTProfileMediaSnapshot(@[], page).count == 0,
              @"Native empty or denied-access states clear the gallery");
    NSCAssert(BHTProfileMediaSnapshot(nil, page).count == 0, @"Nil snapshots clear safely");
    BHTLikedMediaItem* otherProfile = media(@"photo-c", 2.0, NO);
    NSArray* isolated = BHTProfileMediaSnapshot(@[otherProfile], page);
    NSCAssert(isolated.count == 1 && isolated.firstObject == otherProfile,
              @"An unrelated profile snapshot cannot inherit old images");
    BHTLikedMediaItem* video = media(@"video-a", 1.7, NO);
    NSCAssert(BHTProfileMediaSnapshot(@[video], @[]).firstObject == video,
              @"Photo and video instances keep separate snapshots");

    NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
    id previous = [defaults objectForKey:@"hide_grok_sidebar"];
    [defaults setBool:YES forKey:@"hide_grok_sidebar"];
    NSCAssert([FeatureSwitchOverrideValueForKey(@"grok_ios_grok_bot_sidebar_enabled") isEqual:@NO],
              @"The current GrokBotSidebarUpsell initializer must receive false");
    NSCAssert(FeatureSwitchOverrideValueForKey(@"grok_ios_grok_bot_upsells_enabled") == nil,
              @"The sidebar choice must not disable every Grok feature");
    [defaults setBool:NO forKey:@"hide_grok_sidebar"];
    NSCAssert(FeatureSwitchOverrideValueForKey(@"grok_ios_grok_bot_sidebar_enabled") == nil,
              @"Showing the promotion restores the native account gate, without forcing it on");
    if (previous) [defaults setObject:previous forKey:@"hide_grok_sidebar"];
    else [defaults removeObjectForKey:@"hide_grok_sidebar"];
    NSLog(@"PASS: profile snapshot replacement, cleared access states, dimensions, isolation, and Grok promotion gate");
}
