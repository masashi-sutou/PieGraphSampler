//
//  AnimationCurve.swift
//  PieGraphSampler
//
//  Created by 須藤将史 on 2018/08/23.
//  Copyright © 2017年 Keisuke Shoji. All rights reserved.
//

import CoreGraphics

enum GraphAnimationCurve {
    case linear, ease, easeIn, easeOut, easeInOut, original(CGPoint, CGPoint)
    
    var p1: CGPoint {
        switch self {
        case .linear:             return .zero
        case .ease:               return CGPoint(x: 0.25, y: 0.1)
        case .easeIn:             return CGPoint(x: 0.42, y: 0.0)
        case .easeOut:            return .zero
        case .easeInOut:          return CGPoint(x: 0.42, y: 0.0)
        case .original(let p, _): return p
        }
    }
    
    var p2: CGPoint {
        switch self {
        case .linear:             return CGPoint(x: 1.0, y: 1.0)
        case .ease:               return CGPoint(x: 0.25, y: 1.0)
        case .easeIn:             return CGPoint(x: 1.0, y: 1.0)
        case .easeOut:            return CGPoint(x: 0.58, y: 1.0)
        case .easeInOut:          return CGPoint(x: 0.58, y: 1.0)
        case .original(_, let p): return p
        }
    }
}
