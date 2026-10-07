import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData

// exteraGram: shown instead of the conversation when a chat protected with Face ID is long-pressed.
final class ExteraLockedChatPreviewController: ViewController {
    private let presentationData: PresentationData
    private var textNode: ImmediateTextNode?

    init(presentationData: PresentationData) {
        self.presentationData = presentationData

        super.init(navigationBarPresentationData: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadDisplayNode() {
        self.displayNode = ASDisplayNode()
        self.displayNode.backgroundColor = self.presentationData.theme.list.plainBackgroundColor

        let textNode = ImmediateTextNode()
        textNode.attributedText = NSAttributedString(string: "🔒\nЧат защищён", font: Font.medium(17.0), textColor: self.presentationData.theme.list.itemSecondaryTextColor)
        textNode.textAlignment = .center
        textNode.maximumNumberOfLines = 2
        self.displayNode.addSubnode(textNode)
        self.textNode = textNode

        self.displayNodeDidLoad()
    }

    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        if let textNode = self.textNode {
            let textSize = textNode.updateLayout(CGSize(width: layout.size.width - 32.0, height: layout.size.height))
            transition.updateFrame(node: textNode, frame: CGRect(origin: CGPoint(x: floor((layout.size.width - textSize.width) / 2.0), y: floor((layout.size.height - textSize.height) / 2.0)), size: textSize))
        }
    }
}
