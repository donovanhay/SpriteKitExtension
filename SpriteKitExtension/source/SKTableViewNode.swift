//
//  SKTableViewNode.swift
//  SpriteKitExtension
//
//  Created by HanHaikun on 2020/1/30.
//  Copyright © 2020 HanHaikun. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

fileprivate enum UIlayer: CGFloat {
    case BackgroundLayer, ForegroundLayer
}


//  MARK: - SKTableViewNode

public class SKTableViewNode: SKNode {
    
    //  MARK: - public
    
    //Default values
    public static let automaticDimension: CGFloat = -1.0
    
    //Delegate
    public weak var delegate: SKTableViewDelegate? {
        didSet {
            configLayout()
        }
    }
    public weak var dataSource: SKTableViewDataSource? {
        didSet {
            reloadData()
        }
    }
    
    //Appearance
    private(set) public var size: CGSize = CGSize.zero
    public var backgroundNode: SKNode? {
        didSet {
            oldValue?.removeFromParent()
            if backgroundNode != nil {
                backgroundNode!.position = CGPoint.zero
                if backgroundNode!.calculateAccumulatedFrame().size.width > 0 {
                    backgroundNode!.xScale = size.width / backgroundNode!.calculateAccumulatedFrame().size.width
                }
                
                if backgroundNode!.calculateAccumulatedFrame().size.height > 0 {
                    backgroundNode!.yScale = size.height / backgroundNode!.calculateAccumulatedFrame().size.height
                }
                backgroundLayer.addChild(backgroundNode!)
            }
        }
    }

    
    public var allowsSelect: Bool = true {
        didSet {
            if !allowsSelect {
                selectIndex = nil
            }
        }
    }   //A Boolean value that determines whether users can select a row
    
    public var allowsScroll: Bool = true    //A Boolean value that determines whether users can scroll the table
    
    //The IndexPath for selected Row
    private(set) public var selectIndex: IndexPath? = nil {
        didSet {
            if oldValue != nil {
                delegate?.tableView(self, didDeselectRowAt: oldValue!)
            }
            if selectIndex != nil {
                delegate?.tableView(self, didSelectRowAt: selectIndex!)
            }
        }
    }
    
    public var indexPathForVisibleRows: [IndexPath] {
        return indexPathForVisibleLayoutItems.filter({ ($0.row != SKTableViewNode.sectionHeaderRowIndex && $0.row != SKTableViewNode.sectionFooterRowIndex) })
    }
    
    
    //  MARK: - public method
    
