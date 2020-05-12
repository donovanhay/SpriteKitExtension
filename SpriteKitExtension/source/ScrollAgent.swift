//
//  ScrollAgent.swift
//  SpriteKitExtension
//
//  Created by HanHaikun on 2020/3/30.
//  Copyright © 2020 HanHaikun. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit


//  MARK: - PointLocationOfArea

public enum PointLocationOfArea: Int {
    case OutOfArea = -1, OnEdge, InArea
}


//  MARK: - ScrollEdgeAdsorbentDirection

public enum ScrollEdgeAdsorbentDirection: Int {
    case None, In, Out, Both
}


//  MARK: - MoveableGoal

fileprivate struct MoveableGoal {
    var goalKey: String
    var position = CGPoint.zero
    var moveVelocity = CGVector.zero
    var edgeAdsorbentVelocity = CGVector.zero
    var isHold = false {
        didSet {
            if isHold {
                moveVelocity = CGVector.zero
                edgeAdsorbentVelocity = CGVector.zero
                arrivalPosition = nil
                restTime = 0.0
            }
        }
    }
    
    var arrivalPosition: CGPoint? = nil
    var restTime: Double = 0.0
    
    init(goalKey: String, position: CGPoint = CGPoint.zero, moveVelocity: CGVector = CGVector.zero, edgeAdsorbentVelocity: CGVector = CGVector.zero, isHold: Bool = false) {
        self.goalKey = goalKey
        self.position = position
        self.moveVelocity = moveVelocity
        self.edgeAdsorbentVelocity = edgeAdsorbentVelocity
        self.isHold = isHold
    }
}


//  MARK: - ScrollAgent

public class ScrollAgent: NSObject {
    
    //  MARK:   Delegate
    
    public var delegate: ScrollAgentDelegate? {
        didSet {
            initGoals()
        }
    }
    
    
    //  MARK:   Goals and Properties
    
    private var goals = [String: MoveableGoal]()
    
    private func initGoals() {
        goals.removeAll()
        
        if delegate != nil {
            for i in 0..<delegate!.numbersOfGoals(in: self) {
                let goalkey = delegate!.keysOfGoals(in: self)[i]
                let goal = MoveableGoal(goalKey: goalkey, position: delegate!.scrollAgent(self, startPositionOfGoal: goalkey))
                goals[goalkey] = goal
            }
        }
        
    }
    
    public func currentPosition(goalKey key: String) -> CGPoint? {
        return goals[key]?.position
    }
    
    public func currentVelocity(goalKey key: String) -> CGVector? {
        guard let goal = goals[key] else {
            return nil
        }
        
        return CGVector(dx: addInF(lhs: goal.moveVelocity.dx, rhs: goal.edgeAdsorbentVelocity.dx), dy: addInF(lhs: goal.moveVelocity.dy, rhs: goal.edgeAdsorbentVelocity.dy))
    }
    
    public func isHold(goalKey key: String) -> Bool? {
        return goals[key]?.isHold
    }
    
    public func currentDistanceToEdges(goalKey key: String) -> UIEdgeInsets? {
        guard delegate != nil else {
            return nil
        }
        
        guard let goal = goals[key] else {
            return nil
        }
        
        let scrollArea = delegate!.scrollAgent(self, scrollAreaOfGoal: key)
          
        return distanceOfPointToAreaEdge(Point: goal.position, Area: scrollArea)
            
    }
    
    public func currentMovementArea(goalKey key: String) -> CGRect {
        guard delegate != nil else {
            return CGRect.zero
        }
        
        var movementArea = delegate!.scrollAgent(self, scrollAreaOfGoal: key)
        
        let margin = delegate!.scrollAgent(self, edgeAdsorbentMarginOutScrollAreaOfGoal: key)
        
        //top
        if delegate!.scrollAgent(self, topEdgeAdsorbentModeOfGoal: key) == .Out || delegate!.scrollAgent(self, topEdgeAdsorbentModeOfGoal: key) == .Both {
            movementArea.size.height += margin.top
            
        }
        
        //left
        if delegate!.scrollAgent(self, leftEdgeAdsorbentModeOfGoal: key) == .Out || delegate!.scrollAgent(self, leftEdgeAdsorbentModeOfGoal: key) == .Both {
            movementArea.origin.x -= margin.left
            movementArea.size.width += margin.left
            
        }
        
        //bottom
        if delegate!.scrollAgent(self, bottomEdgeAdsorbentModeOfGoal: key) == .Out || delegate!.scrollAgent(self, bottomEdgeAdsorbentModeOfGoal: key) == .Both {
            movementArea.origin.y -= margin.bottom
            movementArea.size.height += margin.bottom
            
        }
        
        //right
        if delegate!.scrollAgent(self, rightEdgeAdsorbentModeOfGoal: key) == .Out || delegate!.scrollAgent(self, rightEdgeAdsorbentModeOfGoal: key) == .Both {
            movementArea.size.width += margin.right
            
        }
                
        return movementArea
    }
    
