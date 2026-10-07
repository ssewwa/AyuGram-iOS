import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

// Small declarative layer over ItemListController for the exteraGram / AyuGram screens.
// Same layout as the Android clients: a hero header, "Категории" that open sub-pages, "Ссылки".

enum ExteraRow {
    case hero(name: String, version: String, icon: UIImage?)
    case header(String)
    case nav(title: String, symbol: String, open: () -> ViewController?)
    case link(title: String, symbol: String, label: String, url: String)
    case toggle(title: String, symbol: String?, value: Bool, update: (Bool) -> Void)
    case action(title: String, destructive: Bool, enabled: Bool, perform: () -> Void)
    case input(placeholder: String, text: String, update: (String) -> Void)
    case note(String)
}

private struct ExteraEntry: ItemListNodeEntry {
    let section: ItemListSectionId
    let stableId: Int
    let signature: String
    let row: ExteraRow
    let environment: ExteraEnvironment

    static func ==(lhs: ExteraEntry, rhs: ExteraEntry) -> Bool {
        return lhs.stableId == rhs.stableId && lhs.signature == rhs.signature
    }

    static func <(lhs: ExteraEntry, rhs: ExteraEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let env = self.environment
        let accent = presentationData.theme.list.itemAccentColor
        switch self.row {
        case let .hero(name, version, icon):
            return ExteraHeroItem(presentationData: presentationData, name: name, version: version, icon: icon, sectionId: self.section)
        case let .header(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text.uppercased(), sectionId: self.section)
        case let .nav(title, symbol, open):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: exteraSymbolIcon(symbol, color: accent), title: title, label: "", sectionId: self.section, style: .blocks, action: {
                if let controller = open() {
                    env.push(controller)
                }
            })
        case let .link(title, symbol, label, url):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: exteraSymbolIcon(symbol, color: accent), title: title, label: label, labelStyle: .coloredText(accent), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                env.openUrl(url)
            })
        case let .toggle(title, symbol, value, update):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, icon: symbol.flatMap { exteraSymbolIcon($0, color: accent) }, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                update(value)
                env.refresh()
            })
        case let .action(title, destructive, enabled, perform):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: !enabled ? .disabled : (destructive ? .destructive : .generic), alignment: .natural, sectionId: self.section, style: .blocks, action: {
                perform()
            })
        case let .input(placeholder, text, update):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(string: ""), text: text, placeholder: placeholder, type: .regular(capitalization: true, autocorrection: false), spacing: 0.0, clearType: .always, maxLength: 32, sectionId: self.section, textUpdated: { updated in
                update(updated)
            }, action: {})
        case let .note(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func signature(of row: ExteraRow) -> String {
    switch row {
    case let .hero(name, version, _): return "hero\(name)\(version)"
    case let .header(text): return "h\(text)"
    case let .nav(title, _, _): return "n\(title)"
    case let .link(title, _, label, _): return "l\(title)\(label)"
    case let .toggle(title, _, value, _): return "t\(title)\(value)"
    case let .action(title, destructive, enabled, _): return "a\(title)\(destructive)\(enabled)"
    case let .input(placeholder, _, _): return "i\(placeholder)"
    case let .note(text): return "x\(text)"
    }
}

final class ExteraEnvironment {
    let context: AccountContext
    weak var controller: ViewController?
    let refreshPromise = ValuePromise<Bool>(true, ignoreRepeated: false)

    init(context: AccountContext) {
        self.context = context
    }

    func refresh() {
        self.refreshPromise.set(true)
    }

    func push(_ controller: ViewController) {
        self.controller?.push(controller)
    }

    func present(_ controller: ViewController) {
        self.controller?.present(controller, in: .window(.root))
    }

    func openUrl(_ url: String) {
        let context = self.context
        context.sharedContext.openExternalUrl(context: context, urlContext: .generic, url: url, forceExternal: !url.hasPrefix("https://t.me/"), presentationData: context.sharedContext.currentPresentationData.with { $0 }, navigationController: self.controller?.navigationController as? NavigationController, dismissInput: {})
    }
}

// Builds a settings page. `sections` is re-evaluated on every refresh, so it can read UserDefaults directly.
func exteraPageController(context: AccountContext, title: String, sections: @escaping (ExteraEnvironment) -> [[ExteraRow]]) -> ViewController {
    let env = ExteraEnvironment(context: context)

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, env.refreshPromise.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let presentationData = presentationData.withUpdated(theme: presentationData.theme.withModalBlocksBackground())

        var entries: [ExteraEntry] = []
        for (sectionIndex, rows) in sections(env).enumerated() {
            for row in rows {
                entries.append(ExteraEntry(section: ItemListSectionId(sectionIndex), stableId: entries.count, signature: signature(of: row), row: row, environment: env))
            }
        }

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, animateChanges: true)
        return (controllerState, (listState, ()))
    }

    let controller = ItemListController(context: context, state: signal)
    env.controller = controller
    return controller
}

func exteraAppVersion() -> String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? ""
    let build = info?["CFBundleVersion"] as? String ?? ""
    return build.isEmpty ? version : "\(version) (\(build))"
}