    //init
    public init(size: CGSize) {
        super.init()
        isUserInteractionEnabled = true
        self.size = size
        
        initLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    //Reload data
    public func reloadData() {
        tableItems.removeAll()
        if dataSource != nil {
            let _sectionCount = dataSource!.numberOfSections(in: self) < 1 ? 1 : dataSource!.numberOfSections(in: self)
            for _sectionIndex in 0..<_sectionCount {
                let _sectionHeader = dataSource!.tableView(self, viewNodeForHeaderInSection: _sectionIndex)
                let _sectionFooter = dataSource!.tableView(self, viewNodeForFooterInSection: _sectionIndex)
                
                var _cells = [SKTableViewNodeCell]()
                let _rowCount = dataSource!.tableView(self, numberOfRowsInSection: _sectionIndex)
                for _rowIndex in 0..<_rowCount {
                    let _cell = dataSource!.tableView(self, cellForRowAt: IndexPath(row: _rowIndex, section: _sectionIndex))
                    _cells.append(_cell)
                }
                
                tableItems.append((sectionHeader: _sectionHeader, cells: _cells, sectionFooter: _sectionFooter))
            }
        }
        initLayoutItems()
    }
    
    
    //Cells and sections
    public func cellForRow(at: IndexPath) -> SKTableViewNodeCell? {
        guard at.section >= 0 && at.section < tableItems.count else {
            return nil
        }
        
        guard at.row >= 0 && at.row < tableItems[at.section].cells.count else {
            return nil
        }
        
        return tableItems[at.section].cells[at.row]
    }
    
    public func sectionHeaderNode(forSection: Int) -> SKTableViewNodeSectionHeadFoot? {
        guard forSection >= 0 && forSection < tableItems.count else {
            return nil
        }
        return tableItems[forSection].sectionHeader
    }
    
    public func sectionFooterNode(forSection: Int) -> SKTableViewNodeSectionHeadFoot? {
        guard forSection >= 0 && forSection < tableItems.count else {
            return nil
        }
        return tableItems[forSection].sectionFooter
    }
    
    public func indexPathForCell(for tableCell: SKTableViewNodeCell) -> IndexPath? {
        for _sectionIndex in 0..<tableItems.count {
            for _rowIndex in 0..<tableItems[_sectionIndex].cells.count {
                if tableCell == tableItems[_sectionIndex].cells[_rowIndex] {
                    return IndexPath(row: _rowIndex, section: _sectionIndex)
                }
            }
        }
        
        return nil
    }
    
    public func indexPathForCell(at: CGPoint) -> IndexPath? {
        guard (at.x >= size.width / -2.0) && (at.x <= size.width / 2.0) else {
            return nil
        }
        
        guard (at.y >= size.height / -2.0) && (at.y <= size.height / 2.0) else {
            return nil
        }
        
        for (_indexPath, _layoutItem) in tableLayoutItems {
            if (at.y - foregroundLayer.position.y >= _layoutItem.position.y - _layoutItem.layoutItemHeight / 2.0) && (at.y - foregroundLayer.position.y <= _layoutItem.position.y + _layoutItem.layoutItemHeight / 2.0) {
                if _indexPath.row >= 0 {
                    return _indexPath
                } else {
                    return nil
                }
            }
        }
        
        return nil
    }
    
    
    //Selecting Cells
    public func selectRow(at: IndexPath, scrollto: Bool) {
        guard allowsSelect else {
            return
        }
        
        guard at.section >= 0 && at.section < tableItems.count else {
            return
        }
        
        guard at.row >= 0 && at.row < tableItems[at.section].cells.count else {
            return
        }
        
        
        //scroll to
        if scrollto && !isLayoutItemVisible(at: at) {
            let layoutItem = layoutItemForTable(at: at)
            
            scrollTable(with: CGVector(dx: 0, dy: layoutItem!.position.y + foregroundLayer.position.y))
        }
        
        selectIndex = at
        
    }
    
    //SpriteKit method
    //Update method, to be called in scene's update.
    public func update(_ currentTime: TimeInterval) {
        if !isUpdateForegroundLayer {
            updateForegroundLayer()
        }
    }
    
    //Private properties for hit test
    private let _maxDistanceCheckSelect: CGFloat = 10.0  //when touch moved, distance between first position and moved position is smaller than this value can be determined Select action
    private var _firstTouchposition: CGPoint = CGPoint.zero
    private var _distancetoFirstTouch: CGFloat = 0.0
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard allowsSelect || allowsScroll else {
            parent?.touchesBegan(touches, with: event)
            return
        }
        _firstTouchposition = touches.first!.location(in: self)
        
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard allowsSelect || allowsScroll else {
            parent?.touchesMoved(touches, with: event)
            return
        }
        
        if _firstTouchposition.distance(to: touches.first!.location(in: self)) > _distancetoFirstTouch  {
            _distancetoFirstTouch = _firstTouchposition.distance(to: touches.first!.location(in: self))
        }
        
        if allowsScroll {
            let touch = touches.first!
            let nowPoint = touch.location(in: self)
            let previousPoint = touch.previousLocation(in: self)
            scrollTable(with: CGVector(dx: nowPoint.x - previousPoint.x, dy: nowPoint.y - previousPoint.y))
        }
        
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard allowsSelect || allowsScroll else {
            parent?.touchesEnded(touches, with: event)
            return
        }
        
        if _distancetoFirstTouch <= _maxDistanceCheckSelect && allowsSelect {
            if let _selectedRow = indexPathForCell(at: _firstTouchposition) {
                selectIndex = _selectedRow
            }
        }
        
    }
    
    //  MARK: - private
    
