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
    private(set) public var size: CGSize!
    public var backgroundNode: SKNode? {
        didSet {
            oldValue?.removeFromParent()
            if backgroundNode != nil {
                backgroundLayer.addChild(backgroundNode!)
            }
        }
    }
//    public var tableHeaderNode: SKTableViewNodeHeadFoot?
//    public var tableFooterNode: SKTableViewNodeHeadFoot?
    
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
        return tableLayoutItems.filter({ ($0.index.row >= 0 && isLayoutItemVisible(at: $0.index)) })
            .map({ $0.index })
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
        initLayout()
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
        
        selectIndex = at
        
    }
    
    //SpriteKit method
    //Update method, to be called in scene's update.
    public func update(_ currentTime: TimeInterval) {
        
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
    private var tableLayoutItems = [(index: IndexPath, layoutItem: SKTableViewNodeLayoutItem)]()
    
    //TableItems
    private var tableItems = [(sectionHeader: SKTableViewNodeSectionHeadFoot?, cells: [SKTableViewNodeCell], sectionFooter: SKTableViewNodeSectionHeadFoot?)]()
    
    
    
    //  MARK: - private method
    private func initLayer() {
        backgroundLayer.removeFromParent()
        backgroundLayer.position = CGPoint.zero
        backgroundLayer.zPosition = UIlayer.BackgroundLayer.rawValue
        foregroundLayer.removeFromParent()
        foregroundLayer.position = CGPoint.zero
        foregroundLayer.zPosition = UIlayer.ForegroundLayer.rawValue
        self.addChild(backgroundLayer)
        self.addChild(foregroundLayer)
    }
    
    
    //Initial the TableLayoutItems
    private func initLayout() {
        tableLayoutItems.removeAll()
        if dataSource != nil {
            let _sectionCount = dataSource!.numberOfSections(in: self) < 1 ? 1 : dataSource!.numberOfSections(in: self)
            for _sectionIndex in 0..<_sectionCount {
                let _sectionHeaderLayout = SKTableViewNodeLayoutItem(type: .sectionHeader, index: IndexPath(row: -1, section: _sectionIndex))
                _sectionHeaderLayout.contentNode = tableItems[_sectionIndex].sectionHeader
                tableLayoutItems.append((index: IndexPath(row: -1, section: _sectionIndex), layoutItem: _sectionHeaderLayout))
                
                let _rowCount = dataSource!.tableView(self, numberOfRowsInSection: _sectionIndex)
                for _rowIndex in 0..<_rowCount {
                    let _cellLayout = SKTableViewNodeLayoutItem(type: .tableCell, index: IndexPath(row: _rowIndex, section: _sectionIndex))
                    _cellLayout.contentNode = tableItems[_sectionIndex].cells[_rowIndex]
                    tableLayoutItems.append((index: IndexPath(row: _rowIndex, section: _sectionIndex), layoutItem: _cellLayout))
                }
                
                let _sectionFooterLayout = SKTableViewNodeLayoutItem(type: .sectionFooter, index: IndexPath(row: -2, section: _sectionIndex))
                _sectionFooterLayout.contentNode = tableItems[_sectionIndex].sectionFooter
                tableLayoutItems.append((index: IndexPath(row: -2, section: _sectionIndex), layoutItem: _sectionFooterLayout))
                
            }
        }
        configLayout()
    }
    
    
    //Config the foregroundLayer Layout
    private func configLayout() {
        foregroundLayer.removeAllChildren()
        foregroundLayer.position = CGPoint.zero
        
        var standardPosition = CGPoint(x: 0, y: size.height / 2)
        
        for (_indexpath, _layoutItem) in tableLayoutItems {
            switch _layoutItem.itemType {
            case .sectionHeader:
                _layoutItem.layoutItemHeight = delegate?.tableView(self, heightForHeaderInSection: _indexpath.section) ?? SKTableViewNode.automaticDimension
                if _layoutItem.layoutItemHeight == SKTableViewNode.automaticDimension {
                    _layoutItem.layoutItemHeight = _layoutItem.contentNode?.calculateHeight ?? 20
                }
            case .sectionFooter:
                _layoutItem.layoutItemHeight = delegate?.tableView(self, heightForFooterInSection: _indexpath.section) ?? SKTableViewNode.automaticDimension
                if _layoutItem.layoutItemHeight == SKTableViewNode.automaticDimension {
                    _layoutItem.layoutItemHeight = _layoutItem.contentNode?.calculateHeight ?? 0
                }
            case .tableCell:
                _layoutItem.layoutItemHeight = delegate?.tableView(self, heightForRowAt: _indexpath) ?? SKTableViewNode.automaticDimension
                if _layoutItem.layoutItemHeight == SKTableViewNode.automaticDimension {
                    _layoutItem.layoutItemHeight = _layoutItem.contentNode?.calculateHeight ?? 20
                }
            default:
                break
            }
            _layoutItem.position = CGPoint(x: standardPosition.x, y: standardPosition.y - _layoutItem.layoutItemHeight / 2.0)
            foregroundLayer.addChild(_layoutItem)
            
            standardPosition = CGPoint(x: standardPosition.x, y: standardPosition.y - _layoutItem.layoutItemHeight)
        }
        
    }
    
    //abandon
    private func initForgroundLayer() {
        foregroundLayer.removeAllChildren()
        
        var standardPosition = CGPoint(x: 0, y: size.height / 2)
        
        for _sectionIndex in 0..<tableItems.count {
            let _section = tableItems[_sectionIndex]
            
            //config section Header begin
            var _sectionHeaderHeight = delegate?.tableView(self, heightForHeaderInSection: _sectionIndex) ?? SKTableViewNode.automaticDimension
            if _sectionHeaderHeight == SKTableViewNode.automaticDimension {
                _sectionHeaderHeight = _section.sectionHeader?.calculateHeight ?? 20
            }
            if _section.sectionHeader != nil {
                //config section header position
                _section.sectionHeader!.position = CGPoint(x: standardPosition.x, y: standardPosition.y - _sectionHeaderHeight / 2.0)
                //add section header on foregroundLayer
                foregroundLayer.addChild(_section.sectionHeader!)
            }
            standardPosition = CGPoint(x: standardPosition.x, y: standardPosition.y - _sectionHeaderHeight)
            //config section Header end
            
            //config rows begin
            for _rowIndex in 0..<_section.cells.count {
                let _cell = _section.cells[_rowIndex]
                
                var _cellHeight = delegate?.tableView(self, heightForRowAt: IndexPath(row: _rowIndex, section: _sectionIndex)) ?? SKTableViewNode.automaticDimension
                if _cellHeight == SKTableViewNode.automaticDimension {
                    _cellHeight = _cell.calculateHeight
                }
                //config cell position
                _cell.position = CGPoint(x: standardPosition.x, y: standardPosition.y - _cellHeight / 2.0)
                //add cell on foregroundLayer
                foregroundLayer.addChild(_cell)
                
                standardPosition = CGPoint(x: standardPosition.x, y: standardPosition.y - _cellHeight)
            }
            //config rows end
            
            //config section Footer begin
            var _sectionFooterHeight = delegate?.tableView(self, heightForFooterInSection: _sectionIndex) ?? SKTableViewNode.automaticDimension
            if _sectionFooterHeight == SKTableViewNode.automaticDimension {
                _sectionFooterHeight = _section.sectionFooter?.calculateHeight ?? 0
            }
            if _section.sectionFooter != nil {
                //config section footer position
                _section.sectionFooter!.position = CGPoint(x: standardPosition.x, y: standardPosition.y - _sectionFooterHeight / 2.0)
                //add section footer on foregroundLayer
                foregroundLayer.addChild(_section.sectionFooter!)
            }
            standardPosition = CGPoint(x: standardPosition.x, y: standardPosition.y - _sectionFooterHeight)
            //config section Footer end
        }
    }
    
    
    //Scroll Table
    private func scrollTable(with: CGVector) {
        var _targetPosition = foregroundLayer.position.move(by: CGVector(dx: 0, dy: with.dy))
        if _targetPosition.y < 0 {
            _targetPosition = CGPoint(x: 0, y: 0)
        }
        
        let _layoutItemsTotalHeight = tableLayoutItems.reduce(0.0) { $0 + $1.layoutItem.layoutItemHeight }
        if _targetPosition.y > _layoutItemsTotalHeight - size.height {
            _targetPosition = CGPoint(x: 0, y: _layoutItemsTotalHeight - size.height)
        }
        
        foregroundLayer.position = _targetPosition
    }
    
    
    //
    private func updateForegroundLayer() {
        
    }
    
    
    private func isLayoutItemVisible(at: IndexPath) -> Bool {
        guard at.section >= 0 && at.section < tableItems.count else {
            return false
        }
        
        guard at.row >= -2 && at.row < tableItems[at.section].cells.count else {
            return false
        }
        
        let layoutItem = tableLayoutItems.filter { return $0.index == at
        }.first?.layoutItem
        
        guard layoutItem != nil else {
            return false
        }
        
        if ((layoutItem!.position.y - layoutItem!.layoutItemHeight / 2.0) < (size.height / 2.0 - foregroundLayer.position.y)) {
            if ((layoutItem!.position.y + layoutItem!.layoutItemHeight / 2.0) > (0 - size.height / 2.0 - foregroundLayer.position.y)) {
                return true
            }
        }
        
        return false
    }
    
}


