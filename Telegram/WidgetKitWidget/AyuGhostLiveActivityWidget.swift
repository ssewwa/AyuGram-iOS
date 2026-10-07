#if arch(arm64) || arch(x86_64)

import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif
import TelegramCore

#if canImport(ActivityKit)
// AyuGram: ghost mode indicator on the Lock Screen and in the Dynamic Island.
@available(iOSApplicationExtension 16.2, iOS 16.2, *)
struct AyuGhostLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AyuGhostActivityAttributes.self) { context in
            HStack(spacing: 12.0) {
                Text("👻")
                    .font(.system(size: 30.0))
                VStack(alignment: .leading, spacing: 2.0) {
                    Text("Режим призрака")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("«Прочитано», «в сети» и «печатает» не отправляются")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(2)
                }
                Spacer(minLength: 8.0)
                Text(context.state.since, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56.0)
            }
            .padding(16.0)
            .activityBackgroundTint(Color.black.opacity(0.75))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("👻")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Режим призрака")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.since, style: .timer)
                        .font(.caption.monospacedDigit())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 56.0)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("«Прочитано», «в сети» и «печатает» не отправляются")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } compactLeading: {
                Text("👻")
            } compactTrailing: {
                Text("Призрак")
                    .font(.caption2)
            } minimal: {
                Text("👻")
            }
            .keylineTint(Color(red: 0.91, green: 0.19, blue: 0.19))
        }
    }
}
#endif

#endif
