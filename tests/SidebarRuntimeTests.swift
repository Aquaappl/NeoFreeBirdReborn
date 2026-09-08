import Foundation
import Combine

@_cdecl("BHTInvokeTwitterDashArraySetter")
func unusedNativeSetter(_ array: UInt, _ object: UnsafeMutableRawPointer,
                        _ setter: UnsafeMutableRawPointer) {
    fatalError("Tests must use the typed fixture setter")
}

private struct Row {
    let title: String
    let iconName: String
    let revision: Int
}

private final class Source: ObservableObject {
    @Published var primaryItems: [Row] = []
    @Published var folderItems: [Row] = []
    @Published var tertiaryItems: [Row] = []
}

private final class Controller: NSObject {
    let dataSource = Source()
}

@main
struct SidebarRuntimeTests {
    static func main() {
        let key = "bht_sidebar_navigation_visible"
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: key)
        defer {
            if let previous { defaults.set(previous, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        let controller = Controller()
        let source = controller.dataSource
        var writes = 0
        BHTSidebarRuntime.testSetter = { property, value, object in
            guard let source = object as? Source, let rows = value as? [Row] else { return false }
            writes += 1
            switch property {
            case "primaryItems": source.primaryItems = rows
            case "folderItems": source.folderItems = rows
            case "tertiaryItems": source.tertiaryItems = rows
            default: return false
            }
            return true
        }
        func rows(_ revision: Int) -> [Row] {
            [Row(title: "Profil", iconName: "account_stroke", revision: revision),
             Row(title: "Listes", iconName: "lists_stroke", revision: revision),
             Row(title: "Actualités", iconName: "news_stroke", revision: revision),
             Row(title: "Future X feature", iconName: "unknown_icon", revision: revision)]
        }
        func drain() { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
        defaults.set(["profile", "profile", "invalid"], forKey: key)
        source.primaryItems = rows(0)
        precondition(BHTSidebarRuntime.applyResult(forDashContentController: controller) == 3)
        precondition(source.primaryItems.map(\.title) == ["Profil", "Future X feature"])
        let initialWrites = writes
        precondition(BHTSidebarRuntime.applyResult(forDashContentController: controller) == 1)
        drain()
        precondition(writes == initialWrites, "Idempotent apply must not republish")
        for revision in 1...5 {
            source.primaryItems = rows(revision)
            drain()
            precondition(source.primaryItems.map(\.title) == ["Profil", "Future X feature"])
            precondition(source.primaryItems.allSatisfy { $0.revision == revision })
        }
        precondition(writes == initialWrites + 5, "Each native refresh should trigger one rewrite")
        defaults.set([String](), forKey: key)
        _ = BHTSidebarRuntime.applyResult(forDashContentController: controller)
        precondition(source.primaryItems.map(\.title) == ["Future X feature"])
        defaults.set(["news", "lists", "profile"], forKey: key)
        _ = BHTSidebarRuntime.applyResult(forDashContentController: controller)
        precondition(source.primaryItems.map(\.title) == ["Actualités", "Listes", "Profil", "Future X feature"])
        precondition(source.primaryItems.allSatisfy { $0.revision == 5 }, "Unhiding must restore the latest native values")
        drain()
        let settledWrites = writes
        drain()
        precondition(writes == settledWrites, "The observer must not feed back into itself")
        print("PASS: sidebar refresh, localization, duplicate preferences, hide-all, restore, and observer idempotence")
    }
}