    private func insetsOfGoalEdgeAdsorbent(goalKey key: String) -> UIEdgeInsets {
        guard delegate != nil else {
            return UIEdgeInsets.zero
        }
        
        let edgeDistances = currentDistanceToEdges(goalKey: key)!
        
        let adsorbentPadding = delegate!.scrollAgent(self, edgeAdsorbentPaddingInScrollAreaOfGoal: key)
        
        let absorbentMargin = delegate!.scrollAgent(self, edgeAdsorbentMarginOutScrollAreaOfGoal: key)
        
        var edgeInset = UIEdgeInsets.zero
        
        // top
        if delegate!.scrollAgent(self, topEdgeAdsorbentModeOfGoal: key) == .In || delegate!.scrollAgent(self, topEdgeAdsorbentModeOfGoal: key) == .Both {
            if isGreatOrEqualInF(lhs: adsorbentPadding.top, rhs: edgeDistances.top) && edgeDistances.top > 0 {
                edgeInset.top = 1
            }
        } else if delegate!.scrollAgent(self, topEdgeAdsorbentModeOfGoal: key) == .Out || delegate!.scrollAgent(self, topEdgeAdsorbentModeOfGoal: key) == .Both {
            if isGreatOrEqualInF(lhs: absorbentMargin.top, rhs: abs(edgeDistances.top)) && edgeDistances.top < 0 {
                edgeInset.top = -1
            }
        }
        
        // left
        if delegate!.scrollAgent(self, leftEdgeAdsorbentModeOfGoal: key) == .In || delegate!.scrollAgent(self, leftEdgeAdsorbentModeOfGoal: key) == .Both {
            if isGreatOrEqualInF(lhs: adsorbentPadding.left, rhs: edgeDistances.left) && edgeDistances.left > 0 {
                edgeInset.left = -1
            }
        } else if delegate!.scrollAgent(self, leftEdgeAdsorbentModeOfGoal: key) == .Out || delegate!.scrollAgent(self, leftEdgeAdsorbentModeOfGoal: key) == .Both {
            if isGreatOrEqualInF(lhs: absorbentMargin.left, rhs: abs(edgeDistances.left)) && edgeDistances.left < 0 {
                edgeInset.left = 1
            }
        }
        
        // bottom
        if delegate!.scrollAgent(self, bottomEdgeAdsorbentModeOfGoal: key) == .In || delegate!.scrollAgent(self, bottomEdgeAdsorbentModeOfGoal: key) == .Both {
            if isGreatOrEqualInF(lhs: adsorbentPadding.bottom, rhs: edgeDistances.bottom) && edgeDistances.bottom > 0 {
                edgeInset.bottom = -1
            }
        } else if delegate!.scrollAgent(self, bottomEdgeAdsorbentModeOfGoal: key) == .Out || delegate!.scrollAgent(self, bottomEdgeAdsorbentModeOfGoal: key) == .Both {
            if isGreatOrEqualInF(lhs: absorbentMargin.bottom, rhs: abs(edgeDistances.bottom)) && edgeDistances.bottom < 0 {
                edgeInset.bottom = 1
            }
        }
        
        // right
        if delegate!.scrollAgent(self, rightEdgeAdsorbentModeOfGoal: key) == .In || delegate!.scrollAgent(self, rightEdgeAdsorbentModeOfGoal: key) == .Both {
            if isGreatOrEqualInF(lhs: adsorbentPadding.right, rhs: edgeDistances.right) && edgeDistances.right > 0 {
                edgeInset.right = 1
            }
        } else if delegate!.scrollAgent(self, rightEdgeAdsorbentModeOfGoal: key) == .Out || delegate!.scrollAgent(self, rightEdgeAdsorbentModeOfGoal: key) == .Both {
            if isGreatOrEqualInF(lhs: absorbentMargin.right, rhs: abs(edgeDistances.right)) && edgeDistances.right < 0 {
                edgeInset.top = -1
            }
        }
        
        return edgeInset
    }
    
    
    //  MARK:   Initial and Reset
    
