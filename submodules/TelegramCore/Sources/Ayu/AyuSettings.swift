import Foundation

// AyuGram settings. Keys and defaults match AyuGram for Android (AyuConfig).
public final class AyuSettings {
    public static let didChangeNotification = Notification.Name("AyuSettingsDidChange")
    public static let defaultDeletedMark = "🧹"

    private static var defaults: UserDefaults {
        return UserDefaults.standard
    }

    private static func bool(_ key: String, _ defaultValue: Bool) -> Bool {
        return self.defaults.object(forKey: key) as? Bool ?? defaultValue
    }

    private static func set(_ value: Bool, _ key: String) {
        self.defaults.set(value, forKey: key)
        NotificationCenter.default.post(name: AyuSettings.didChangeNotification, object: nil)
    }

    // MARK: Ghost essentials

    public static var sendReadPackets: Bool {
        get { return self.bool("sendReadPackets", true) }
        set { self.set(newValue, "sendReadPackets") }
    }

    public static var sendOnlinePackets: Bool {
        get { return self.bool("sendOnlinePackets", true) }
        set { self.set(newValue, "sendOnlinePackets") }
    }

    public static var sendUploadProgress: Bool {
        get { return self.bool("sendUploadProgress", true) }
        set { self.set(newValue, "sendUploadProgress") }
    }

    public static var sendOfflinePacketAfterOnline: Bool {
        get { return self.bool("sendOfflinePacketAfterOnline", false) }
        set { self.set(newValue, "sendOfflinePacketAfterOnline") }
    }

    public static var markReadAfterSend: Bool {
        get { return self.bool("markReadAfterSend", true) }
        set { self.set(newValue, "markReadAfterSend") }
    }

    // MARK: Message history

    public static var saveDeletedMessages: Bool {
        get { return self.bool("saveDeletedMessages", true) }
        set { self.set(newValue, "saveDeletedMessages") }
    }

    public static var deletedMark: String {
        get { return self.defaults.string(forKey: "deletedMarkText") ?? AyuSettings.defaultDeletedMark }
        set {
            self.defaults.set(newValue, forKey: "deletedMarkText")
            NotificationCenter.default.post(name: AyuSettings.didChangeNotification, object: nil)
        }
    }

    // MARK: Ghost mode

    public static var isGhostModeActive: Bool {
        return !self.sendReadPackets && !self.sendOnlinePackets && !self.sendUploadProgress && self.sendOfflinePacketAfterOnline
    }

    public static func setGhostMode(_ enabled: Bool) {
        self.sendReadPackets = !enabled
        self.sendOnlinePackets = !enabled
        self.sendUploadProgress = !enabled
        self.sendOfflinePacketAfterOnline = enabled
    }
}
