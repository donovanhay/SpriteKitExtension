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