    public func addGoal(withKey key: String) {
        guard delegate != nil else {
            return
        }
        
        guard !(goals.keys.contains(key)) else {
            return
        }
        
        let goal = MoveableGoal(goalKey: key, position: delegate!.scrollAgent(self, startPositionOfGoal: key))
        
        goals[key] = goal
        
    }
    
    public func removeGoal(withKey key: String) {
        goals.removeValue(forKey: key)
    }
    
    public func reset() {
        goals.keys.forEach { (key) in
            reset(goalKey: key)
        }
    }
    
    public func reset(goalKey key: String) {
        setPosition(goalKey: key, Position: delegate!.scrollAgent(self, startPositionOfGoal: key))
        goals[key]?.moveVelocity = CGVector.zero
        goals[key]?.edgeAdsorbentVelocity = CGVector.zero
        goals[key]?.isHold = false
        
    }
    
    
    //  MARK:   User Input for Movement
    
    public func setMovement(goalKey key: String, moveTo: CGPoint, duration: TimeInterval) {
        guard goals.keys.contains(key) else {
            return
        }
        
        let moveVector = CGVector(dx: minusInF(lhs: moveTo.x, rhs: goals[key]!.position.x), dy: minusInF(lhs: moveTo.y, rhs: goals[key]!.position.y))
        
        setPosition(goalKey: key, Position: arrivalPosition(goalKey: key, Destination: moveTo))
        
        setMovement(goalKey: key, setVelocity: moveVector / Double(duration))
        
    }
    
    public func setMovement(goalKey key: String, moveBy: CGVector, duration: TimeInterval) {
        guard goals.keys.contains(key) else {
            return
        }
        
        setMovement(goalKey: key, moveTo: goals[key]!.position.move(by: moveBy), duration: duration)
        
    }
    
    public func setHold(goalKey key: String, isHold: Bool) {
        goals[key]?.isHold = isHold
    }
    
    public func setMovement(goalKey key: String, setVelocity v: CGVector) {
        guard goals.keys.contains(key) else {
            return
        }
        
        guard !(goals[key]!.isHold) else {
            return
        }
        
        guard goals[key]!.arrivalPosition == nil else {
            return
        }
        
        let maxV = delegate?.scrollAgent(self, maxVelocityValueOfGoal: key) ?? CGVector(dx: CGFloat.greatestFiniteMagnitude, dy: CGFloat.greatestFiniteMagnitude)
        let minV = delegate?.scrollAgent(self, minVelocityValueOfGoal: key) ?? CGVector.zero
        
        let velocityX = isGreatInF(lhs: abs(v.dx), rhs: maxV.dx) ? (v.dx / abs(v.dx) * maxV.dx) : (isGreatInF(lhs: minV.dx, rhs: abs(v.dx)) ? 0.0 : v.dx)
        let velocityY = isGreatInF(lhs: abs(v.dy), rhs: maxV.dy) ? (v.dy / abs(v.dy) * maxV.dy) : (isGreatInF(lhs: minV.dy, rhs: abs(v.dy)) ? 0.0 : v.dy)
        
        goals[key]!.moveVelocity = CGVector(dx: velocityX, dy: velocityY)
        
    }
    
    private func setMovement(setEdgeAdsorbentVelocityForGoalKey key: String) {
        guard goals.keys.contains(key) else {
            return
        }
        
        guard !(goals[key]!.isHold) else {
            return
        }
        
        guard goals[key]!.arrivalPosition == nil else {
            return
        }
        
        let insetOFEdgeAdsorbent = insetsOfGoalEdgeAdsorbent(goalKey: key)
        
        var velocityX: CGFloat = 0.0
        var velocityY: CGFloat = 0.0
        
        //horizontal
        //left
        velocityX = insetOFEdgeAdsorbent.left * 1500 + insetOFEdgeAdsorbent.right * 1500
        
        //vertical
        velocityY = insetOFEdgeAdsorbent.bottom * 1500 + insetOFEdgeAdsorbent.top * 1500
        
        goals[key]!.edgeAdsorbentVelocity = CGVector(dx: velocityX, dy: velocityY)
    }
    
