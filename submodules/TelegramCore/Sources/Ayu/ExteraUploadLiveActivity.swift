import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
// Shared between the app (starts, updates and ends the activity) and the widget extension (draws it).
@available(iOS 16.2, *)
public struct ExteraUploadActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var count: Int
        public var progress: Double
        public var finished: Bool

        public init(count: Int, progress: Double, finished: Bool) {
            self.count = count
            self.progress = progress
            self.finished = finished
        }
    }

    public init() {
    }
}
#endif

// exteraGram: progress of outgoing media in the Dynamic Island and on the Lock Screen.
public final class ExteraUploadLiveActivity {
    public static var isEnabled: Bool {
        get { return UserDefaults.standard.object(forKey: "extera.uploadLiveActivity") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera.uploadLiveActivity") }
    }

    private static var firstSeen: Date?
    private static var lastSent: (date: Date, progress: Double)?
    private static var maxCount = 0

    // Called on the main queue with the progress of every media upload in flight (0...1).
    public static func update(progresses: [Float]) {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            let current = Activity<ExteraUploadActivityAttributes>.activities

            if progresses.isEmpty || !self.isEnabled {
                if !current.isEmpty {
                    let done = ExteraUploadActivityAttributes.ContentState(count: self.maxCount, progress: 1.0, finished: true)
                    for activity in current {
                        Task {
                            await activity.end(ActivityContent(state: done, staleDate: nil), dismissalPolicy: .after(Date().addingTimeInterval(3.0)))
                        }
                    }
                }
                self.firstSeen = nil
                self.lastSent = nil
                self.maxCount = 0
                return
            }

            let now = Date()
            let progress = Double(progresses.reduce(0, +)) / Double(progresses.count)
            self.maxCount = max(self.maxCount, progresses.count)
            let state = ExteraUploadActivityAttributes.ContentState(count: progresses.count, progress: progress, finished: false)

            if current.isEmpty {
                // Small photos are sent instantly; only show uploads that take a while.
                if self.firstSeen == nil {
                    self.firstSeen = now
                }
                guard let firstSeen = self.firstSeen, now.timeIntervalSince(firstSeen) > 1.5, ActivityAuthorizationInfo().areActivitiesEnabled else {
                    return
                }
                let _ = try? Activity.request(attributes: ExteraUploadActivityAttributes(), content: ActivityContent(state: state, staleDate: nil), pushType: nil)
                self.lastSent = (now, progress)
                return
            }

            // Updates are rate-limited by iOS: send at most twice a second or on a visible change.
            if let lastSent = self.lastSent, now.timeIntervalSince(lastSent.date) < 0.5 && abs(progress - lastSent.progress) < 0.05 {
                return
            }
            self.lastSent = (now, progress)
            for activity in current {
                Task {
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                }
            }
        }
        #endif
    }
}
