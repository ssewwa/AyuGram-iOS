import Foundation
import LocalAuthentication
import Postbox

// exteraGram: individual chats protected with Face ID / Touch ID / device passcode.
// A chat stays unlocked until the app goes to background.
public final class ExteraChatLock {
    private static let storageKey = "extera.lockedPeerIds"
    private static var unlockedPeerIds = Set<Int64>()
    private static var backgroundObserver: NSObjectProtocol?

    private static var lockedPeerIds: Set<Int64> {
        get {
            let values = UserDefaults.standard.array(forKey: self.storageKey) as? [NSNumber] ?? []
            return Set(values.map { $0.int64Value })
        }
        set {
            UserDefaults.standard.set(newValue.map { NSNumber(value: $0) }, forKey: self.storageKey)
            NotificationCenter.default.post(name: AyuSettings.didChangeNotification, object: nil)
        }
    }

    public static var lockedCount: Int {
        return self.lockedPeerIds.count
    }

    public static func isLocked(_ peerId: PeerId) -> Bool {
        return self.lockedPeerIds.contains(peerId.toInt64())
    }

    public static func needsAuthentication(_ peerId: PeerId) -> Bool {
        return self.isLocked(peerId) && !self.unlockedPeerIds.contains(peerId.toInt64())
    }

    public static func setLocked(_ peerId: PeerId, _ locked: Bool) {
        var ids = self.lockedPeerIds
        if locked {
            ids.insert(peerId.toInt64())
        } else {
            ids.remove(peerId.toInt64())
            self.unlockedPeerIds.remove(peerId.toInt64())
        }
        self.lockedPeerIds = ids
    }

    public static func unlockAll() {
        self.lockedPeerIds = Set()
        self.unlockedPeerIds.removeAll()
    }

    // Face ID, Touch ID or at least a device passcode must be set up to protect chats.
    public static var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    public static var biometryName: String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "код-пароль"
        }
    }

    // Calls completion on the main queue.
    public static func authenticate(peerId: PeerId?, reason: String = "Открыть защищённый чат", completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Nothing to authenticate with (the passcode was removed after locking): don't lock the user out.
            DispatchQueue.main.async {
                completion(true)
            }
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason, reply: { success, _ in
            DispatchQueue.main.async {
                if success, let peerId = peerId {
                    self.unlockedPeerIds.insert(peerId.toInt64())
                    self.installRelockObserverIfNeeded()
                }
                completion(success)
            }
        })
    }

    private static func installRelockObserverIfNeeded() {
        if self.backgroundObserver != nil {
            return
        }
        // UIApplication.didEnterBackgroundNotification, without importing UIKit into TelegramCore
        self.backgroundObserver = NotificationCenter.default.addObserver(forName: Notification.Name("UIApplicationDidEnterBackgroundNotification"), object: nil, queue: .main, using: { _ in
            ExteraChatLock.unlockedPeerIds.removeAll()
        })
    }
}