    private func setPosition(goalKey key:String, Position posi: CGPoint) {
        guard goals.keys.contains(key) else {
            return
        }
        
        let originalPosi = goals[key]!.position
        
        goals[key]!.position = posi
        
        delegate?.scrollAgent(self, positionDidChangeFrom: originalPosi, To: posi, ofGoal: key)
        
    }
    
    private func arrivalPosition(goalKey key: String, Destination destPosition: CGPoint) -> CGPoint {
        let scrollArea = delegate!.scrollAgent(self, scrollAreaOfGoal: key)
        
        if pointLocationOfArea(Point: goals[key]!.position, Area: scrollArea) == .InArea && pointLocationOfArea(Point: destPosition, Area: scrollArea) == .InArea {
            return destPosition
        }
        
        if goals[key]!.isHold {
            let distanceInset = distanceOfPointToAreaEdge(Point: destPosition, Area: scrollArea)
            
            var arrivalPositionX = destPosition.x
            var arrivalPositionY = destPosition.y
            
            //horizontal
            if compareInF(lhs: distanceInset.left, rhs: 0) < 0 {
                arrivalPositionX = delegate!.scrollAgent(self, scrollAreaOfGoal: key).origin.x + distanceInset.left * cos(CGFloat.pi / 2 * distanceInset.left / (delegate!.scrollAgent(self, edgeAdsorbentMarginOutScrollAreaOfGoal: key).left * 1.25))
            } else {
                arrivalPositionX = delegate!.scrollAgent(self, scrollAreaOfGoal: key).origin.x + delegate!.scrollAgent(self, scrollAreaOfGoal: key).width - distanceInset.right * cos(CGFloat.pi / 2 * distanceInset.right / (delegate!.scrollAgent(self, edgeAdsorbentMarginOutScrollAreaOfGoal: key).right * 1.25))
            }
            
            //vertical
            if compareInF(lhs: distanceInset.bottom, rhs: 0) < 0 {
                arrivalPositionY = delegate!.scrollAgent(self, scrollAreaOfGoal: key).origin.y + distanceInset.bottom * cos(CGFloat.pi / 2 * distanceInset.bottom / (delegate!.scrollAgent(self, edgeAdsorbentMarginOutScrollAreaOfGoal: key).bottom * 1.25))
            } else {
                arrivalPositionY = delegate!.scrollAgent(self, scrollAreaOfGoal: key).origin.y + delegate!.scrollAgent(self, scrollAreaOfGoal: key).height - distanceInset.top * cos(CGFloat.pi / 2 * distanceInset.top / (delegate!.scrollAgent(self, edgeAdsorbentMarginOutScrollAreaOfGoal: key).top * 1.25))
            }
            
            if pointLocationOfArea(Point: CGPoint(x: arrivalPositionX, y: arrivalPositionY), Area: currentMovementArea(goalKey: key)) == .OutOfArea {
                return arrivalPositionInArea(Destination: CGPoint(x: arrivalPositionX, y: arrivalPositionY), Area: currentMovementArea(goalKey: key))
            } else {
                return CGPoint(x: arrivalPositionX, y: arrivalPositionY)
            }
        }
        
        if pointLocationOfArea(Point: goals[key]!.position, Area: scrollArea) != .InArea && pointLocationOfArea(Point: destPosition, Area: scrollArea) != .InArea {
            return destPosition
        }
        
        return intersectionPosition(PointA: goals[key]!.position, PointB: destPosition, Rect: scrollArea) ?? destPosition
        
    }
    
    
    //  MARK:   Goal's Action
    
    public func goal(goalKey key: String, moveTo: CGPoint, duration: TimeInterval? = nil) {
        guard goals.keys.contains(key) else {
            return
        }
        
        guard !(goals[key]!.isHold) else {
            return
        }
        
        guard goals[key]!.arrivalPosition == nil else {
            return
        }
        
        goals[key]!.arrivalPosition = moveTo
        
        if duration != nil {
            goals[key]!.restTime = duration!
        } else {
            goals[key]!.restTime = CGVector(dx: moveTo.x - goals[key]!.position.x, dy: moveTo.y - goals[key]!.position.y).length / 1000
        }
        
        goals[key]!.edgeAdsorbentVelocity = CGVector.zero
        goals[key]!.moveVelocity = CGVector.zero
        
    }
    
