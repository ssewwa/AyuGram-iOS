import Foundation
import Postbox

// Marks a message the server told us was deleted. The message is kept in Postbox
// instead of being removed (AyuGram "save deleted messages").
public final class AyuDeletedMessageAttribute: MessageAttribute {
    public let date: Int32

    public init(date: Int32) {
        self.date = date
    }

    required public init(decoder: PostboxDecoder) {
        self.date = decoder.decodeInt32ForKey("d", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.date, forKey: "d")
    }
}

public extension Message {
    var ayuDeletedDate: Int32? {
        for attribute in self.attributes {
            if let attribute = attribute as? AyuDeletedMessageAttribute {
                return attribute.date
            }
        }
        return nil
    }
}

public extension EngineMessage {
    var ayuDeletedDate: Int32? {
        return self._asMessage().ayuDeletedDate
    }
}

// Called while replaying server deletions. Marks the messages we keep and returns the ids
// that still have to be deleted for real.
func ayuKeepDeletedMessages(transaction: Transaction, ids: [MessageId]) -> [MessageId] {
    guard AyuSettings.saveDeletedMessages else {
        return ids
    }
    let date = Int32(Date().timeIntervalSince1970)
    var remaining: [MessageId] = []
    for id in ids {
        guard ayuShouldKeepDeletedMessage(id: id), let message = transaction.getMessage(id) else {
            remaining.append(id)
            continue
        }
        if message.ayuDeletedDate != nil {
            continue
        }
        transaction.updateMessage(id, update: { currentMessage in
            var storeForwardInfo: StoreMessageForwardInfo?
            if let forwardInfo = currentMessage.forwardInfo {
                storeForwardInfo = StoreMessageForwardInfo(authorId: forwardInfo.author?.id, sourceId: forwardInfo.source?.id, sourceMessageId: forwardInfo.sourceMessageId, date: forwardInfo.date, authorSignature: forwardInfo.authorSignature, psaType: forwardInfo.psaType, flags: forwardInfo.flags)
            }
            var attributes = currentMessage.attributes
            attributes.append(AyuDeletedMessageAttribute(date: date))
            return .update(StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId: currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: currentMessage.text, attributes: attributes, media: currentMessage.media))
        })
    }
    return remaining
}

// Same for deletions that arrive with global ids (private chats and basic groups).
func ayuKeepDeletedMessages(transaction: Transaction, globalIds: [Int32]) -> [Int32] {
    guard AyuSettings.saveDeletedMessages else {
        return globalIds
    }
    var remaining: [Int32] = []
    for globalId in globalIds {
        guard let id = transaction.messageIdsForGlobalIds([globalId]).first else {
            remaining.append(globalId)
            continue
        }
        if !ayuKeepDeletedMessages(transaction: transaction, ids: [id]).isEmpty {
            remaining.append(globalId)
        }
    }
    return remaining
}

private func ayuShouldKeepDeletedMessage(id: MessageId) -> Bool {
    // Only regular cloud messages: scheduled, quick reply and ephemeral ones are deleted as usual.
    guard id.namespace == Namespaces.Message.Cloud else {
        return false
    }
    switch id.peerId.namespace {
    case Namespaces.Peer.CloudUser, Namespaces.Peer.CloudGroup, Namespaces.Peer.CloudChannel:
        return true
    default:
        return false
    }
}
