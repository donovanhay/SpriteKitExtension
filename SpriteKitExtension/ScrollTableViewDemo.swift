//
//  ScrollTableViewDemo.swift
//  SpriteKitExtension
//
//  Created by HanHaikun on 2020/3/9.
//  Copyright © 2020 HanHaikun. All rights reserved.
//

import Foundation
import SpriteKit

class ScrollTableViewScene: SKScene {
    
    private var heroesinfo = [(name:String, heropower: String, imagename: String)]()
    private let heroesImages = SKTextureAtlas(named: "heroes")
    
    private var backgroundNode: SKSpriteNode!
    private var title: SKNode!
    private var heroTable: TableViewNode!
    private var backLabel: SKLabelNode!
    
    override func sceneDidLoad() {
        let plisturl = Bundle.main.path(forResource: "HeroesInfo", ofType: "plist")
        let herolist = NSArray(contentsOfFile: plisturl!)
        for item in herolist! {
            let dic = item as! NSDictionary
            let _heroname = dic.value(forKey: "name") as! String
            let _heropower = dic.value(forKey: "heropower") as! String
            let _imagename = dic.value(forKey: "image") as! String
            
            heroesinfo.append((name: _heroname, heropower: _heropower, imagename: _imagename))
        }
        
    }
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        //backgroundNode
        backgroundNode = SKSpriteNode(texture: SKTexture(imageNamed: "background.jpg"), size: size)
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundNode.position = CGPoint.zero
        backgroundNode.zPosition = -1
        self.addChild(backgroundNode)
        
        //titleNode
        title = SKNode()
        title.position = CGPoint(x: 0, y: size.height / 2 - 40 - (UIDevice.current.isNotchScreen ? 24 : 0))
        let titleBorder = SKSpriteNode(imageNamed: "labelborder.png")
        titleBorder.size = CGSize(width: 180, height: 40)
        titleBorder.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        titleBorder.position = CGPoint.zero
        title.addChild(titleBorder)
        let titletext = SKLabelNode(fontNamed: "Cochin-Bold") //PartyLetPlain Cochin-Bold Papyrus Zapfino
        titletext.text = "HEROES"
        titletext.verticalAlignmentMode = .center
        titletext.horizontalAlignmentMode = .center
        titletext.fontSize = 24
        titletext.fontColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        titletext.position = CGPoint.zero
        title.addChild(titletext)
        
        self.addChild(title)
        
        //heroTable
        heroTable = TableViewNode(size: CGSize(width: size.width - 40, height: size.height - 136 - (UIDevice.current.isNotchScreen ? 24 : 0)))
        heroTable.dataSource = self
        heroTable.delegate = self
        heroTable.allowsScroll = true
        heroTable.allowsSelect = true
        heroTable.backgroundNode = nil
        heroTable.position = CGPoint(x: 0, y: title.position.y - 30 - heroTable.size.height / 2)
        self.addChild(heroTable)
        
        //backLabel
        backLabel = SKLabelNode(fontNamed: "PingFangSC-Medium")
        backLabel!.verticalAlignmentMode = .bottom
        backLabel!.horizontalAlignmentMode = .left
        backLabel!.fontSize = 20
        backLabel!.fontColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        backLabel!.text = "Back"
        backLabel!.position = CGPoint(x: 20 - size.width / 2, y: 20 - size.height / 2)
        self.addChild(backLabel!)
    }
    
    override func update(_ currentTime: TimeInterval) {
        heroTable.update(currentTime)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchposition = touches.first?.location(in: self)
        
        if backLabel!.contains(touchposition ?? CGPoint.zero) {
            view?.presentScene(GameScene(size: view!.bounds.size), transition: SKTransition.crossFade(withDuration: 1.0))
        }
    }
    
}


extension ScrollTableViewScene: TableViewDataSource {
    func numberOfSections(in tableView: TableViewNode) -> Int {
        return 1
    }
    
    func tableView(_ tableView: TableViewNode, numberOfRowsInSection section: Int) -> Int {
        return heroesinfo.count
    }
    
    func tableView(_ tableView: TableViewNode, cellForRowAt indexPath: IndexPath) -> TableViewNodeCell {
        let heroinfo = heroesinfo[indexPath.row]
        
        let cell = TableViewNodeCell(TableView: tableView, style: .split)
        cell.backgroundNode = SKSpriteNode(imageNamed: "cellborder.png")
        cell.setSplitWidthPercentage(left: 0.4, right: 0.6)
        
        let imageNode = SKSpriteNode(texture: heroesImages.textureNamed(heroinfo.imagename), size: CGSize(width: cell.leftNodeSize.width - 40, height: (cell.leftNodeSize.width - 40) * 1.38133))
        imageNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imageNode.position = CGPoint.zero
        cell.leftNode?.addChild(imageNode)
        
        let labelNode = SKLabelNode(fontNamed: "PingFangSC-Medium")
        labelNode.text = heroinfo.name
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        labelNode.fontColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        labelNode.fontSize = 18
        labelNode.position = CGPoint.zero
        cell.rightNode?.addChild(labelNode)
        
        return cell
    }
    
}

extension ScrollTableViewScene: TableViewDelegate {
    func tableView(_ tableView: TableViewNode, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: TableViewNode, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: TableViewNode, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.size.width * 0.4 * 1.38 - 45
//        return 165
    }
}
