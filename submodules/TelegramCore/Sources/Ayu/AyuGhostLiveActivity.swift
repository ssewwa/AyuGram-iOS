import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
// Shared between the app (starts and ends the activity) and the widget extension (draws it).
@available(iOS 16.2, *)
public struct AyuGhostActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var since: Date

        public init(since: Date) {
            self.since = since
        }
    }

    public init() {
    }
}
#endif

// Live Activity on the Lock Screen and in the Dynamic Island while ghost mode is on.
public final class AyuGhostLiveActivity {
    public static var isEnabled: Bool {
        get { return UserDefaults.standard.object(forKey: "showGhostLiveActivity") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "showGhostLiveActivity")
            self.sync()
        }
    }

    // Starts or ends the activity to match the settings. Call from the main app only.
    public static func sync() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            let shouldShow = self.isEnabled && AyuSettings.isGhostModeActive
            let current = Activity<AyuGhostActivityAttributes>.activities
            if shouldShow {
                if current.isEmpty && ActivityAuthorizationInfo().areActivitiesEnabled {
                    let content = ActivityContent(state: AyuGhostActivityAttributes.ContentState(since: Date()), staleDate: nil)
                    let _ = try? Activity.request(attributes: AyuGhostActivityAttributes(), content: content, pushType: nil)
                }
            } else {
                for activity in current {
                    Task {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    }
                }
            }
        }
        #endif
    }
}
