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
    let unlockAllChats: () -> Void
    let updateLocalTranscription: (Bool) -> Void
    let updateHideOnScreenCapture: (Bool) -> Void
    let updateHideInAppSwitcher: (Bool) -> Void

    init(
        updateTitleText: @escaping (String) -> Void,
        updateTimeWithSeconds: @escaping (Bool) -> Void,
        updateNumberRounding: @escaping (Bool) -> Void,
        updateHidePhoneNumber: @escaping (Bool) -> Void,
        updateShowIdAndDc: @escaping (Bool) -> Void,
        unlockAllChats: @escaping () -> Void,
        updateLocalTranscription: @escaping (Bool) -> Void,
        updateHideOnScreenCapture: @escaping (Bool) -> Void,
        updateHideInAppSwitcher: @escaping (Bool) -> Void
    ) {
        self.updateTitleText = updateTitleText
        self.updateTimeWithSeconds = updateTimeWithSeconds
        self.updateNumberRounding = updateNumberRounding
        self.updateHidePhoneNumber = updateHidePhoneNumber
        self.updateShowIdAndDc = updateShowIdAndDc
        self.unlockAllChats = unlockAllChats
        self.updateLocalTranscription = updateLocalTranscription
        self.updateHideOnScreenCapture = updateHideOnScreenCapture
        self.updateHideInAppSwitcher = updateHideInAppSwitcher
    }
}

private enum ExteraGramSettingsSection: Int32 {
    case title
    case appearance
    case profile
    case lockedChats
    case voice
    case screen
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

    case lockedChatsHeader
    case unlockAllChats(Int)
    case lockedChatsFooter(String)

    case voiceHeader
    case localTranscription(Bool)
    case voiceFooter

    case screenHeader
    case hideOnScreenCapture(Bool)
    case hideInAppSwitcher(Bool)
    case screenFooter

    var section: ItemListSectionId {
        switch self {
        case .titleHeader, .titleText, .titleFooter:
            return ExteraGramSettingsSection.title.rawValue
        case .appearanceHeader, .timeWithSeconds, .numberRounding, .appearanceFooter:
            return ExteraGramSettingsSection.appearance.rawValue
        case .profileHeader, .hidePhoneNumber, .showIdAndDc, .profileFooter:
            return ExteraGramSettingsSection.profile.rawValue
        case .lockedChatsHeader, .unlockAllChats, .lockedChatsFooter:
            return ExteraGramSettingsSection.lockedChats.rawValue
        case .voiceHeader, .localTranscription, .voiceFooter:
            return ExteraGramSettingsSection.voice.rawValue
        case .screenHeader, .hideOnScreenCapture, .hideInAppSwitcher, .screenFooter:
            return ExteraGramSettingsSection.screen.rawValue
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
        case .lockedChatsHeader:
            return 11
        case .unlockAllChats:
            return 12
        case .lockedChatsFooter:
            return 13
        case .voiceHeader:
            return 14
        case .localTranscription:
            return 15
        case .voiceFooter:
            return 16
        case .screenHeader:
            return 17
        case .hideOnScreenCapture:
            return 18
        case .hideInAppSwitcher:
            return 19
        case .screenFooter:
            return 20
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
        case .lockedChatsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ЗАЩИЩЁННЫЕ ЧАТЫ", sectionId: self.section)
        case let .unlockAllChats(count):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: count == 0 ? "Нет защищённых чатов" : "Снять защиту со всех (\(count))", kind: count == 0 ? .disabled : .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.unlockAllChats()
            })
        case let .lockedChatsFooter(biometryName):
            return ItemListTextItem(presentationData: presentationData, text: .plain("Зажми чат в списке и выбери «Защитить \(biometryName)». Такой чат откроется только после проверки, в списке вместо последнего сообщения будет «🔒 Чат защищён», а превью по долгому нажатию скроется. Чат снова закрывается, когда ты выходишь из приложения."), sectionId: self.section)
        case .voiceHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ГОЛОСОВЫЕ", sectionId: self.section)
        case let .localTranscription(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Расшифровка на устройстве", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateLocalTranscription(value)
            })
        case .voiceFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Кнопка «Расшифровать» под каждым голосовым, без Telegram Premium. Речь распознаёт сам iPhone — голос не отправляется в Telegram. Если для языка нет офлайн-модели, iOS может использовать серверы Apple."), sectionId: self.section)
        case .screenHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ЭКРАН", sectionId: self.section)
        case let .hideOnScreenCapture(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Скрывать при записи экрана", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHideOnScreenCapture(value)
            })
        case let .hideInAppSwitcher(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Размывать в переключателе приложений", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHideInAppSwitcher(value)
            })
        case .screenFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Во время записи экрана, трансляции через AirPlay или показа экрана в созвоне приложение закрывается размытием. В переключателе приложений вместо переписки будет размытие. Обычные скриншоты iOS запретить не даёт."), sectionId: self.section)
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

    entries.append(.lockedChatsHeader)
    entries.append(.unlockAllChats(ExteraChatLock.lockedCount))
    entries.append(.lockedChatsFooter(ExteraChatLock.biometryName))

    entries.append(.voiceHeader)
    entries.append(.localTranscription(ExteraSettings.localVoiceTranscription))
    entries.append(.voiceFooter)

    entries.append(.screenHeader)
    entries.append(.hideOnScreenCapture(ExteraSettings.hideOnScreenCapture))
    entries.append(.hideInAppSwitcher(ExteraSettings.hideInAppSwitcher))
    entries.append(.screenFooter)

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
        },
        unlockAllChats: {
            ExteraChatLock.authenticate(peerId: nil, reason: "Снять защиту со всех чатов", completion: { success in
                if success {
                    ExteraChatLock.unlockAll()
                    refresh()
                }
            })
        },
        updateLocalTranscription: { value in
            ExteraSettings.localVoiceTranscription = value
            refresh()
        },
        updateHideOnScreenCapture: { value in
            ExteraSettings.hideOnScreenCapture = value
            refresh()
        },
        updateHideInAppSwitcher: { value in
            ExteraSettings.hideInAppSwitcher = value
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