// SF Symbol drawn into the 29pt slot ItemList uses for row icons, tinted with the accent like the Android outline icons.
func exteraSymbolIcon(_ name: String, color: UIColor) -> UIImage? {
    let config = UIImage.SymbolConfiguration(pointSize: 20.0, weight: .regular)
    guard let symbol = UIImage(systemName: name, withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal) else {
        return nil
    }
    let size = CGSize(width: 29.0, height: 29.0)
    return UIGraphicsImageRenderer(size: size).image { _ in
        symbol.draw(at: CGPoint(x: (size.width - symbol.size.width) / 2.0, y: (size.height - symbol.size.height) / 2.0))
    }
}

// Rounded app tile with a glyph, like the header on Android: dark tile tinted with the accent, light glyph.
func exteraHeroIcon(glyph: (CGRect) -> UIBezierPath, accent: UIColor) -> UIImage {
    let size = CGSize(width: 104.0, height: 104.0)
    return UIGraphicsImageRenderer(size: size).image { ctx in
        let rect = CGRect(origin: .zero, size: size)
        UIColor(white: 0.12, alpha: 1.0).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 30.0).fill()
        accent.withAlphaComponent(0.28).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 30.0).fill()
        accent.mixedWith(.white, alpha: 0.55).setFill()
        glyph(rect).fill()
    }
}

let exteraGlyph: (CGRect) -> UIBezierPath = { r in
    // exteraGram arrow
    let p = UIBezierPath()
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + r.width * x, y: r.minY + r.height * y) }
    p.move(to: pt(0.27, 0.47))
    p.addLine(to: pt(0.74, 0.27))
    p.addLine(to: pt(0.56, 0.74))
    p.addLine(to: pt(0.49, 0.53))
    p.close()
    return p
}

let ayuGlyph: (CGRect) -> UIBezierPath = { r in
    // AyuGram "A": two blades and a narrow keel
    let p = UIBezierPath()
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + r.width * x, y: r.minY + r.height * y) }
    p.move(to: pt(0.25, 0.66)); p.addLine(to: pt(0.46, 0.27)); p.addLine(to: pt(0.43, 0.66)); p.close()
    p.move(to: pt(0.75, 0.66)); p.addLine(to: pt(0.54, 0.27)); p.addLine(to: pt(0.57, 0.66)); p.close()
    p.move(to: pt(0.48, 0.44)); p.addLine(to: pt(0.52, 0.44)); p.addLine(to: pt(0.52, 0.70)); p.addLine(to: pt(0.50, 0.75)); p.addLine(to: pt(0.48, 0.70)); p.close()
    return p
}

// MARK: - Hero header (icon, name, version)

final class ExteraHeroItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let name: String
    let version: String
    let icon: UIImage?
    let sectionId: ItemListSectionId
    let isAlwaysPlain: Bool = true
    let tag: ItemListItemTag? = nil
    let requestsNoInset: Bool = false
    let selectable: Bool = false

    init(presentationData: ItemListPresentationData, name: String, version: String, icon: UIImage?, sectionId: ItemListSectionId) {
        self.presentationData = presentationData
        self.name = name
        self.version = version
        self.icon = icon
        self.sectionId = sectionId
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        Queue.mainQueue().async {
            let node = ExteraHeroItemNode()
            let layout = node.update(item: self, params: params)
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            completion(node, {
                return (nil, { _ in })
            })
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? ExteraHeroItemNode else {
                return
            }
            let layout = nodeValue.update(item: self, params: params)
            completion(layout, { _ in })
        }
    }
}

final class ExteraHeroItemNode: ListViewItemNode {
    private let iconNode = ASImageNode()
    private let nameNode = ImmediateTextNode()
    private let versionNode = ImmediateTextNode()

    init() {
        super.init(layerBacked: false)
        self.iconNode.displaysAsynchronously = false
        self.addSubnode(self.iconNode)
        self.addSubnode(self.nameNode)
        self.addSubnode(self.versionNode)
    }

    func update(item: ExteraHeroItem, params: ListViewItemLayoutParams) -> ListViewItemNodeLayout {
        let theme = item.presentationData.theme
        let width = params.width
        let iconSize: CGFloat = 104.0

        self.iconNode.image = item.icon
        self.iconNode.frame = CGRect(x: floor((width - iconSize) / 2.0), y: 16.0, width: iconSize, height: iconSize)

        self.nameNode.attributedText = NSAttributedString(string: item.name, font: Font.bold(26.0), textColor: theme.list.itemPrimaryTextColor)
        let nameSize = self.nameNode.updateLayout(CGSize(width: width - 32.0, height: 40.0))
        self.nameNode.frame = CGRect(x: floor((width - nameSize.width) / 2.0), y: self.iconNode.frame.maxY + 18.0, width: nameSize.width, height: nameSize.height)

        self.versionNode.attributedText = NSAttributedString(string: item.version, font: Font.medium(17.0), textColor: theme.list.itemSecondaryTextColor)
        let versionSize = self.versionNode.updateLayout(CGSize(width: width - 32.0, height: 30.0))
        self.versionNode.frame = CGRect(x: floor((width - versionSize.width) / 2.0), y: self.nameNode.frame.maxY + 4.0, width: versionSize.width, height: versionSize.height)

        let height = self.versionNode.frame.maxY + 8.0
        let layout = ListViewItemNodeLayout(contentSize: CGSize(width: width, height: height), insets: UIEdgeInsets())
        self.contentSize = layout.contentSize
        self.insets = layout.insets
        return layout
    }
}
