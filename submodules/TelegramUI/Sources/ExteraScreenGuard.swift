import Foundation
import UIKit
import TelegramCore

// exteraGram: hides the app content while the screen is recorded / mirrored / shared,
// and in the App Switcher snapshot.
final class ExteraScreenGuard {
    static let shared = ExteraScreenGuard()

    private weak var window: UIWindow?
    private var captureOverlay: UIView?
    private var switcherOverlay: UIView?
    private var observers: [NSObjectProtocol] = []

    func install(window: UIWindow) {
        self.window = window

        let center = NotificationCenter.default
        self.observers.append(center.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.updateCaptureOverlay()
        }))
        self.observers.append(center.addObserver(forName: AyuSettings.didChangeNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.updateCaptureOverlay()
        }))
        self.observers.append(center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.setSwitcherOverlayVisible(ExteraSettings.hideInAppSwitcher)
        }))
        self.observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.setSwitcherOverlayVisible(false)
        }))

        self.updateCaptureOverlay()
    }

    private func updateCaptureOverlay() {
        guard let window = self.window else {
            return
        }
        let isCaptured = window.screen.isCaptured
        if isCaptured && ExteraSettings.hideOnScreenCapture {
            if self.captureOverlay == nil {
                let overlay = self.makeOverlay(text: "🔒\nИдёт запись или трансляция экрана\nСодержимое скрыто")
                overlay.frame = window.bounds
                window.addSubview(overlay)
                self.captureOverlay = overlay
            }
            if let overlay = self.captureOverlay {
                window.bringSubviewToFront(overlay)
            }
        } else if let overlay = self.captureOverlay {
            overlay.removeFromSuperview()
            self.captureOverlay = nil
        }
    }

    private func setSwitcherOverlayVisible(_ visible: Bool) {
        guard let window = self.window else {
            return
        }
        if visible {
            if self.switcherOverlay == nil {
                let overlay = self.makeOverlay(text: nil)
                overlay.frame = window.bounds
                window.addSubview(overlay)
                self.switcherOverlay = overlay
            }
        } else if let overlay = self.switcherOverlay {
            overlay.removeFromSuperview()
            self.switcherOverlay = nil
        }
    }

    private func makeOverlay(text: String?) -> UIView {
        let overlay = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if let text = text {
            let label = UILabel()
            label.text = text
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
            label.translatesAutoresizingMaskIntoConstraints = false
            overlay.contentView.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: overlay.contentView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: overlay.contentView.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.contentView.leadingAnchor, constant: 32.0),
                label.trailingAnchor.constraint(lessThanOrEqualTo: overlay.contentView.trailingAnchor, constant: -32.0)
            ])
        }
        return overlay
    }
}
