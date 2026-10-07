import Foundation
import UIKit
import Display
import TelegramCore
import AccountContext

// AyuGram settings. Same layout as AyuGramPreferencesActivity on Android: header, categories, links.
public func ayuGramSettingsController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "", sections: { env in
        let accent = env.context.sharedContext.currentPresentationData.with { $0 }.theme.list.itemAccentColor
        return [
            [.hero(name: "AyuGram", version: exteraAppVersion(), icon: exteraHeroIcon(glyph: ayuGlyph, accent: accent))],
            [
                .header("Категории"),
                .nav(title: "Режим призрака", symbol: "eye.slash", open: { ayuGhostSettingsController(context: context) }),
                .nav(title: "Шпион", symbol: "eye", open: { ayuSpySettingsController(context: context) }),
            ],
            [
                .header("Ссылки"),
                .link(title: "Канал", symbol: "megaphone", label: "@ayugram", url: "https://t.me/ayugram"),
                .link(title: "Чаты", symbol: "person.2", label: "@ayugramchat", url: "https://t.me/ayugramchat"),
                .link(title: "Перевод", symbol: "character.bubble", label: "Crowdin", url: "https://crowdin.com/project/ayugram"),
                .link(title: "Документация", symbol: "globe", label: "ayugram.one", url: "https://ayugram.one"),
            ],
        ]
    })
}

private func ayuGhostSettingsController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Режим призрака", sections: { _ in
        return [
            [
                .toggle(title: "Режим призрака", symbol: "eye.slash", value: AyuSettings.isGhostModeActive, update: { AyuSettings.setGhostMode($0) }),
            ],
            [
                .header("Отправлять"),
                .toggle(title: "«Прочитано»", symbol: nil, value: AyuSettings.sendReadPackets, update: { AyuSettings.sendReadPackets = $0 }),
                .toggle(title: "«В сети»", symbol: nil, value: AyuSettings.sendOnlinePackets, update: { AyuSettings.sendOnlinePackets = $0 }),
                .toggle(title: "«Печатает»", symbol: nil, value: AyuSettings.sendUploadProgress, update: { AyuSettings.sendUploadProgress = $0 }),
            ],
            [
                .header("После отправки"),
                .toggle(title: "Уходить в офлайн", symbol: nil, value: AyuSettings.sendOfflinePacketAfterOnline, update: { AyuSettings.sendOfflinePacketAfterOnline = $0 }),
                .toggle(title: "Читать чат после ответа", symbol: nil, value: AyuSettings.markReadAfterSend, update: { AyuSettings.markReadAfterSend = $0 }),
            ],
        ]
    })
}

private func ayuSpySettingsController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Шпион", sections: { _ in
        return [
            [
                .toggle(title: "Сохранять удалённые", symbol: "trash.slash", value: AyuSettings.saveDeletedMessages, update: { AyuSettings.saveDeletedMessages = $0 }),
                .note("Помечаются \(AyuSettings.deletedMark), хранятся только на этом устройстве."),
            ],
        ]
    })
}
