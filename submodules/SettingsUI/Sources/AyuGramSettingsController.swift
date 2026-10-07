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
// TODO: move strings to the localization files.
private final class AyuGramSettingsControllerArguments {
    let updateGhostMode: (Bool) -> Void
    let updateSendRead: (Bool) -> Void
    let updateSendOnline: (Bool) -> Void
    let updateSendTyping: (Bool) -> Void
    let updateOfflineAfterSend: (Bool) -> Void
    let updateSaveDeleted: (Bool) -> Void

    init(
        updateGhostMode: @escaping (Bool) -> Void,
        updateSendRead: @escaping (Bool) -> Void,
        updateSendOnline: @escaping (Bool) -> Void,
        updateSendTyping: @escaping (Bool) -> Void,
        updateOfflineAfterSend: @escaping (Bool) -> Void,
        updateSaveDeleted: @escaping (Bool) -> Void
    ) {
        self.updateGhostMode = updateGhostMode
        self.updateSendRead = updateSendRead
        self.updateSendOnline = updateSendOnline
        self.updateSendTyping = updateSendTyping
        self.updateOfflineAfterSend = updateOfflineAfterSend
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
    case ghostFooter

    case historyHeader
    case saveDeleted(Bool)
    case historyFooter

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostMode, .sendRead, .sendOnline, .sendTyping, .offlineAfterSend, .ghostFooter:
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
        case .ghostFooter:
            return 6
        case .historyHeader:
            return 7
        case .saveDeleted:
            return 8
        case .historyFooter:
            return 9
        }
    }

    static func <(lhs: AyuGramSettingsControllerEntry, rhs: AyuGramSettingsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramSettingsControllerArguments
        switch self {
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "GHOST MODE", sectionId: self.section)
        case let .ghostMode(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Ghost Mode", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateGhostMode(value)
            })
        case let .sendRead(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send Read Status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSendRead(value)
            })
        case let .sendOnline(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send Online Status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSendOnline(value)
            })
        case let .sendTyping(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send Typing Status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSendTyping(value)
            })
        case let .offlineAfterSend(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Go Offline After Sending", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateOfflineAfterSend(value)
            })
        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Ghost Mode turns off read, online and typing statuses. Telegram marks you online when you send a message, \"Go Offline After Sending\" switches you back right away."), sectionId: self.section)
        case .historyHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "MESSAGE HISTORY", sectionId: self.section)
        case let .saveDeleted(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Save Deleted Messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSaveDeleted(value)
            })
        case .historyFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Messages deleted by others stay in the chat, marked with \(AyuSettings.deletedMark). Saved only on this device."), sectionId: self.section)
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