    public func goal(goalKey key: String, moveBy: CGVector, duration: TimeInterval? = nil) {
        guard goals.keys.contains(key) else {
            return
        }
        
        goal(goalKey: key, moveTo: goals[key]!.position.move(by: moveBy), duration: duration)
    }
    
    
    //  MARK:   Performing Periodic Updates
    
    public func update(deltaTime dt: TimeInterval) {
        
        goals.forEach { (key, value) in
            goalsMovementStateUpdate(goalKey: key, deltaTime: dt)
        }
        
        
    }
    
    private func goalsMovementStateUpdate(goalKey key: String, deltaTime dt: TimeInterval) {
        guard goals.keys.contains(key) else {
            return
        }
        
        guard !(goals[key]!.isHold) else {
            return
        }
                
        let totalVelcity = goals[key]!.edgeAdsorbentVelocity + goals[key]!.moveVelocity
        
        guard totalVelcity.angle != 0 else {
            return
        }
        
        let moveToPosition = arrivalPosition(goalKey: key, Destination: goals[key]!.position.move(by: totalVelcity * dt))
        
        setPosition(goalKey: key, Position: moveToPosition)
        
        let dampingRatioVector = CGVector(dx: delegate!.scrollAgent(self, dampingRatioXOfGoal: key), dy: delegate!.scrollAgent(self, dampingRatioYOfGoal: key))
        
        let updatedVelcity = CGVector(dx: goals[key]!.moveVelocity.dx * pow(1 - dampingRatioVector.dx, CGFloat(dt)), dy: goals[key]!.moveVelocity.dy * pow(1 - dampingRatioVector.dy, CGFloat(dt)))
        
        setMovement(goalKey: key, setVelocity: updatedVelcity)
        setMovement(setEdgeAdsorbentVelocityForGoalKey: key)
        
    }
    
    private func goalsMoveActionUpdate(goalKey key: String, deltaTime dt: TimeInterval) {
        guard goals.keys.contains(key) else {
            return
        }
        
        guard !(goals[key]!.isHold) else {
            return
        }
        
        guard goals[key]!.arrivalPosition != nil else {
            return
        }
        
        let arrivalPosi = goals[key]!.position.move(by: CGVector(startPoint: goals[key]!.position, endPoint: goals[key]!.arrivalPosition!) * (goals[key]!.restTime / dt))
        
        setPosition(goalKey: key, Position: arrivalPosi)
        
        goals[key]!.restTime = Double.maximum(goals[key]!.restTime - dt, 0.0)
        
        if goals[key]!.position == goals[key]!.arrivalPosition {
            goals[key]!.arrivalPosition = nil
        }
        
    }
    
    //  MARK:   User Touches (deprecated)
    
    private func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    private func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    private func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    // MARK:    private method
    
    private func distanceOfPointToAreaEdge(Point aPoint: CGPoint, Area area: CGRect) -> UIEdgeInsets {
        let leftDis = minusInF(lhs: aPoint.x, rhs: area.origin.x)
        let rightDis = minusInF(lhs: area.width, rhs: leftDis)
        let bottomDis = minusInF(lhs: aPoint.y, rhs: area.origin.y)
        let topDis = minusInF(lhs: area.height, rhs: bottomDis)
        
        return UIEdgeInsets(top: topDis, left: leftDis, bottom: bottomDis, right: rightDis)
    }
    
    private func pointLocationOfArea(Point aPoint: CGPoint, Area area: CGRect) -> PointLocationOfArea {
        let distanceToEdge = distanceOfPointToAreaEdge(Point: aPoint, Area: area)
        
        if (distanceToEdge.top > 0) && (distanceToEdge.left > 0) && (distanceToEdge.bottom > 0) && (distanceToEdge.right > 0) {
            return PointLocationOfArea.InArea
        } else if (distanceToEdge.top < 0) || (distanceToEdge.left < 0) || (distanceToEdge.bottom < 0) || (distanceToEdge.right < 0) {
            return PointLocationOfArea.OutOfArea
        } else {
            return PointLocationOfArea.OnEdge
        }
                
    }
    
