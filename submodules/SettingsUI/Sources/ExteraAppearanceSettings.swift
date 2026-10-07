import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import AccountContext
import AppBundle

// exteraGram → Оформление: app icon, chat list, tab bar, bubbles, font, colors.
func exteraAppearanceController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Оформление", sections: { _ in
        return [
            [
                .nav(title: "Иконка приложения", symbol: "app", open: { exteraAppIconController(context: context) }),
                .nav(title: "Список чатов", symbol: "list.bullet", open: { exteraChatListAppearanceController(context: context) }),
                .nav(title: "Нижняя панель", symbol: "dock.rectangle", open: { exteraTabBarController(context: context) }),
                .nav(title: "Пузыри", symbol: "bubble.left.and.bubble.right", open: { exteraBubblesController(context: context) }),
                .nav(title: "Шрифт", symbol: "textformat", open: { exteraFontController(context: context) }),
                .nav(title: "Цвета", symbol: "paintpalette", open: { exteraColorsController(context: context) }),
            ],
            [
                .toggle(title: "Время с секундами", symbol: "clock", value: ExteraSettings.formatTimeWithSeconds, update: { ExteraSettings.formatTimeWithSeconds = $0 }),
                .toggle(title: "Не округлять числа", symbol: "number", value: ExteraSettings.disableNumberRounding, update: { ExteraSettings.disableNumberRounding = $0 }),
            ],
        ]
    })
}

private let iconTitles: [String: String] = [
    "Telegram": "exteraGram",
    "ExteraBlack": "Чёрная",
    "ExteraWhite": "Белая",
    "ExteraSunset": "Закат",
    "ExteraOcean": "Океан",
    "ExteraMidnight": "Полночь",
    "ExteraGold": "Золото",
    "ExteraMint": "Мята",
    "AyuGhost": "Призрак",
]

private func exteraAppIconController(context: AccountContext) -> ViewController {
    let bindings = context.sharedContext.applicationBindings
    return exteraPageController(context: context, title: "Иконка", sections: { env in
        let current = bindings.getAlternateIconName()
        let rows: [ExteraRow] = bindings.getAvailableAlternateIcons().map { icon in
            let image = UIImage(named: icon.imageName) ?? UIImage(named: icon.imageName, in: getAppBundle(), compatibleWith: nil)
            let rounded = image.flatMap { exteraRoundedIcon($0) }
            let selected = icon.isDefault ? current == nil : current == icon.name
            return .choice(title: iconTitles[icon.name] ?? icon.name, icon: rounded, selected: selected, select: {
                bindings.requestSetAlternateIconName(icon.isDefault ? nil : icon.name, { _ in
                    env.refresh()
                })
            })
        }
        return [rows]
    })
}

private func exteraRoundedIcon(_ image: UIImage) -> UIImage {
    let size = CGSize(width: 30.0, height: 30.0)
    return UIGraphicsImageRenderer(size: size).image { _ in
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 7.0).addClip()
        image.draw(in: CGRect(origin: .zero, size: size))
    }
}

private func exteraChatListAppearanceController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Список чатов", sections: { _ in
        let mode = ExteraSettings.titleMode
        var titleRows: [ExteraRow] = [
            .header("Заголовок"),
            .choice(title: "Свой текст", icon: nil, selected: mode == "text", select: { ExteraSettings.titleMode = "text" }),
            .choice(title: "Имя аккаунта", icon: nil, selected: mode == "name", select: { ExteraSettings.titleMode = "name" }),
            .choice(title: "@юзернейм", icon: nil, selected: mode == "username", select: { ExteraSettings.titleMode = "username" }),
            .choice(title: "Без заголовка", icon: nil, selected: mode == "none", select: { ExteraSettings.titleMode = "none" }),
        ]
        if mode == "text" {
            titleRows.append(.input(placeholder: "Чаты", text: ExteraSettings.titleText, update: { ExteraSettings.titleText = $0.trimmingCharacters(in: .whitespacesAndNewlines) }))
        }
        titleRows.append(.note("После перезапуска."))

        let shape = ExteraSettings.avatarShape
        return [
            [
                .toggle(title: "Компактный список", symbol: "rectangle.compress.vertical", value: ExteraSettings.compactChatList, update: { ExteraSettings.compactChatList = $0 }),
                .toggle(title: "Скрыть истории", symbol: "circle.dashed", value: ExteraSettings.hideStories, update: { ExteraSettings.hideStories = $0 }),
            ],
            titleRows,
            [
                .header("Форма аватарок"),
                .choice(title: "Круг", icon: nil, selected: shape == "circle", select: { ExteraSettings.avatarShape = "circle" }),
                .choice(title: "Скруглённый квадрат", icon: nil, selected: shape == "rounded", select: { ExteraSettings.avatarShape = "rounded" }),
                .note("После перезапуска."),
            ],
        ]
    })
}

