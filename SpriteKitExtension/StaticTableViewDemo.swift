//
//  StaticTableViewDemo.swift
//  SpriteKitExtension
//
//  Created by HanHaikun on 2020/2/20.
//  Copyright © 2020 HanHaikun. All rights reserved.
//

import Foundation
import SpriteKit

class StaticTableViewScene: SKScene {
    
    private let infos = ["NONAME................................9999",
                         "NONAME................................9000",
                         "NONAME................................8000",
                         "NONAME................................7000",
                         "NONAME................................6000",
                         "NONAME................................5000",
                         "NONAME................................4000",
                         "NONAME................................3000",
                         "NONAME................................2000",
                         "NONAME................................1000"]
    
    private var backgroundNode: SKSpriteNode?
    private var leaderboardTable: TableViewNode?
    private var leaderboardLabel: SKLabelNode?
    private var backLabel: SKLabelNode?
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        //backgroundNode
        backgroundNode = SKSpriteNode(imageNamed: "sky.png")
        backgroundNode!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundNode!.size = CGSize(width: size.width, height: backgroundNode!.size.height * size.width / backgroundNode!.size.width)
        backgroundNode!.position = CGPoint(x: 0, y: (backgroundNode!.size.height - size.height) / 2)
        backgroundNode!.zPosition = -1
        self.addChild(backgroundNode!)
        
        //leaderboardLabel
        leaderboardLabel = SKLabelNode(fontNamed: "Copperplate-Bold")
        leaderboardLabel!.verticalAlignmentMode = .center
        leaderboardLabel!.horizontalAlignmentMode = .center
        leaderboardLabel!.fontSize = 38
        leaderboardLabel!.fontColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        leaderboardLabel!.text = "LEADERBOARD"
        leaderboardLabel!.position = CGPoint(x: 0, y: size.height / 2 - 130)
        self.addChild(leaderboardLabel!)
        
        //leaderboardTable
        leaderboardTable = TableViewNode(size: CGSize(width: 300, height: 500))
        leaderboardTable!.dataSource = self
        leaderboardTable!.delegate = self
        leaderboardTable!.allowsScroll = false
        leaderboardTable!.allowsSelect = false
        leaderboardTable!.backgroundNode = SKSpriteNode(color: SKColor.clear, size: leaderboardTable!.size)
        leaderboardTable!.position = CGPoint(x: 0, y: leaderboardLabel!.position.y - 280)
        self.addChild(leaderboardTable!)
        
        //backLabel
        backLabel = SKLabelNode(fontNamed: "PingFangSC-Regular")
        backLabel!.verticalAlignmentMode = .bottom
        backLabel!.horizontalAlignmentMode = .left
        backLabel!.fontSize = 30
        backLabel!.fontColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        backLabel!.text = "Back"
        backLabel!.position = CGPoint(x: 30 - size.width / 2, y: 30 - size.height / 2)
        self.addChild(backLabel!)
        
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchposition = touches.first?.location(in: self)
        
        if backLabel!.contains(touchposition ?? CGPoint.zero) {
            view?.presentScene(GameScene(size: view!.bounds.size), transition: SKTransition.crossFade(withDuration: 1.0))
        }
        
    }
    
}


extension StaticTableViewScene: TableViewDataSource {
    func tableView(_ tableView: TableViewNode, cellForRowAt indexPath: IndexPath) -> TableViewNodeCell {
        let cell = TableViewNodeCell(TableView: tableView, style: .label)
        cell.backgroundNode = SKSpriteNode(color: SKColor.clear, size: cell.size!)
        cell.labelNode!.fontName = "AmericanTypewriter"
        cell.labelNode!.fontColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        cell.labelNode!.numberOfLines = 1
        cell.labelNode!.text = infos[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: TableViewNode, numberOfRowsInSection section: Int) -> Int {
        return infos.count
    }
    
    func numberOfSections(in tableView: TableViewNode) -> Int {
        return 1
    }
    
}

extension StaticTableViewScene: TableViewDelegate {
    func tableView(_ tableView: TableViewNode, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: TableViewNode, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: TableViewNode, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
}
