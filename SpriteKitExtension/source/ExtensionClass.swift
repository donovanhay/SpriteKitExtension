//
//  ExtensionClass.swift
//  SpriteKitExtension
//
//  Created by HanHaikun on 2020/2/10.
//  Copyright © 2020 HanHaikun. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let deltaX = point.x - x
        let deltaY = point.y - y
        return hypot(deltaX, deltaY)
    }
    func move(by: CGVector) -> CGPoint {
        return CGPoint(x: x + by.dx, y: y + by.dy)
    }
}

extension CGVector {
    var length: Double {
        get {
            let dx = Double(self.dx)
            let dy = Double(self.dy)
            return sqrt(dx * dx + dy * dy)
        }
    }
    
    /// Normalizing
    var normalizer: CGVector {
        get {
            return self / length
        }
    }
    
    var angle: Double {
        get {
            return atan2(Double(dy), Double(dx))
        }
    }
    
    init(startPoint: CGPoint, endPoint: CGPoint) {
        dx = endPoint.x - startPoint.x
        dy = endPoint.y - startPoint.y
    }
    
    static func + (left: CGVector, right: CGVector) -> CGVector {
        return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
    }
    
    static func += (left: inout CGVector, right: CGVector) {
        left = left + right
    }
    
    static func * (vector: CGVector, scalar: Double) -> CGVector {
        return CGVector(dx: Double(vector.dx) * scalar, dy: Double(vector.dy) * scalar)
    }
    
    static func * (scalar: Double, vector: CGVector) -> CGVector {
        return CGVector(dx: Double(vector.dx) * scalar, dy: Double(vector.dy) * scalar)
    }
    
    static func *= (vector: inout CGVector, scalar: Double) {
        vector = vector * scalar
    }
    
    static func - (left: CGVector, right: CGVector) -> CGVector {
        return CGVector(dx: left.dx - right.dx, dy: left.dy - right.dy)
    }
    
    static func -= (left: inout CGVector, right: CGVector) {
        left = left - right
    }
    
    static func / (left: CGVector, scalar: Double) -> CGVector {
        return CGVector(dx: Double(left.dx) / scalar, dy: Double(left.dy) / scalar)
    }
    
    static func /= (vector: inout CGVector, scalar: Double) {
        vector = vector / scalar
    }
}