    //Appearance
    private var backgroundLayer: SKNode = SKNode()
    private var foregroundLayer: SKNode = SKNode()
    
    //LayoutItems
    private var tableLayoutItems = [IndexPath:  SKTableViewNodeLayoutItem]()
    
    //A Sequence of LayoutItems in order of IndexPath
    private var tableLayoutItemsSequence: [(IndexPath, SKTableViewNodeLayoutItem)] {
        return tableLayoutItems.sorted(by: { $0.key < $1.key })
    }
    
    //TableItems
    private var tableItems = [(sectionHeader: SKTableViewNodeSectionHeadFoot?, cells: [SKTableViewNodeCell], sectionFooter: SKTableViewNodeSectionHeadFoot?)]()
    
    //An Array of IndexPath for Visible LayoutItems
    private var indexPathForVisibleLayoutItems: [IndexPath] {
        return tableLayoutItems.filter({ isLayoutItemVisible(at: $0.key) }).keys.sorted(by: { $0 < $1 })
    }
    
    
    //  MARK: - private method
    private func initLayer() {
        backgroundLayer = SKSpriteNode(color: SKColor.clear, size: size)
        backgroundLayer.removeFromParent()
        backgroundLayer.position = CGPoint.zero
        backgroundLayer.zPosition = UIlayer.BackgroundLayer.rawValue
        foregroundLayer.removeFromParent()
        foregroundLayer.position = CGPoint.zero
        foregroundLayer.zPosition = UIlayer.ForegroundLayer.rawValue
        self.addChild(backgroundLayer)
        self.addChild(foregroundLayer)
        
        //init backgroundNode
        backgroundNode = SKSpriteNode(color: #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1), size: size)
        
    }
    
    fileprivate static let sectionHeaderRowIndex = -1
    fileprivate static let sectionFooterRowIndex = Int.max
    
    //Initial the TableLayoutItems
    private func initLayoutItems() {
        tableLayoutItems.removeAll()
        if dataSource != nil {
            let _sectionCount = dataSource!.numberOfSections(in: self) < 1 ? 1 : dataSource!.numberOfSections(in: self)
            for _sectionIndex in 0..<_sectionCount {
                let _sectionHeaderLayout = SKTableViewNodeLayoutItem(type: .sectionHeader, TableView: self)
                _sectionHeaderLayout.contentNode = tableItems[_sectionIndex].sectionHeader
                tableLayoutItems[IndexPath(row: SKTableViewNode.sectionHeaderRowIndex, section: _sectionIndex)] = _sectionHeaderLayout
                
                let _rowCount = dataSource!.tableView(self, numberOfRowsInSection: _sectionIndex)
                for _rowIndex in 0..<_rowCount {
                    let _cellLayout = SKTableViewNodeLayoutItem(type: .tableCell, TableView: self)
                    _cellLayout.contentNode = tableItems[_sectionIndex].cells[_rowIndex]
                    tableLayoutItems[IndexPath(row:_rowIndex, section: _sectionIndex)] = _cellLayout
                }
                
                let _sectionFooterLayout = SKTableViewNodeLayoutItem(type: .sectionFooter, TableView: self)
                _sectionFooterLayout.contentNode = tableItems[_sectionIndex].sectionFooter
                tableLayoutItems[IndexPath(row: SKTableViewNode.sectionFooterRowIndex, section: _sectionIndex)] = _sectionFooterLayout
                
            }
        }
        configLayout()
    }
    
    
    
    //Config the foregroundLayer Layout
    private func configLayout() {
        foregroundLayer.removeAllChildren()
        foregroundLayer.position = CGPoint.zero
        
        var standardPosition = CGPoint(x: 0, y: size.height / 2)
        
        for (_indexpath, _layoutItem) in tableLayoutItemsSequence {
            
            configLayoutItemHeight(at: _indexpath)
            
            _layoutItem.position = CGPoint(x: standardPosition.x, y: standardPosition.y - _layoutItem.layoutItemHeight / 2.0)
            foregroundLayer.addChild(_layoutItem)
            
            standardPosition = CGPoint(x: standardPosition.x, y: standardPosition.y - _layoutItem.layoutItemHeight)
            
        }
        
    }
    
    
    fileprivate static let defaultCellHeight: CGFloat = 44 //when the Height of cell/sectionHeader is automaticDimension, set this value
    
    //config one Layout Item's height which Item is at given indexpath
    private func configLayoutItemHeight(at: IndexPath) {
        guard let layoutItem = layoutItemForTable(at: at) else {
            return
        }
        
        var layoutItemHeightInDelegate: CGFloat
        
        switch layoutItem.itemType {
        case .sectionHeader:
            layoutItemHeightInDelegate = delegate?.tableView(self, heightForHeaderInSection: at.section) ?? SKTableViewNode.automaticDimension
            if layoutItemHeightInDelegate != SKTableViewNode.automaticDimension {
                layoutItem.layoutItemHeight = layoutItemHeightInDelegate
            } else {
                layoutItem.layoutItemHeight = layoutItem.contentNode?.calculateHeight ?? SKTableViewNode.defaultCellHeight
            }
        case .sectionFooter:
            layoutItemHeightInDelegate = delegate?.tableView(self, heightForFooterInSection: at.section) ?? SKTableViewNode.automaticDimension
            if layoutItemHeightInDelegate != SKTableViewNode.automaticDimension {
                layoutItem.layoutItemHeight = layoutItemHeightInDelegate
            } else {
                layoutItem.layoutItemHeight = layoutItem.contentNode?.calculateHeight ?? 0
            }
        case .tableCell:
            layoutItemHeightInDelegate = delegate?.tableView(self, heightForRowAt: at) ?? SKTableViewNode.automaticDimension
            if layoutItemHeightInDelegate != SKTableViewNode.automaticDimension {
                layoutItem.layoutItemHeight = layoutItemHeightInDelegate
            } else {
                layoutItem.layoutItemHeight = layoutItem.contentNode?.calculateHeight ?? SKTableViewNode.defaultCellHeight
            }
//        default:
//            break
        }
        
    }
    
    
    private var isUpdateForegroundLayer: Bool = false   //A Boolean value detemine if the method updateForegroundLayer is calling
    //When one height of Layout Item was changed, the whole foreground will be changed, update the layout Items' layoutItemHeight and position lower than the Top VisibleLayoutItem.
    private func updateForegroundLayer() {
        guard let topVisibleItemIndex = indexPathForVisibleLayoutItems.first else {
            return
        }
        
        isUpdateForegroundLayer = true
        
        var startPosition = CGPoint(x: 0.0, y: tableLayoutItems[topVisibleItemIndex]!.position.y + tableLayoutItems[topVisibleItemIndex]!.layoutItemHeight / 2.0)
        
        let updateLayoutItems = tableLayoutItemsSequence.filter({ $0.0 >= topVisibleItemIndex})
        
        for (_indexpath, _layoutItem) in updateLayoutItems {
            
            configLayoutItemHeight(at: _indexpath)
            
            _layoutItem.position = CGPoint(x: startPosition.x, y: startPosition.y - _layoutItem.layoutItemHeight / 2.0)
            
            startPosition = CGPoint(x: startPosition.x, y: startPosition.y - _layoutItem.layoutItemHeight)
            
        }
        
        isUpdateForegroundLayer = false
        
    }
    
    
    //Scroll Table
    private func scrollTable(with: CGVector) {
        var _targetPosition = foregroundLayer.position.move(by: CGVector(dx: 0, dy: with.dy))
        if _targetPosition.y < 0 {
            _targetPosition = CGPoint(x: 0, y: 0)
        }
        
        let _layoutItemsTotalHeight = tableLayoutItems.reduce(0.0) { $0 + $1.value.layoutItemHeight }
        let _bottomPositiony = (_layoutItemsTotalHeight - size.height >= 0) ? _layoutItemsTotalHeight - size.height : 0
        if _targetPosition.y > _bottomPositiony {
            _targetPosition = CGPoint(x: 0, y: _bottomPositiony)
        }
        
        foregroundLayer.position = _targetPosition
    }
    
    
    private func isLayoutItemVisible(at: IndexPath) -> Bool {
        guard let layoutItem = layoutItemForTable(at: at) else {
            return false
        }
        
        if ((layoutItem.position.y - layoutItem.layoutItemHeight / 2.0) < (size.height / 2.0 - foregroundLayer.position.y)) {
            if ((layoutItem.position.y + layoutItem.layoutItemHeight / 2.0) > (0 - size.height / 2.0 - foregroundLayer.position.y)) {
                return true
            }
        }
        
        return false
    }
    
    private func layoutItemForTable(at: IndexPath) -> SKTableViewNodeLayoutItem? {
        return tableLayoutItems[at]
    }
    
}


//  MARK: - SKTableViewNodeLayoutItem

fileprivate class SKTableViewNodeLayoutItem: SKNode {
    enum LayoutType: Int {
        case sectionHeader, tableCell, sectionFooter
    }
    
    private(set) fileprivate weak var tableview: SKTableViewNode?
    
    var itemType: LayoutType
    var layoutItemHeight: CGFloat = SKTableViewNode.automaticDimension {
        didSet {
            if (oldValue != layoutItemHeight && size != nil) {
//                if itemType == .tableCell {print(layoutItemHeight)}
                contentNode?.setScaleTo(size!)
            }
        }
    }
    private var isVisibleOnTable: Bool = false
    
    var size: CGSize? {
        if tableview != nil {
            return CGSize(width: tableview!.size.width, height: layoutItemHeight)
        }
        return nil
    }
    
    var contentNode: SKTableViewNodeComponent? {
        didSet {
            oldValue?.removeFromParent()
            if contentNode != nil {
                contentNode?.position = CGPoint.zero
                self.addChild(contentNode!)
            }
            //layoutItemHeight = contentNode?.calculateHeight ?? SKTableViewNode.automaticDimension
        }
    }
    
    public init(type: LayoutType, TableView: SKTableViewNode) {
        self.itemType = type
        self.tableview = TableView
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


//  MARK: - SKTableViewNodeComponent

public class SKTableViewNodeComponent: SKNode {
    private(set) public weak var tableview: SKTableViewNode?
    
    fileprivate var calculateHeight: CGFloat {
        return calculateAccumulatedFrame().size.height
    }
    
    fileprivate var backgroundLayer: SKNode = SKNode()
    fileprivate var foregroundLayer: SKNode = SKNode()
    
    public var backgroundNode: SKNode? {
        didSet {
            oldValue?.removeFromParent()
            if backgroundNode != nil {
                backgroundNode!.position = CGPoint.zero
                backgroundLayer.addChild(backgroundNode!)
            }
        }
    }
    
    public var size: CGSize? {
        if tableview != nil {
            return CGSize(width: tableview!.size.width, height: calculateHeight)
        }
        return nil
    }
    
    public init(TableView: SKTableViewNode) {
        super.init()
        
        tableview = TableView
        initLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initLayer() {
        backgroundLayer = SKSpriteNode(color: SKColor.clear, size: size!)
        backgroundLayer.removeFromParent()
        backgroundLayer.position = CGPoint.zero
        backgroundLayer.zPosition = UIlayer.BackgroundLayer.rawValue
        foregroundLayer.removeFromParent()
        foregroundLayer.position = CGPoint.zero
        foregroundLayer.zPosition = UIlayer.ForegroundLayer.rawValue
        self.addChild(backgroundLayer)
        self.addChild(foregroundLayer)
    }
    
    fileprivate func setScaleTo(_ toSize: CGSize) {
        guard backgroundNode != nil else {
            return
        }
        
        if backgroundNode!.calculateAccumulatedFrame().size.width > 0 {
            backgroundNode!.xScale = toSize.width / backgroundNode!.calculateAccumulatedFrame().size.width
        }
        
        if backgroundNode!.calculateAccumulatedFrame().size.height > 0 {
            backgroundNode!.yScale = toSize.height / backgroundNode!.calculateAccumulatedFrame().size.height
        }
    }
}


//  MARK: - SKTableViewNodeCell

public class SKTableViewNodeCell: SKTableViewNodeComponent {
    
    fileprivate override var calculateHeight: CGFloat {
        if self.style == .label {
            return CGFloat.maximum(CGFloat.maximum(labelNode?.calculateAccumulatedFrame().size.height ?? 0 + 20, SKTableViewNode.defaultCellHeight), super.calculateHeight)
        } else {
            return super.calculateHeight
        }
    }
    
    public enum CellStyle: Int {
        case label, split, custom
    }
    
    private(set) public var style: CellStyle = .custom
    
    
    private(set) public var labelNode: SKLabelNode?
    private(set) public var leftNode: SKNode?
    private(set) public var rightNode: SKNode?
    private(set) public var contentNode: SKNode?
    
    
    public init(TableView: SKTableViewNode, style: SKTableViewNodeCell.CellStyle = .custom) {
        super.init(TableView: TableView)
        self.style = style
        initLayout()
        
        //init backgroundNode
        backgroundNode = SKSpriteNode(color: #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), size: size!)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initLayout() {
        
        switch style {
        case .label:
            labelNode = SKLabelNode(fontNamed: "PingFangSC-Light")
            labelNode!.fontSize = 17
            labelNode!.fontColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            labelNode!.horizontalAlignmentMode = .left
            labelNode!.verticalAlignmentMode = .center
            labelNode!.lineBreakMode = .byTruncatingMiddle
            labelNode!.preferredMaxLayoutWidth = size!.width - 40
            labelNode!.numberOfLines = 1
            labelNode!.position = CGPoint(x: 20 - size!.width / 2.0, y: 0)
            foregroundLayer.addChild(labelNode!)
        case .split:
            leftNode = SKNode()
            rightNode = SKNode()
            leftNode?.position = CGPoint(x: 0 - size!.width / 2.0, y: 0)
            rightNode?.position = CGPoint(x: size!.width / 2.0, y: 0)
            foregroundLayer.addChild(leftNode!)
            foregroundLayer.addChild(rightNode!)
        case .custom:
            contentNode = SKNode()
            contentNode!.position = CGPoint.zero
            foregroundLayer.addChild(contentNode!)
//        default:
//            break
        }
        
    }
    
    public func setSplitWidthAbsolute(left: CGFloat, right: CGFloat) {
        if style == .split {
            guard left + right <= size!.width else {
                return
            }
            
            leftNode?.position = CGPoint(x: left / 2.0 - size!.width / 2.0, y: 0)
            rightNode?.position = CGPoint(x: size!.width / 2.0 - right / 2.0, y: 0)
        }
        
    }
    
    public func setSplitWidthPercentage(left: CGFloat, right: CGFloat) {
        if style == .split {
            guard left + right <= 1 else {
                return
            }
            
            leftNode?.position = CGPoint(x: size!.width * (left - 1) / 2.0, y: 0)
            rightNode?.position = CGPoint(x: size!.width * (1 - right) / 2.0, y: 0)
        }
    }
    
}


//  MARK: - SKTableViewNodeHeadFoot

public class SKTableViewNodeSectionHeadFoot: SKTableViewNodeComponent {
    fileprivate override var calculateHeight: CGFloat {
        if self.style == .label {
            return CGFloat.maximum(CGFloat.maximum(labelNode?.calculateAccumulatedFrame().size.height ?? 0 + 20, SKTableViewNode.defaultCellHeight), super.calculateHeight)
        } else {
            return super.calculateHeight
        }
    }
    
    public enum SectionStyle: Int {
        case label, custom
    }
    
    private(set) public var style: SectionStyle = .custom
    
    private(set) public var labelNode: SKLabelNode?
    private(set) public var contentNode: SKNode?
    
    public init(TableView: SKTableViewNode, style: SKTableViewNodeSectionHeadFoot.SectionStyle = .custom) {
        super.init(TableView: TableView)
        self.style = style
        initLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initLayout() {
        
        switch style {
        case .label:
            labelNode = SKLabelNode(fontNamed: "PingFangSC-Semibold")
            labelNode!.fontSize = 17
            labelNode!.fontColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            labelNode!.horizontalAlignmentMode = .left
            labelNode!.verticalAlignmentMode = .center
            labelNode!.lineBreakMode = .byTruncatingMiddle
            labelNode!.preferredMaxLayoutWidth = size!.width - 40
            labelNode!.numberOfLines = 1
            labelNode!.position = CGPoint(x: 20 - size!.width / 2.0, y: 0)
            foregroundLayer.addChild(labelNode!)
        case .custom:
            contentNode = SKNode()
            contentNode!.position = CGPoint.zero
            foregroundLayer.addChild(contentNode!)
//        default:
//            break
        }
        
    }
}


//  MARK: - SKTableViewDelegate

public protocol SKTableViewDelegate: class {
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, heightForRowAt indexPath: IndexPath) -> CGFloat
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, heightForHeaderInSection section: Int) -> CGFloat
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, heightForFooterInSection section: Int) -> CGFloat
    
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    
    //  @available(iOS 3.0, *)
    //  func tableView(_ tableView: SKTableViewNode, willDeselectRowAt indexPath: IndexPath) -> IndexPath?
    
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, didSelectRowAt indexPath: IndexPath)
    
    @available(iOS 3.0, *)
    func tableView(_ tableView: SKTableViewNode, didDeselectRowAt indexPath: IndexPath)
    
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, indentationLevelForRowAt indexPath: IndexPath) -> Int
    
}

public extension SKTableViewDelegate {
    func tableView(_ tableView: SKTableViewNode, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SKTableViewNode.automaticDimension
    }
    
