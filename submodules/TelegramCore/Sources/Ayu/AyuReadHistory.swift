import Foundation
import Postbox
import TelegramApi
import SwiftSignalKit
import MtProtoKit

// Marks the whole chat as read on the server, bypassing ghost mode.
// Counterpart of AyuGhostUtils.markReadOnServer on Android.
func ayuMarkReadOnServer(postbox: Postbox, network: Network, stateManager: AccountStateManager, peerId: PeerId) -> Signal<Void, NoError> {
    return postbox.transaction { transaction -> (Peer, MessageId)? in
        guard let peer = transaction.getPeer(peerId), let topMessageId = transaction.getTopPeerMessageId(peerId: peerId, namespace: Namespaces.Message.Cloud) else {
            return nil
        }
        return (peer, topMessageId)
    }
    |> mapToSignal { data -> Signal<Void, NoError> in
        guard let data = data else {
            return .complete()
        }
        let (peer, topMessageId) = data
        switch peer.id.namespace {
        case Namespaces.Peer.CloudChannel:
            guard let inputChannel = apiInputChannel(peer) else {
                return .complete()
            }
            return network.ayuOriginalRequest(Api.functions.channels.readHistory(channel: inputChannel, maxId: topMessageId.id))
            |> `catch` { _ -> Signal<Api.Bool, NoError> in
                return .complete()
            }
            |> mapToSignal { _ -> Signal<Void, NoError> in
                return .complete()
            }
        case Namespaces.Peer.CloudUser, Namespaces.Peer.CloudGroup:
            guard let inputPeer = apiInputPeer(peer) else {
                return .complete()
            }
            return network.ayuOriginalRequest(Api.functions.messages.readHistory(peer: inputPeer, maxId: topMessageId.id))
            |> map(Optional.init)
            |> `catch` { _ -> Signal<Api.messages.AffectedMessages?, NoError> in
                return .single(nil)
            }
            |> mapToSignal { result -> Signal<Void, NoError> in
                if let result = result {
                    switch result {
                    case let .affectedMessages(affectedMessagesData):
                        stateManager.addUpdateGroups([.updatePts(pts: affectedMessagesData.pts, ptsCount: affectedMessagesData.ptsCount)])
                    }
                }
                return .complete()
            }
        default:
            return .complete()
        }
    }
}

// Ghost mode hides read receipts, but once we reply the chat should look read to the other side.
func ayuMarkReadAfterSendIfNeeded(postbox: Postbox, network: Network, stateManager: AccountStateManager, peerId: PeerId) {
    guard !AyuSettings.sendReadPackets, AyuSettings.markReadAfterSend else {
        return
    }
    let _ = ayuMarkReadOnServer(postbox: postbox, network: network, stateManager: stateManager, peerId: peerId).start()
}
