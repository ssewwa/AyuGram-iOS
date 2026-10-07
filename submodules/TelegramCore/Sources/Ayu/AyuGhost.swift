import Foundation
import TelegramApi
import SwiftSignalKit
import MtProtoKit

// Network-level ghost mode, the iOS counterpart of the AyuGram request hook in
// ConnectionsManager.sendRequestInternal on Android.
enum AyuGhostRequestAction {
    // Don't send; answer with Bool.boolTrue as if the server accepted it.
    case fakeTrue
    // Don't send; fail. Used for methods returning messages.AffectedMessages: every caller
    // catches the error, and a fake pts would corrupt the update state.
    case fail
}

func ayuGhostRequestAction(functionName: String) -> AyuGhostRequestAction? {
    switch functionName {
    case "messages.setTyping", "messages.setEncryptedTyping":
        return AyuSettings.sendUploadProgress ? nil : .fakeTrue
    case "channels.readHistory", "channels.readMessageContents", "messages.readDiscussion", "messages.readEncryptedHistory":
        return AyuSettings.sendReadPackets ? nil : .fakeTrue
    case "messages.readHistory", "messages.readMessageContents":
        return AyuSettings.sendReadPackets ? nil : .fail
    default:
        return nil
    }
}

func ayuGhostIntercept<T>(_ data: (FunctionDescription, Buffer, DeserializeFunctionResponse<T>)) -> Signal<T, MTRpcError>? {
    guard let action = ayuGhostRequestAction(functionName: data.0.name) else {
        return nil
    }
    switch action {
    case .fakeTrue:
        let buffer = Buffer()
        buffer.appendInt32(-1720552011) // boolTrue
        if let result = data.2.parse(buffer) {
            return .single(result)
        }
        return .fail(MTRpcError(errorCode: 400, errorDescription: "AYU_GHOST_BLOCKED"))
    case .fail:
        return .fail(MTRpcError(errorCode: 400, errorDescription: "AYU_GHOST_BLOCKED"))
    }
}

func ayuIsSendMessageRequest(functionName: String) -> Bool {
    switch functionName {
    case "messages.sendMessage", "messages.sendMedia", "messages.sendMultiMedia":
        return true
    default:
        return false
    }
}