private func exteraTabBarController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Нижняя панель", sections: { _ in
        return [
            [
                .toggle(title: "Чаты первой вкладкой", symbol: "bubble.left", value: ExteraSettings.chatsTabFirst, update: { ExteraSettings.chatsTabFirst = $0 }),
                .toggle(title: "Скрыть «Контакты»", symbol: "person.crop.circle", value: ExteraSettings.hideContactsTab, update: { ExteraSettings.hideContactsTab = $0 }),
                .toggle(title: "Скрыть «Звонки»", symbol: "phone", value: ExteraSettings.hideCallsTab, update: { ExteraSettings.hideCallsTab = $0 }),
                .note("После перезапуска."),
            ],
        ]
    })
}

private func exteraBubblesController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Пузыри", sections: { env in
        let tail = ExteraSettings.bubbleTail
        let density = ExteraSettings.chatDensity
        let radius = Int32(context.sharedContext.currentPresentationData.with { $0 }.chatBubbleCorners.mainRadius)
        let setRadius: (Int32) -> Void = { value in
            let _ = updatePresentationThemeSettingsInteractively(accountManager: context.sharedContext.accountManager, { current in
                var current = current
                current.chatBubbleSettings = PresentationChatBubbleSettings(mainRadius: value, auxiliaryRadius: min(value, 8), mergeBubbleCorners: value >= 10)
                return current
            }).start(completed: {
                env.refresh()
            })
        }
        return [
            [
                .header("Скругление"),
                .choice(title: "Квадратные", icon: nil, selected: radius <= 2, select: { setRadius(2) }),
                .choice(title: "Слегка скруглённые", icon: nil, selected: radius > 2 && radius <= 8, select: { setRadius(8) }),
                .choice(title: "Обычные", icon: nil, selected: radius > 8 && radius < 16, select: { setRadius(12) }),
                .choice(title: "Круглые", icon: nil, selected: radius >= 16, select: { setRadius(16) }),
            ],
            [
                .header("Хвостики"),
                .choice(title: "Обычные", icon: nil, selected: tail != "none", select: { ExteraSettings.bubbleTail = "default" }),
                .choice(title: "Без хвостиков", icon: nil, selected: tail == "none", select: { ExteraSettings.bubbleTail = "none" }),
            ],
            [
                .header("Плотность"),
                .choice(title: "Плотно", icon: nil, selected: density == "compact", select: { ExteraSettings.chatDensity = "compact" }),
                .choice(title: "Обычно", icon: nil, selected: density == "default", select: { ExteraSettings.chatDensity = "default" }),
                .choice(title: "Воздушно", icon: nil, selected: density == "airy", select: { ExteraSettings.chatDensity = "airy" }),
            ],
            [
                .toggle(title: "Стеклянные пузыри", symbol: "drop", value: ExteraSettings.glassBubbles, update: { ExteraSettings.glassBubbles = $0 }),
                .toggle(title: "Скрыть время", symbol: "clock.badge.xmark", value: ExteraSettings.hideMessageTime, update: { ExteraSettings.hideMessageTime = $0 }),
                .note("Хвостики, стекло и плотность — после перезапуска."),
            ],
        ]
    })
}

