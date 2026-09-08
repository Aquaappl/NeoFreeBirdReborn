# X 12.24.1 compatibility update — beta 51

Target: `com.atebits.Tweetie2`, X **12.24.1 build 1**, arm64, minimum iOS 15.0.
The supplied IPA contains 61 Mach-O images; all inspected encryption flags are
zero. Input SHA-256:
`d720024ea8d9125f1554727875f7d90b211d1800108be8a1bb59c0eb67dc6ceb`.

## Hook inventory

The [machine-readable audit](X12_24_1_HOOK_AUDIT.json) records every Logos
method's source signature, native encoding, implementation address, and owning
class where available. It also inventories compatibility-report probes and
the exported Swift sidebar setters. A missing alternative diagnostic probe
does not mean the active feature's implementation is missing.

| Classification | Methods | Meaning |
| --- | ---: | --- |
| Native method found | 201 | Present on the hooked class, a parent, or an app-supplied category |
| System runtime | 58 | UIKit/Foundation and other system implementations are outside the IPA; validate at runtime |
| Tweak additions | 9 | `%new` methods supplied by the tweak |
| Guarded legacy alias | 5 | Old Home class alias absent; its constructor checks prevent registration. The current mangled Home class is present |

No remaining unguarded Logos hook references a missing app class or method.
Presence and matching metadata do **not** establish device behavior or server
acceptance. Dynamic theme-provider replacements continue checking the active
provider and method shapes at runtime.

Changes from the previous target:

- Retired six hooks on removed classes: the slideshow ad gate, slideshow heart,
  two slideshow quality actions, duplicate immersive V2 gesture hook, and old
  settings controller. Existing current immersive, media-quality, ad-filtering,
  and generic-settings paths remain.
- Updated the DM attachment class from `DMConversation.MessageAttachmentView`
  to `ChatConversation.MessageAttachmentView`; `layoutSubviews` is present.
- Retargeted guarded sign-in, reply, and diagnostic version checks to 12.24.1.
  Their method/layout checks remain active. Native account and posting flows
  remain the defaults.
- Updated the native Bookmarks carrier used for Likes to the current panel
  factory at `T1Twitter+0x69B0C4`, jump table `+0x1403730`, panel-6 case
  `+0x69B1E0`. UUID `B7626D78-E963-30FF-A7E1-C1281BC7298D` is checked before
  any offset is read, followed by the prologue, dispatch, and case signatures.
  An unknown binary returns no carrier instead of calling an old address.

## Likes layout

`TFSTwitterEntityMedia` exposes `mediaDimensions`/`imageDimensions` as CGSize;
the former width/height lookups did not obtain these dimensions. Tiles now use
this metadata immediately, with video numerator/denominator as a fallback.
Decoded images can still correct incomplete metadata.

Corrections coalesce on a one-shot display link in common run-loop modes,
including active scrolling. UIKit's invalidation-context offset adjustment
anchors the visible item without calling `setContentOffset:` during the
correction. Prepared geometry is reused until it changes. Prefetches and
visible cells use the same pixel-bucket calculation so they can share work.
The display-link target captures the controller weakly.

The scheduling and offset APIs follow Apple's
[CADisplayLink documentation](https://developer.apple.com/documentation/quartzcore/cadisplaylink)
and [layout invalidation context documentation](https://developer.apple.com/documentation/uikit/uicollectionviewlayoutinvalidationcontext).

## Sidebar persistence

Taps and reorders save immediately; leaving through Back no longer discards
the selection. The editor uses Done. Empty selection remains a valid saved
value rather than reverting to defaults.

The runtime observes the source's `ObservableObject` changes and reapplies the
saved selection after a native publication commits. It coalesces updates and
ignores publications from its own setters. Cached hidden rows are refreshed
when X supplies newer rows, preserving current badges and action values when
unhidden. Duplicate/unknown saved IDs are sanitized before ranking. Known icon
names supplement English titles when identifying localized primary rows;
unknown X-owned rows are preserved.

All three native array setters remain exported from XAppLibraries:
`primaryItems` at `0x2CF872C`, `folderItems` at `0x2CF8A7C`, and `tertiaryItems`
at `0x2CF8DCC`. Runtime calls continue resolving their names with `dlsym`;
these addresses are audit evidence, not additional hard-coded calls.

## Validation and package

- Source invariant check: passed, 80 settings and 25 localized subsections.
- Branding regression tests: passed on the macOS runner.
- Sidebar executable tests: passed for native republication, localization,
  duplicate preferences, hide-all, restoration of current row values, and
  observer idempotence.
- arm64 sideload build: [successful run](https://github.com/Vicitiniman/NeoFreeBirdReborn/actions/runs/34254641491),
  compiled source commit `244de80`.
- The local packager checks the input IPA's audit hash, required hook exports,
  Mach-O layouts, unchanged executable instruction sections, archive CRCs,
  duplicate entries, and settings resources. It retains the host signature blob
  for entitlement extraction by the user's signer; signing hashes must be
  regenerated during sideloading.

The output IPA is unsigned and requires the user's usual sideload signer.
No device execution has been performed. The remaining acceptance pass is:
open the app and settings; scroll Likes continuously with portrait/landscape
media and pinch the grid; hide Lists/News, leave via Back, reopen the drawer,
switch accounts, and relaunch; then exercise media viewing/downloads, native
sign-in/replies, and themes on the device. Network-backed features still depend
on the host app and X's services.

Reproduce the inventory with Python 3.11+ and `lief` installed:

```sh
python tools/audit_ipa_hooks.py /path/to/input.ipa --output docs/X12_24_1_HOOK_AUDIT.json
```

For local packaging, install `lief` and Pillow, download the **sideload-payload**
Actions artifact, and supply an authorized arm64 substrate-compatible runtime:

```sh
python tools/package_local_ipa.py /path/to/input.ipa /path/to/NeoFreeBird-sideload-payload.zip --substrate /path/to/libsubstrate.dylib --output /path/to/NeoFreeBird.ipa
```

The original 12.9 investigation is retained in
[X12_9_FEATURE_AUDIT.md](X12_9_FEATURE_AUDIT.md) as historical reference.
