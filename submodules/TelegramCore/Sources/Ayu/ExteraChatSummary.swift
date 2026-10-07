import Foundation
import SwiftSignalKit
import Postbox
#if canImport(FoundationModels)
import FoundationModels
#endif

// exteraGram «Коротко»: summarizes the latest messages of a chat with Apple Intelligence.
// Runs fully on device (Foundation Models, iOS 26+); nothing leaves the iPhone.
public enum ExteraChatSummary {
    public static var isAvailable: Bool {
        guard ExteraSettings.aiSummary else {
            return false
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    // Why the feature is off on this device, for the settings screen.
    public static var unavailableReason: String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            if case .available = availability {
                return nil
            }
            if case .unavailable(.deviceNotEligible) = availability {
                return "Нужен iPhone 15 Pro или новее"
            }
            if case .unavailable(.appleIntelligenceNotEnabled) = availability {
                return "Включите Apple Intelligence в настройках iPhone"
            }
            if case .unavailable(.modelNotReady) = availability {
                return "Модель ещё загружается"
            }
            return "Недоступно на этом iPhone"
        }
        #endif
        return "Нужна iOS 26"
    }

    public static func summarize(postbox: Postbox, accountPeerId: PeerId, peerId: PeerId, completion: @escaping (Result<String, Error>) -> Void) {
        let _ = (postbox.aroundMessageHistoryViewForLocation(.peer(peerId: peerId, threadId: nil), anchor: .upperBound, ignoreMessagesInTimestampRange: nil, ignoreMessageIds: Set(), count: 80, fixedCombinedReadStates: nil, topTaggedMessageIdNamespaces: Set(), tag: nil, appendMessagesFromTheSameGroup: false, namespaces: .not(Namespaces.Message.allNonRegular), orderStatistics: [])
        |> take(1)
        |> deliverOnMainQueue).startStandalone(next: { view, _, _ in
            let transcript = self.transcript(view.entries.map { $0.message }, accountPeerId: accountPeerId)
            guard !transcript.isEmpty else {
                completion(.failure(SummaryError.empty))
                return
            }
            self.run(transcript: transcript, completion: completion)
        })
    }

    enum SummaryError: LocalizedError {
        case empty
        case unavailable

        var errorDescription: String? {
            switch self {
            case .empty:
                return "В чате пока нечего пересказывать."
            case .unavailable:
                return ExteraChatSummary.unavailableReason ?? "Apple Intelligence недоступен."
            }
        }
    }

    // "Имя: текст" lines, newest last, trimmed to fit the on-device model's context window.
    private static func transcript(_ messages: [Message], accountPeerId: PeerId) -> String {
        var lines: [String] = []
        for message in messages {
            var text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                text = message.media.isEmpty ? "" : "[вложение]"
            }
            if text.isEmpty {
                continue
            }
            let author: String
            if message.author?.id == accountPeerId {
                author = "Я"
            } else if let peer = message.author {
                author = peer.debugDisplayTitle
            } else {
                author = "?"
            }
            lines.append("\(author): \(text.prefix(400))")
        }

        var result: [String] = []
        var length = 0
        for line in lines.reversed() {
            length += line.count
            if length > 3500 {
                break
            }
            result.insert(line, at: 0)
        }
        return result.joined(separator: "\n")
    }

    private static func run(transcript: String, completion: @escaping (Result<String, Error>) -> Void) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            Task {
                do {
                    let session = LanguageModelSession(instructions: "Ты помощник в мессенджере. Кратко перескажи переписку: 3–5 пунктов, каждый начинается с «• ». Отметь договорённости, вопросы и то, что ждут от «Я». Пиши на языке переписки, без вступлений.")
                    let response = try await session.respond(to: transcript)
                    let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async {
                        completion(.success(text))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            return
        }
        #endif
        completion(.failure(SummaryError.unavailable))
    }
}
