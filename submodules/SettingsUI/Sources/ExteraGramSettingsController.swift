import Foundation
import UIKit
import Display
import TelegramCore
import AccountContext

// exteraGram settings. Same layout as the exteraGram preferences on Android: header, categories, links.
public func exteraGramSettingsController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "", sections: { env in
        let accent = env.context.sharedContext.currentPresentationData.with { $0 }.theme.list.itemAccentColor
        return [
            [.hero(name: "exteraGram", version: exteraAppVersion(), icon: exteraHeroIcon(glyph: exteraGlyph, accent: accent))],
            [
                .header("Категории"),
                .nav(title: "Основные", symbol: "square.grid.2x2", open: { exteraGeneralController(context: context) }),
                .nav(title: "Оформление", symbol: "paintpalette", open: { exteraAppearanceController(context: context) }),
                .nav(title: "Чаты", symbol: "bubble.left", open: { exteraChatsController(context: context) }),
                .nav(title: "Apple Intelligence", symbol: "sparkles", open: { exteraIntelligenceController(context: context) }),
                .nav(title: "Другое", symbol: "star", open: { exteraOtherController(context: context) }),
            ],
            [
                .header("Ссылки"),
                .link(title: "Канал", symbol: "megaphone", label: "@exteraGram", url: "https://t.me/exteraGram"),
                .link(title: "Чаты", symbol: "person.2", label: "@exteraChat", url: "https://t.me/exteraChat"),
                .link(title: "Перевод", symbol: "character.bubble", label: "Crowdin", url: "https://crowdin.com/project/exteralocales"),
                .link(title: "Веб-сайт", symbol: "globe", label: "exteraGram.app", url: "https://exteragram.app"),
            ],
        ]
    })
}

private func exteraGeneralController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Основные", sections: { env in
        let lockedCount = ExteraChatLock.lockedCount
        return [
            [
                .header("Заголовок списка чатов"),
                .input(placeholder: "Чаты", text: ExteraSettings.titleText, update: { ExteraSettings.titleText = $0.trimmingCharacters(in: .whitespacesAndNewlines) }),
                .note("После перезапуска."),
            ],
            [
                .header("Защищённые чаты"),
                .action(title: lockedCount == 0 ? "Нет защищённых чатов" : "Снять защиту со всех (\(lockedCount))", destructive: true, enabled: lockedCount != 0, perform: {
                    ExteraChatLock.authenticate(peerId: nil, reason: "Снять защиту со всех чатов", completion: { success in
                        if success {
                            ExteraChatLock.unlockAll()
                            env.refresh()
                        }
                    })
                }),
                .note("Зажми чат → «Защитить \(ExteraChatLock.biometryName)»."),
            ],
            [
                .header("Экран"),
                .toggle(title: "Скрывать при записи экрана", symbol: "record.circle", value: ExteraSettings.hideOnScreenCapture, update: { ExteraSettings.hideOnScreenCapture = $0 }),
                .toggle(title: "Размывать в переключателе", symbol: "square.stack", value: ExteraSettings.hideInAppSwitcher, update: { ExteraSettings.hideInAppSwitcher = $0 }),
            ],
        ]
    })
}

private func exteraAppearanceController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Оформление", sections: { _ in
        return [
            [
                .toggle(title: "Время с секундами", symbol: "clock", value: ExteraSettings.formatTimeWithSeconds, update: { ExteraSettings.formatTimeWithSeconds = $0 }),
                .toggle(title: "Не округлять числа", symbol: "number", value: ExteraSettings.disableNumberRounding, update: { ExteraSettings.disableNumberRounding = $0 }),
            ],
        ]
    })
}

private func exteraChatsController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Чаты", sections: { _ in
        return [
            [
                .toggle(title: "Расшифровка голосовых", symbol: "waveform", value: ExteraSettings.localVoiceTranscription, update: { ExteraSettings.localVoiceTranscription = $0 }),
                .note("Бесплатно, на устройстве."),
            ],
        ]
    })
}

private func exteraIntelligenceController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Apple Intelligence", sections: { _ in
        var rows: [ExteraRow] = [
            .toggle(title: "Коротко", symbol: "sparkles", value: ExteraSettings.aiSummary, update: { ExteraSettings.aiSummary = $0 }),
        ]
        if let reason = ExteraChatSummary.unavailableReason {
            rows.append(.note(reason + "."))
        } else {
            rows.append(.note("Зажми чат → «Коротко». Всё на устройстве."))
        }
        return [rows]
    })
}

private func exteraOtherController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Другое", sections: { _ in
        return [
            [
                .toggle(title: "Скрыть свой номер", symbol: "phone", value: ExteraSettings.hidePhoneNumber, update: { ExteraSettings.hidePhoneNumber = $0 }),
                .toggle(title: "Показывать ID и DC", symbol: "number.circle", value: ExteraSettings.showIdAndDc, update: { ExteraSettings.showIdAndDc = $0 }),
            ],
        ]
    })
}
