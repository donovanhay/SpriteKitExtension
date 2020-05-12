//
//  GameScene.swift
//  SpriteKitExtension
//
//  Created by HanHaikun on 2020/1/30.
//  Copyright © 2020 HanHaikun. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private let demos = ["StaticTableViewDemo-Leaderboard": StaticTableViewScene.self,
                         "ScrollTalbeViewDemo-HeroesInfo": ScrollTableViewScene.self]
    private var tableNode : TableViewNode?
    
    override func didMove(to view: SKView) {
        self.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        tableNode = TableViewNode(size: CGSize(width: view.bounds.size.width - 40, height: view.bounds.size.height - 100))
        tableNode!.position = CGPoint.zero
        tableNode!.delegate = self
        tableNode!.dataSource = self
        
        self.addChild(tableNode!)
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        tableNode?.update(currentTime)
    }
}

extension GameScene: TableViewDelegate {
    func tableView(_ tableView: TableViewNode, didSelectRowAt indexPath: IndexPath) {
        let sceneType = Array(demos.values)[indexPath.row] as SKScene.Type
        let selectedScene = sceneType.init(size: view!.bounds.size)
        
        view?.presentScene(selectedScene, transition: SKTransition.crossFade(withDuration: 1.0))
        
    }
    
    func tableView(_ tableView: TableViewNode, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TableViewNode.automaticDimension
    }
}

extension GameScene: TableViewDataSource {
    func numberOfSections(in tableView: TableViewNode) -> Int {
        return 1
    }
    
    func tableView(_ tableView: TableViewNode, numberOfRowsInSection section: Int) -> Int {
        return demos.count
    }
    
    func tableView(_ tableView: TableViewNode, cellForRowAt indexPath: IndexPath) -> TableViewNodeCell {
        let cell = TableViewNodeCell(TableView: tableView, style: .label)
        cell.labelNode?.text = Array(demos.keys)[indexPath.row]
        
//        let back = SKShapeNode(rectOf: cell.size!)
//        back.fillColor = .white
//        back.strokeColor = .black
//        back.lineWidth = 1
//        cell.backgroundNode = back
        
        return cell
    }
    
    func tableView(_ tableView: TableViewNode, viewNodeForHeaderInSection section: Int) -> TableViewNodeSectionHeadFoot? {
        let sectionHeader = TableViewNodeSectionHeadFoot(TableView: tableView, style: .label)
        sectionHeader.labelNode!.text = "Demos"
        return sectionHeader
    }
    
}
