//
//  UnitBezier.swift
//  PieGraphSampler
//
//  Created by 須藤将史 on 2018/08/23.
//  Copyright © 2017年 Keisuke Shoji. All rights reserved.
//

import CoreGraphics

/// Solver for cubic bezier curve with implicit control points at (0.0, 0.0) and (1.0, 1.0)
struct UnitBezier {
    private let a: CGPoint
    private let b: CGPoint
    private let c: CGPoint
    
    init(p1: CGPoint, p2: CGPoint) {
        // pre-calculate the polynomial coefficients
        // First and last control points are implied to be (0.0, 0.0) and (1.0, 1.0)
        c = CGPoint(x: 3.0 * p1.x,
                    y: 3.0 * p1.y)
        b = CGPoint(x: 3.0 * (p2.x - p1.x) - c.x,
                    y: 3.0 * (p2.y - p1.y) - c.y)
        a = CGPoint(x: 1.0 - c.x - b.x,
                    y: 1.0 - c.y - b.y)
    }
    
    private func sampleCurveX(t: CGFloat) -> CGFloat {
        return ((a.x * t + b.x) * t + c.x) * t
    }
    
    private func sampleCurveY(t: CGFloat) -> CGFloat {
        return ((a.y * t + b.y) * t + c.y) * t
    }
    
    private func sampleCurveDerivativeX(t: CGFloat) -> CGFloat {
        return (3.0 * a.x * t + 2.0 * b.x) * t + c.x
    }
    
    private func solveCurveX(t: CGFloat) -> CGFloat {
        let epsilon: CGFloat = 0.000001
        var t0: CGFloat = 0.0
        var t1: CGFloat = 1.0
        var t2: CGFloat = t
        var x2: CGFloat = 0.0
        
        // First try a few iterations of Newton's method -- normally very fast.
        for _ in 0 ..< 8 {
            x2 = sampleCurveX(t: t2) - t
            if abs(x2) < epsilon {
                return t2
            }
            let d2: CGFloat = sampleCurveDerivativeX(t: t2)
            if abs(d2) < epsilon {
                break
            }
            t2 = t2 - x2 / d2
        }
        
        // No solution found - use bi-section
        t2 = t
        
        if t2 < t0 {
            return t0
        } else if t2 > t1 {
            return t1
        }
        
        while t0 < t1 {
            x2 = sampleCurveX(t: t2)
            if abs(x2 - t) < epsilon {
                return t2
            } else if t > x2 {
                t0 = t2
            } else {
                t1 = t2
            }
            t2 = (t1 - t0) / 2.0 + t0
        }
        
        // Give up
        return t2
    }
    
    // Find new T as a function of Y along curve X
    func solve(t: CGFloat) -> CGFloat {
        return sampleCurveY(t: solveCurveX(t: t))
    }
}
