import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

// exteraGram settings screen. Counterpart of the exteraGram preferences on Android.
private final class ExteraGramSettingsControllerArguments {
    let updateTitleText: (String) -> Void
    let updateTimeWithSeconds: (Bool) -> Void
    let updateNumberRounding: (Bool) -> Void
    let updateHidePhoneNumber: (Bool) -> Void
    let updateShowIdAndDc: (Bool) -> Void

    init(
        updateTitleText: @escaping (String) -> Void,
        updateTimeWithSeconds: @escaping (Bool) -> Void,
        updateNumberRounding: @escaping (Bool) -> Void,
        updateHidePhoneNumber: @escaping (Bool) -> Void,
        updateShowIdAndDc: @escaping (Bool) -> Void
    ) {
        self.updateTitleText = updateTitleText
        self.updateTimeWithSeconds = updateTimeWithSeconds
        self.updateNumberRounding = updateNumberRounding
        self.updateHidePhoneNumber = updateHidePhoneNumber
        self.updateShowIdAndDc = updateShowIdAndDc
    }
}

private enum ExteraGramSettingsSection: Int32 {
    case title
    case appearance
    case profile
}

private enum ExteraGramSettingsControllerEntry: ItemListNodeEntry {
    case titleHeader
    case titleText(String)
    case titleFooter

    case appearanceHeader
    case timeWithSeconds(Bool)
    case numberRounding(Bool)
    case appearanceFooter

    case profileHeader
    case hidePhoneNumber(Bool)
    case showIdAndDc(Bool)
    case profileFooter

    var section: ItemListSectionId {
        switch self {
        case .titleHeader, .titleText, .titleFooter:
            return ExteraGramSettingsSection.title.rawValue
        case .appearanceHeader, .timeWithSeconds, .numberRounding, .appearanceFooter:
            return ExteraGramSettingsSection.appearance.rawValue
        case .profileHeader, .hidePhoneNumber, .showIdAndDc, .profileFooter:
            return ExteraGramSettingsSection.profile.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .titleHeader:
            return 0
        case .titleText:
            return 1
        case .titleFooter:
            return 2
        case .appearanceHeader:
            return 3
        case .timeWithSeconds:
            return 4
        case .numberRounding:
            return 5
        case .appearanceFooter:
            return 6
        case .profileHeader:
            return 7
        case .hidePhoneNumber:
            return 8
        case .showIdAndDc:
            return 9
        case .profileFooter:
            return 10
        }
    }

    static func <(lhs: ExteraGramSettingsControllerEntry, rhs: ExteraGramSettingsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraGramSettingsControllerArguments
        switch self {
        case .titleHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ЗАГОЛОВОК", sectionId: self.section)
        case let .titleText(value):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(string: ""), text: value, placeholder: "Чаты", type: .regular(capitalization: true, autocorrection: false), spacing: 0.0, clearType: .always, maxLength: 32, sectionId: self.section, textUpdated: { updatedText in
                arguments.updateTitleText(updatedText)
            }, action: {})
        case .titleFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Текст над списком чатов. Оставь пустым, чтобы вернуть стандартный. Применится после перезапуска приложения."), sectionId: self.section)
        case .appearanceHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ВНЕШНИЙ ВИД", sectionId: self.section)
        case let .timeWithSeconds(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Время с секундами", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateTimeWithSeconds(value)
            })
        case let .numberRounding(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Не округлять числа", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateNumberRounding(value)
            })
        case .appearanceFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Время сообщений будет показываться с секундами, а просмотры и участники — полным числом: 1 234 вместо 1.2K."), sectionId: self.section)
        case .profileHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ПРОФИЛЬ И ПРИВАТНОСТЬ", sectionId: self.section)
        case let .hidePhoneNumber(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Скрыть свой номер", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHidePhoneNumber(value)
            })
        case let .showIdAndDc(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Показывать ID и DC", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateShowIdAndDc(value)
            })
        case .profileFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Номер не будет виден в шапке настроек — удобно для скриншотов. ID и дата-центр появятся в профилях людей, групп и каналов; нажми на строку, чтобы скопировать ID."), sectionId: self.section)
        }
    }
}

private func exteraGramSettingsControllerEntries() -> [ExteraGramSettingsControllerEntry] {
    var entries: [ExteraGramSettingsControllerEntry] = []

    entries.append(.titleHeader)
    entries.append(.titleText(ExteraSettings.titleText))
    entries.append(.titleFooter)

    entries.append(.appearanceHeader)
    entries.append(.timeWithSeconds(ExteraSettings.formatTimeWithSeconds))
    entries.append(.numberRounding(ExteraSettings.disableNumberRounding))
    entries.append(.appearanceFooter)

    entries.append(.profileHeader)
    entries.append(.hidePhoneNumber(ExteraSettings.hidePhoneNumber))
    entries.append(.showIdAndDc(ExteraSettings.showIdAndDc))
    entries.append(.profileFooter)

    return entries
}

public func exteraGramSettingsController(context: AccountContext) -> ViewController {
    // ExteraSettings lives in UserDefaults; this promise just re-renders the list after a change.
    let refreshPromise = ValuePromise<Bool>(true, ignoreRepeated: false)
    let refresh: () -> Void = {
        refreshPromise.set(true)
    }

    let arguments = ExteraGramSettingsControllerArguments(
        updateTitleText: { value in
            ExteraSettings.titleText = value.trimmingCharacters(in: .whitespacesAndNewlines)
        },
        updateTimeWithSeconds: { value in
            ExteraSettings.formatTimeWithSeconds = value
            refresh()
        },
        updateNumberRounding: { value in
            ExteraSettings.disableNumberRounding = value
            refresh()
        },
        updateHidePhoneNumber: { value in
            ExteraSettings.hidePhoneNumber = value
            refresh()
        },
        updateShowIdAndDc: { value in
            ExteraSettings.showIdAndDc = value
            refresh()
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        refreshPromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var presentationData = presentationData

        let updatedTheme = presentationData.theme.withModalBlocksBackground()
        presentationData = presentationData.withUpdated(theme: updatedTheme)

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("exteraGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraGramSettingsControllerEntries(), style: .blocks, animateChanges: true)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