private func exteraFontController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Шрифт", sections: { _ in
        let design = ExteraSettings.fontDesign
        let options: [(String, String)] = [("regular", "Системный"), ("round", "SF Rounded"), ("serif", "New York"), ("monospace", "Моноширинный")]
        var rows: [ExteraRow] = options.map { key, title in
            .choice(title: title, icon: nil, selected: design == key, select: { ExteraSettings.fontDesign = key })
        }
        rows.append(.note("После перезапуска."))
        return [rows]
    })
}

private let accentOptions: [(String, UInt32?)] = [
    ("Из темы", nil),
    ("Красный exteraGram", 0xFFE83030),
    ("Розовый", 0xFFFF5A8A),
    ("Оранжевый", 0xFFFF9500),
    ("Жёлтый", 0xFFFFC300),
    ("Зелёный", 0xFF34C759),
    ("Мятный", 0xFF00C7BE),
    ("Синий", 0xFF007AFF),
    ("Фиолетовый", 0xFFAF52DE),
]

private func exteraColorDot(_ argb: UInt32) -> UIImage {
    let size = CGSize(width: 30.0, height: 30.0)
    let color = UIColor(red: CGFloat((argb >> 16) & 0xFF) / 255.0, green: CGFloat((argb >> 8) & 0xFF) / 255.0, blue: CGFloat(argb & 0xFF) / 255.0, alpha: 1.0)
    return UIGraphicsImageRenderer(size: size).image { _ in
        color.setFill()
        UIBezierPath(ovalIn: CGRect(x: 4.0, y: 4.0, width: 22.0, height: 22.0)).fill()
    }
}

private func exteraColorsController(context: AccountContext) -> ViewController {
    return exteraPageController(context: context, title: "Цвета", sections: { env in
        let selectedAccent = UserDefaults.standard.object(forKey: "extera.accentColor") as? Int
        let accentRows: [ExteraRow] = accentOptions.map { title, argb in
            let selected = argb.map { Int($0) == selectedAccent } ?? (selectedAccent == nil)
            return .choice(title: title, icon: argb.map(exteraColorDot), selected: selected, select: {
                if let argb = argb {
                    UserDefaults.standard.set(Int(argb), forKey: "extera.accentColor")
                } else {
                    UserDefaults.standard.removeObject(forKey: "extera.accentColor")
                }
                exteraApplyAccent(context: context, argb: argb)
            })
        }
        let oled = UserDefaults.standard.bool(forKey: "extera.oledBlack")
        return [
            [ExteraRow.header("Акцентный цвет")] + accentRows,
            [
                .toggle(title: "Чёрная тема для OLED", symbol: "moon.fill", value: oled, update: { value in
                    UserDefaults.standard.set(value, forKey: "extera.oledBlack")
                    exteraApplyOled(context: context, value)
                }),
                .note("Ночная тема становится полностью чёрной."),
            ],
        ]
    })
}

// Sets the accent of the current built-in theme, the same way Settings → Appearance does.
private func exteraApplyAccent(context: AccountContext, argb: UInt32?) {
    let autoNight = context.sharedContext.currentPresentationData.with { $0 }.autoNightModeTriggered
    let _ = updatePresentationThemeSettingsInteractively(accountManager: context.sharedContext.accountManager, { current in
        var current = current
        let reference = autoNight ? current.automaticThemeSwitchSetting.theme : current.theme
        guard case .builtin = reference else {
            return current
        }
        if let argb = argb {
            current.themeSpecificAccentColors[reference.index] = PresentationThemeAccentColor(index: 100, baseColor: .custom, accentColor: argb)
        } else {
            current.themeSpecificAccentColors[reference.index] = nil
        }
        return current
    }).start()
}

// Pure black night theme: Telegram's built-in "Night" instead of the tinted one.
private func exteraApplyOled(context: AccountContext, _ value: Bool) {
    let _ = updatePresentationThemeSettingsInteractively(accountManager: context.sharedContext.accountManager, { current in
        var current = current
        let night: PresentationThemeReference = .builtin(value ? .night : .nightAccent)
        current.automaticThemeSwitchSetting.theme = night
        if case let .builtin(theme) = current.theme, theme == .night || theme == .nightAccent {
            current.theme = night
        }
        return current
    }).start()
}