    func tableView(_ tableView: SKTableViewNode, heightForHeaderInSection section: Int) -> CGFloat {
        return SKTableViewNode.automaticDimension
    }
    
    func tableView(_ tableView: SKTableViewNode, heightForFooterInSection section: Int) -> CGFloat {
        return SKTableViewNode.automaticDimension
    }
    
    func tableView(_ tableView: SKTableViewNode, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: SKTableViewNode, didDeselectRowAt indexPath: IndexPath) {
        
    }
}


//  MARK: - SKTableViewDataSource

public protocol SKTableViewDataSource: class {
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, numberOfRowsInSection section: Int) -> Int
    
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, cellForRowAt indexPath: IndexPath) -> SKTableViewNodeCell
    
    
    @available(iOS 2.0, *)
    func numberOfSections(in tableView: SKTableViewNode) -> Int // Default is 1 if not implemented
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, viewNodeForHeaderInSection section: Int) -> SKTableViewNodeSectionHeadFoot?
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, viewNodeForFooterInSection section: Int) -> SKTableViewNodeSectionHeadFoot?
    
    
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, titleForHeaderInSection section: Int) -> String? // fixed font style. use custom view (UILabel) if you want something different
    
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, titleForFooterInSection section: Int) -> String?
    
    
    // Editing
    
    // Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, canEditRowAt indexPath: IndexPath) -> Bool
    
    
    // Moving/reordering
    
    // Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, canMoveRowAt indexPath: IndexPath) -> Bool
    
    
    // Index
    
    //  @available(iOS 2.0, *)
    //  func sectionIndexTitles(for tableView: SKTableViewNode) -> [String]? // return list of section titles to display in section index view (e.g. "ABCD...Z#")
    
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, sectionForSectionIndexTitle title: String, at index: Int) -> Int // tell table which section corresponds to section title/index (e.g. "B",1))
    
    
    // Data manipulation - insert and delete support
    
    // After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
    // Not called for edit actions using UITableViewRowAction - the action's handler will be invoked instead
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    
    
    // Data manipulation - reorder / moving support
    
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    
}

public extension SKTableViewDataSource {
    func numberOfSections(in tableView: SKTableViewNode) -> Int {
        return 1
    }
    
    func tableView(_ tableView: SKTableViewNode, viewNodeForHeaderInSection section: Int) -> SKTableViewNodeSectionHeadFoot? {
        return nil
    }
    
    func tableView(_ tableView: SKTableViewNode, viewNodeForFooterInSection section: Int) -> SKTableViewNodeSectionHeadFoot? {
        return nil
    }
    
}
