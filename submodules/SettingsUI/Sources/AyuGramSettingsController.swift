import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

// AyuGram settings screen. Counterpart of AyuGramPreferencesActivity on Android.
private final class AyuGramSettingsControllerArguments {
    let updateGhostMode: (Bool) -> Void
    let updateSendRead: (Bool) -> Void
    let updateSendOnline: (Bool) -> Void
    let updateSendTyping: (Bool) -> Void
    let updateOfflineAfterSend: (Bool) -> Void
    let updateReadAfterSend: (Bool) -> Void
    let updateLiveActivity: (Bool) -> Void
    let updateSaveDeleted: (Bool) -> Void

    init(
        updateGhostMode: @escaping (Bool) -> Void,
        updateSendRead: @escaping (Bool) -> Void,
        updateSendOnline: @escaping (Bool) -> Void,
        updateSendTyping: @escaping (Bool) -> Void,
        updateOfflineAfterSend: @escaping (Bool) -> Void,
        updateReadAfterSend: @escaping (Bool) -> Void,
        updateLiveActivity: @escaping (Bool) -> Void,
        updateSaveDeleted: @escaping (Bool) -> Void
    ) {
        self.updateGhostMode = updateGhostMode
        self.updateSendRead = updateSendRead
        self.updateSendOnline = updateSendOnline
        self.updateSendTyping = updateSendTyping
        self.updateOfflineAfterSend = updateOfflineAfterSend
        self.updateReadAfterSend = updateReadAfterSend
        self.updateLiveActivity = updateLiveActivity
        self.updateSaveDeleted = updateSaveDeleted
    }
}

private enum AyuGramSettingsSection: Int32 {
    case ghost
    case history
}

private enum AyuGramSettingsControllerEntry: ItemListNodeEntry {
    case ghostHeader
    case ghostMode(Bool)
    case sendRead(Bool)
    case sendOnline(Bool)
    case sendTyping(Bool)
    case offlineAfterSend(Bool)
    case readAfterSend(Bool)
    case liveActivity(Bool)
    case ghostFooter

    case historyHeader
    case saveDeleted(Bool)
    case historyFooter

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostMode, .sendRead, .sendOnline, .sendTyping, .offlineAfterSend, .readAfterSend, .liveActivity, .ghostFooter:
            return AyuGramSettingsSection.ghost.rawValue
        case .historyHeader, .saveDeleted, .historyFooter:
            return AyuGramSettingsSection.history.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostHeader:
            return 0
        case .ghostMode:
            return 1
        case .sendRead:
            return 2
        case .sendOnline:
            return 3
        case .sendTyping:
            return 4
        case .offlineAfterSend:
            return 5
        case .readAfterSend:
            return 6
        case .liveActivity:
            return 7
        case .ghostFooter:
            return 8
        case .historyHeader:
            return 9
        case .saveDeleted:
            return 10
        case .historyFooter:
            return 11
        }
    }

    static func <(lhs: AyuGramSettingsControllerEntry, rhs: AyuGramSettingsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramSettingsControllerArguments
        switch self {
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "РЕЖИМ ПРИЗРАКА", sectionId: self.section)
        case let .ghostMode(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Режим призрака", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateGhostMode(value)
            })
        case let .sendRead(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Отправлять «прочитано»", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSendRead(value)
            })
        case let .sendOnline(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Отправлять «в сети»", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSendOnline(value)
            })
        case let .sendTyping(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Отправлять «печатает»", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSendTyping(value)
            })
        case let .offlineAfterSend(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Офлайн после отправки", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateOfflineAfterSend(value)
            })
        case let .readAfterSend(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Прочитать чат после ответа", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateReadAfterSend(value)
            })
        case let .liveActivity(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Значок в Dynamic Island", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateLiveActivity(value)
            })
        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Режим призрака отключает «прочитано», «в сети» и «печатает». Telegram показывает тебя в сети, когда ты отправляешь сообщение, — «Офлайн после отправки» сразу возвращает статус обратно. «Прочитать чат после ответа» отмечает чат прочитанным, когда ты отвечаешь. Пока призрак включён, 👻 висит в Dynamic Island и на экране блокировки."), sectionId: self.section)
        case .historyHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ИСТОРИЯ СООБЩЕНИЙ", sectionId: self.section)
        case let .saveDeleted(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Сохранять удалённые", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSaveDeleted(value)
            })
        case .historyFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Сообщения, которые удалил собеседник, остаются в чате с пометкой \(AyuSettings.deletedMark). Хранятся только на этом устройстве."), sectionId: self.section)
        }
    }
}

private func ayuGramSettingsControllerEntries() -> [AyuGramSettingsControllerEntry] {
    var entries: [AyuGramSettingsControllerEntry] = []

    entries.append(.ghostHeader)
    entries.append(.ghostMode(AyuSettings.isGhostModeActive))
    entries.append(.sendRead(AyuSettings.sendReadPackets))
    entries.append(.sendOnline(AyuSettings.sendOnlinePackets))
    entries.append(.sendTyping(AyuSettings.sendUploadProgress))
    entries.append(.offlineAfterSend(AyuSettings.sendOfflinePacketAfterOnline))
    entries.append(.readAfterSend(AyuSettings.markReadAfterSend))
    entries.append(.liveActivity(AyuGhostLiveActivity.isEnabled))
    entries.append(.ghostFooter)

    entries.append(.historyHeader)
    entries.append(.saveDeleted(AyuSettings.saveDeletedMessages))
    entries.append(.historyFooter)

    return entries
}

public func ayuGramSettingsController(context: AccountContext) -> ViewController {
    // AyuSettings lives in UserDefaults; this promise just re-renders the list after a change.
    let refreshPromise = ValuePromise<Bool>(true, ignoreRepeated: false)
    let refresh: () -> Void = {
        refreshPromise.set(true)
    }

    let arguments = AyuGramSettingsControllerArguments(
        updateGhostMode: { value in
            AyuSettings.setGhostMode(value)
            refresh()
        },
        updateSendRead: { value in
            AyuSettings.sendReadPackets = value
            refresh()
        },
        updateSendOnline: { value in
            AyuSettings.sendOnlinePackets = value
            refresh()
        },
        updateSendTyping: { value in
            AyuSettings.sendUploadProgress = value
            refresh()
        },
        updateOfflineAfterSend: { value in
            AyuSettings.sendOfflinePacketAfterOnline = value
            refresh()
        },
        updateReadAfterSend: { value in
            AyuSettings.markReadAfterSend = value
            refresh()
        },
        updateLiveActivity: { value in
            AyuGhostLiveActivity.isEnabled = value
            refresh()
        },
        updateSaveDeleted: { value in
            AyuSettings.saveDeletedMessages = value
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

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("AyuGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: ayuGramSettingsControllerEntries(), style: .blocks, animateChanges: true)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