    private func intersectionPosition(PointA aPosition: CGPoint, PointB bPosition: CGPoint, Rect rect: CGRect) -> CGPoint? {
        var intersections = [(divisionRatio: Float, position: CGPoint)]()
        
        //topIntersection
        let topDivisionRatio = divisionRatio(divisionValue: Float(rect.origin.y) + Float(rect.height), left: Float(aPosition.y), right: Float(bPosition.y))
        if topDivisionRatio >= 0 {
            let y = rect.origin.y + rect.height
            let x = CGFloat((Float(aPosition.x) + Float(bPosition.x) * topDivisionRatio) / (1 + topDivisionRatio))
            
            if isGreatOrEqualInF(lhs: x, rhs: rect.origin.x) && isGreatOrEqualInF(lhs: rect.origin.x + rect.width, rhs: x) {
                let Intersection = CGPoint(x: x, y: y)
                intersections.append((divisionRatio: topDivisionRatio, position: Intersection))
            }
        }
        
        //leftIntersection
        let leftDivisionRatio = divisionRatio(divisionValue: Float(rect.origin.x), left: Float(aPosition.x), right: Float(bPosition.x))
        if leftDivisionRatio >= 0 {
            let x = rect.origin.x
            let y = CGFloat((Float(aPosition.y) + Float(bPosition.y) * topDivisionRatio) / (1 + topDivisionRatio))
            
            if isGreatOrEqualInF(lhs: y, rhs: rect.origin.y) && isGreatOrEqualInF(lhs: rect.origin.y + rect.height, rhs: y) {
                let Intersection = CGPoint(x: x, y: y)
                intersections.append((divisionRatio: leftDivisionRatio, position: Intersection))
            }
        }
        
        //bottomIntersection
        let bottomDivisionRatio = divisionRatio(divisionValue: Float(rect.origin.y), left: Float(aPosition.y), right: Float(bPosition.y))
        if bottomDivisionRatio >= 0 {
            let y = rect.origin.y
            let x = CGFloat((Float(aPosition.x) + Float(bPosition.x) * topDivisionRatio) / (1 + topDivisionRatio))
            
            if isGreatOrEqualInF(lhs: x, rhs: rect.origin.x) && isGreatOrEqualInF(lhs: rect.origin.x + rect.width, rhs: x) {
                let Intersection = CGPoint(x: x, y: y)
                intersections.append((divisionRatio: bottomDivisionRatio, position: Intersection))
            }
        }
        
        //rightIntersection
        let rightDivisionRatio = divisionRatio(divisionValue: Float(rect.origin.x) + Float(rect.width), left: Float(aPosition.x), right: Float(bPosition.x))
        if rightDivisionRatio >= 0 {
            let x = rect.origin.x + rect.width
            let y = CGFloat((Float(aPosition.y) + Float(bPosition.y) * topDivisionRatio) / (1 + topDivisionRatio))
            
            if isGreatOrEqualInF(lhs: y, rhs: rect.origin.y) && isGreatOrEqualInF(lhs: rect.origin.y + rect.height, rhs: y) {
                let Intersection = CGPoint(x: x, y: y)
                intersections.append((divisionRatio: rightDivisionRatio, position: Intersection))
            }
        }
        
        return intersections.sorted(by: {(item0, item1) -> Bool in return item0.divisionRatio < item1.divisionRatio}).first?.position
        
    }
    
    private func arrivalPositionInArea(Destination bPosition: CGPoint, Area area: CGRect) -> CGPoint {
        let arrivalX = isGreatInF(lhs: bPosition.x, rhs: area.origin.x) ? (isGreatInF(lhs: addInF(lhs: area.origin.x, rhs: area.width), rhs: bPosition.x) ? bPosition.x : addInF(lhs: area.origin.x, rhs: area.width) ) : area.origin.x
        
        let arrivalY = isGreatInF(lhs: bPosition.y, rhs: area.origin.y) ? (isGreatInF(lhs: addInF(lhs: area.origin.y, rhs: area.height), rhs: bPosition.y) ? bPosition.y : addInF(lhs: area.origin.y, rhs: area.height) ) : area.origin.y
        
        return CGPoint(x: arrivalX, y: arrivalY)
        
    }
    
}


//  MARK: - ScrollAgentDelegate

public protocol ScrollAgentDelegate: class {
    
    //  MARK:   Basic
    func numbersOfGoals(in scrollAgent: ScrollAgent) -> Int
    
    func keysOfGoals(in scrollAgent: ScrollAgent) -> [String]
    
