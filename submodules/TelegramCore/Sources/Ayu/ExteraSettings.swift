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

    // MARK: Customization

    private static func string(_ key: String, _ defaultValue: String) -> String {
        return self.defaults.string(forKey: "extera." + key) ?? defaultValue
    }

    // "text" (titleText), "name", "username" or "none"
    public static var titleMode: String {
        get { return self.string("titleMode", "text") }
        set { self.set(newValue, "titleMode") }
    }

    // Account name / username, cached for the chat list title.
    public static var cachedAccountName: String {
        get { return self.string("cachedAccountName", "") }
        set { self.defaults.set(newValue, forKey: "extera.cachedAccountName") }
    }

    public static var cachedAccountUsername: String {
        get { return self.string("cachedAccountUsername", "") }
        set { self.defaults.set(newValue, forKey: "extera.cachedAccountUsername") }
    }

    public static func chatListTitle(defaultTitle: String) -> String {
        switch self.titleMode {
        case "name":
            return self.cachedAccountName.isEmpty ? defaultTitle : self.cachedAccountName
        case "username":
            return self.cachedAccountUsername.isEmpty ? defaultTitle : "@" + self.cachedAccountUsername
        case "none":
            return " "
        default:
            return self.titleText.isEmpty ? defaultTitle : self.titleText
        }
    }

    public static var compactChatList: Bool {
        get { return self.bool("compactChatList", false) }
        set { self.set(newValue, "compactChatList") }
    }

    public static var hideStories: Bool {
        get { return self.bool("hideStories", false) }
        set { self.set(newValue, "hideStories") }
    }

    // "circle" or "rounded"
    public static var avatarShape: String {
        get { return self.string("avatarShape", "circle") }
        set { self.set(newValue, "avatarShape") }
    }

    public static var hideContactsTab: Bool {
        get { return self.bool("hideContactsTab", false) }
        set { self.set(newValue, "hideContactsTab") }
    }

    public static var hideCallsTab: Bool {
        get { return self.bool("hideCallsTab", false) }
        set { self.set(newValue, "hideCallsTab") }
    }

    public static var chatsTabFirst: Bool {
        get { return self.bool("chatsTabFirst", false) }
        set { self.set(newValue, "chatsTabFirst") }
    }

    // "default" or "none"
    public static var bubbleTail: String {
        get { return self.string("bubbleTail", "default") }
        set { self.set(newValue, "bubbleTail") }
    }

    public static var glassBubbles: Bool {
        get { return self.bool("glassBubbles", false) }
        set { self.set(newValue, "glassBubbles") }
    }

    // "compact", "default" or "airy"
    public static var chatDensity: String {
        get { return self.string("chatDensity", "default") }
        set { self.set(newValue, "chatDensity") }
    }

    public static var hideMessageTime: Bool {
        get { return self.bool("hideMessageTime", false) }
        set { self.set(newValue, "hideMessageTime") }
    }

    // Read by Display's Font at launch: "regular", "round", "serif" or "monospace"
    public static var fontDesign: String {
        get { return self.string("fontDesign", "regular") }
        set { self.set(newValue, "fontDesign") }
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
