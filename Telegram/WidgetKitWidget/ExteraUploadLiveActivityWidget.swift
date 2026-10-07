#if arch(arm64) || arch(x86_64)

import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif
import TelegramCore

#if canImport(ActivityKit)
private let exteraRed = Color(red: 0.91, green: 0.19, blue: 0.19)

private func uploadTitle(_ state: ExteraUploadActivityAttributes.ContentState) -> String {
    if state.finished {
        return "Отправлено"
    }
    return state.count > 1 ? "Отправка · \(state.count)" : "Отправка"
}

private struct UploadRing: View {
    let state: ExteraUploadActivityAttributes.ContentState
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.2), lineWidth: size * 0.14)
            Circle()
                .trim(from: 0.0, to: CGFloat(state.progress))
                .stroke(state.finished ? Color.green : exteraRed, style: StrokeStyle(lineWidth: size * 0.14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: state.finished ? "checkmark" : "arrow.up")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundColor(state.finished ? .green : .white)
        }
        .frame(width: size, height: size)
    }
}

// exteraGram: outgoing media progress on the Lock Screen and in the Dynamic Island.
@available(iOSApplicationExtension 16.2, iOS 16.2, *)
struct ExteraUploadLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExteraUploadActivityAttributes.self) { context in
            HStack(spacing: 14.0) {
                UploadRing(state: context.state, size: 40.0)
                VStack(alignment: .leading, spacing: 6.0) {
                    Text(uploadTitle(context.state))
                        .font(.headline)
                        .foregroundColor(.white)
                    ProgressView(value: context.state.progress)
                        .tint(context.state.finished ? .green : exteraRed)
                }
                Text("\(Int(context.state.progress * 100))%")
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundColor(.white)
            }
            .padding(16.0)
            .activityBackgroundTint(Color.black.opacity(0.75))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    UploadRing(state: context.state, size: 36.0)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(uploadTitle(context.state))
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.headline.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(context.state.finished ? .green : exteraRed)
                }
            } compactLeading: {
                Image(systemName: context.state.finished ? "checkmark" : "arrow.up")
                    .foregroundColor(context.state.finished ? .green : exteraRed)
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption2.monospacedDigit())
            } minimal: {
                UploadRing(state: context.state, size: 22.0)
            }
            .keylineTint(exteraRed)
        }
    }
}
#endif

#endif