//

fileprivate class SKTableViewNodeLayoutItem: SKNode {
    enum LayoutType: Int {
        case sectionHeader, tableCell, sectionFooter
    }
    var itemType: LayoutType
    var index: IndexPath!
    var layoutItemHeight: CGFloat! = SKTableViewNode.automaticDimension
    var isVisibleOnTable: Bool = false
    
    var contentNode: SKTableViewNodeComponent? {
        didSet {
            oldValue?.removeFromParent()
            if contentNode != nil {
                contentNode?.position = CGPoint.zero
                self.addChild(contentNode!)
            }
            layoutItemHeight = contentNode?.calculateHeight ?? SKTableViewNode.automaticDimension
        }
    }
    
    
    public init(type: LayoutType, index: IndexPath) {
        self.itemType = type
        self.index = index
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


//  MARK: - SKTableViewNodeComponent

public class SKTableViewNodeComponent: SKNode {
    public weak var tableview: SKTableViewNode?
    
    fileprivate var calculateHeight: CGFloat {
        return calculateAccumulatedFrame().size.height
    }
    
    //abandon
    fileprivate var isAddedOnTableView: Bool {
        var parentnode = parent
        while parentnode != nil {
            if parentnode == tableview {
                return true
            }
            parentnode = parentnode?.parent
        }
        return false
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


//  MARK: - SKTableViewNodeCell

public class SKTableViewNodeCell: SKTableViewNodeComponent {
    
}


//  MARK: - SKTableViewNodeHeadFoot

public class SKTableViewNodeSectionHeadFoot: SKTableViewNodeComponent {
    
}


//  MARK: - SKTableViewDelegate

public protocol SKTableViewDelegate: class {
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, heightForRowAt indexPath: IndexPath) -> CGFloat
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, heightForHeaderInSection section: Int) -> CGFloat
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, heightForFooterInSection section: Int) -> CGFloat
    
    //    @available(iOS 7.0, *)
    //    func tableView(_ tableView: SKTableViewNode, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
    //
    //    @available(iOS 7.0, *)
    //    func tableView(_ tableView: SKTableViewNode, estimatedHeightForHeaderInSection section: Int) -> CGFloat
    //
    //    @available(iOS 7.0, *)
    //    func tableView(_ tableView: SKTableViewNode, estimatedHeightForFooterInSection section: Int) -> CGFloat
    
    
    
    //  @available(iOS 2.0, *)
    //  func tableView(_ tableView: SKTableViewNode, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    
    //  @available(iOS 3.0, *)
    //  func tableView(_ tableView: SKTableViewNode, willDeselectRowAt indexPath: IndexPath) -> IndexPath?
    
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, didSelectRowAt indexPath: IndexPath)
    
    @available(iOS 3.0, *)
    func tableView(_ tableView: SKTableViewNode, didDeselectRowAt indexPath: IndexPath)
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: SKTableViewNode, indentationLevelForRowAt indexPath: IndexPath) -> Int
    
}

public extension SKTableViewDelegate {
    
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