    func scrollAgent(_ scrollAgent: ScrollAgent, scrollAreaOfGoal key: String) -> CGRect
    
    func scrollAgent(_ scrollAgent: ScrollAgent, startPositionOfGoal key: String) -> CGPoint
    
    
    //  MARK:   Inertance
    func scrollAgent(_ scrollAgent: ScrollAgent, dampingRatioXOfGoal key: String) -> CGFloat
    
    func scrollAgent(_ scrollAgent: ScrollAgent, dampingRatioYOfGoal key: String) -> CGFloat
    
    func scrollAgent(_ scrollAgent: ScrollAgent, minVelocityValueOfGoal key: String) -> CGVector
    
    func scrollAgent(_ scrollAgent: ScrollAgent, maxVelocityValueOfGoal key: String) -> CGVector
    
    
    //  MARK:    EdgeAdsorbent
    func scrollAgent(_ scrollAgent: ScrollAgent, topEdgeAdsorbentModeOfGoal key: String) -> ScrollEdgeAdsorbentDirection
    func scrollAgent(_ scrollAgent: ScrollAgent, leftEdgeAdsorbentModeOfGoal key: String) -> ScrollEdgeAdsorbentDirection
    func scrollAgent(_ scrollAgent: ScrollAgent, bottomEdgeAdsorbentModeOfGoal key: String) -> ScrollEdgeAdsorbentDirection
    func scrollAgent(_ scrollAgent: ScrollAgent, rightEdgeAdsorbentModeOfGoal key: String) -> ScrollEdgeAdsorbentDirection
    
    func scrollAgent(_ scrollAgent: ScrollAgent, edgeAdsorbentPaddingInScrollAreaOfGoal key: String) -> UIEdgeInsets
    func scrollAgent(_ scrollAgent: ScrollAgent, edgeAdsorbentMarginOutScrollAreaOfGoal key: String) -> UIEdgeInsets
    
    
    //  MARK:   Reaction
    //func scrollAgent(_ scrollAgent: ScrollAgent, positionWillChangeFrom from: CGPoint, To to: CGPoint, ofGoal key: String)
    
    func scrollAgent(_ scrollAgent: ScrollAgent, positionDidChangeFrom from: CGPoint, To to: CGPoint, ofGoal key: String)
    
}


//  MARK: - Required Functions

//  MARK:   Operations in Float

fileprivate func addInF (lhs: CGFloat, rhs: CGFloat) -> CGFloat {
    return CGFloat(Float(lhs) + Float(rhs))
}

fileprivate func minusInF (lhs: CGFloat, rhs: CGFloat) -> CGFloat {
    return CGFloat(Float(lhs) - Float(rhs))
}

fileprivate func multiplyInF (lhs: CGFloat, rhs: CGFloat) -> CGFloat {
    return CGFloat(Float(lhs) * Float(rhs))
}

fileprivate func divideInF (lhs: CGFloat, rhs: CGFloat) -> CGFloat {
    return CGFloat(Float(lhs) / Float(rhs))
}

fileprivate func compareInF (lhs: CGFloat, rhs: CGFloat) -> Int {
    if Float(lhs) == Float(rhs) {
        return 0
    } else if Float(lhs) > Float(rhs) {
        return 1
    } else {
        return -1
    }
}

fileprivate func isGreatInF (lhs: CGFloat, rhs: CGFloat) -> Bool {
    return compareInF(lhs: lhs, rhs: rhs) > 0
}

fileprivate func isGreatOrEqualInF (lhs: CGFloat, rhs: CGFloat) -> Bool {
    return compareInF(lhs: lhs, rhs: rhs) >= 0
}

fileprivate func isEqualInF (lhs: CGFloat, rhs: CGFloat) -> Bool {
    return compareInF(lhs: lhs, rhs: rhs) == 0
}

fileprivate func distanceBetween(Point aPoint: CGPoint, andPoint bPoint: CGPoint) -> CGFloat {
    let deltaX = aPoint.x - bPoint.x
    let deltaY = aPoint.y - bPoint.y
    return hypot(deltaX, deltaY)
}

fileprivate func divisionRatio(divisionValue division: Float, left: Float, right: Float) -> Float {
    if division == right {
        if left == right {
            return 0
        } else {
            return Float.greatestFiniteMagnitude
        }
    }
    
    return (division - left) / (right - division)
}
