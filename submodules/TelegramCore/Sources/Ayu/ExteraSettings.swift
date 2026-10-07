import Foundation
import Postbox

// exteraGram customization settings. Keys match ExteraConfig in exteraGram for Android.
public final class ExteraSettings {
    private static var defaults: UserDefaults {
        return UserDefaults.standard
    }

    private static func bool(_ key: String, _ defaultValue: Bool) -> Bool {
        return self.defaults.object(forKey: "extera." + key) as? Bool ?? defaultValue
    }

    private static func set(_ value: Any?, _ key: String) {
        self.defaults.set(value, forKey: "extera." + key)
        NotificationCenter.default.post(name: AyuSettings.didChangeNotification, object: nil)
    }

    // MARK: Appearance

    // Custom title above the chat list; empty means the default one.
    public static var titleText: String {
        get { return self.defaults.string(forKey: "extera.titleText") ?? "" }
        set { self.set(newValue, "titleText") }
    }

    public static var formatTimeWithSeconds: Bool {
        get { return self.bool("formatTimeWithSeconds", false) }
        set { self.set(newValue, "formatTimeWithSeconds") }
    }

    public static var disableNumberRounding: Bool {
        get { return self.bool("disableNumberRounding", false) }
        set { self.set(newValue, "disableNumberRounding") }
    }

    // MARK: Profile & privacy

    public static var hidePhoneNumber: Bool {
        get { return self.bool("hidePhoneNumber", false) }
        set { self.set(newValue, "hidePhoneNumber") }
    }

    public static var showIdAndDc: Bool {
        get { return self.bool("showIdAndDc", false) }
        set { self.set(newValue, "showIdAndDc") }
    }

    // MARK: Screen privacy (iOS only)

    public static var hideOnScreenCapture: Bool {
        get { return self.bool("hideOnScreenCapture", true) }
        set { self.set(newValue, "hideOnScreenCapture") }
    }

    public static var hideInAppSwitcher: Bool {
        get { return self.bool("hideInAppSwitcher", false) }
        set { self.set(newValue, "hideInAppSwitcher") }
    }

    // MARK: Voice messages (iOS only)

    // Free on-device transcription with Apple's Speech framework instead of Telegram Premium's server one.
    public static var localVoiceTranscription: Bool {
        get { return self.bool("localVoiceTranscription", true) }
        set { self.set(newValue, "localVoiceTranscription") }
    }

    // MARK: Apple Intelligence (iOS only)

    // "Коротко": on-device chat summary with Apple's Foundation Models.
    public static var aiSummary: Bool {
        get { return self.bool("aiSummary", true) }
        set { self.set(newValue, "aiSummary") }
    }
}

// Peer id the way bots and other clients show it: users as is, basic groups with "-", channels with "-100".
public func exteraBotApiPeerId(_ peerId: PeerId) -> String {
    let rawId = peerId.id._internalGetInt64Value()
    switch peerId.namespace {
    case Namespaces.Peer.CloudChannel:
        return "-100\(rawId)"
    case Namespaces.Peer.CloudGroup:
        return "-\(rawId)"
    default:
        return "\(rawId)"
    }
}
