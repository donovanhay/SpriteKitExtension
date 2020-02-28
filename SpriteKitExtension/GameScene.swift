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
    
    private let demos = ["StaticTableViewDemo-Leaderboard": StaticTableViewScene.self]
    private var tableNode : SKTableViewNode?
    
    override func didMove(to view: SKView) {
        self.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        tableNode = SKTableViewNode(size: CGSize(width: view.bounds.size.width - 40, height: view.bounds.size.height - 100))
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

extension GameScene: SKTableViewDelegate {
    func tableView(_ tableView: SKTableViewNode, didSelectRowAt indexPath: IndexPath) {
        let sceneType = Array(demos.values)[indexPath.row] as SKScene.Type
        let selectedScene = sceneType.init(size: view!.bounds.size)
        
        view?.presentScene(selectedScene, transition: SKTransition.crossFade(withDuration: 1.0))
        
    }
    
    func tableView(_ tableView: SKTableViewNode, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SKTableViewNode.automaticDimension
    }
}

extension GameScene: SKTableViewDataSource {
    func numberOfSections(in tableView: SKTableViewNode) -> Int {
        return 1
    }
    
    func tableView(_ tableView: SKTableViewNode, numberOfRowsInSection section: Int) -> Int {
        return demos.count
    }
    
    func tableView(_ tableView: SKTableViewNode, cellForRowAt indexPath: IndexPath) -> SKTableViewNodeCell {
        let cell = SKTableViewNodeCell(TableView: tableView, style: .label)
        cell.labelNode?.text = Array(demos.keys)[indexPath.row]
        
//        let back = SKShapeNode(rectOf: cell.size!)
//        back.fillColor = .white
//        back.strokeColor = .black
//        back.lineWidth = 1
//        cell.backgroundNode = back
        
        return cell
    }
    
    func tableView(_ tableView: SKTableViewNode, viewNodeForHeaderInSection section: Int) -> SKTableViewNodeSectionHeadFoot? {
        let sectionHeader = SKTableViewNodeSectionHeadFoot(TableView: tableView, style: .label)
        sectionHeader.labelNode!.text = "Section"
        return sectionHeader
    }
    
}
