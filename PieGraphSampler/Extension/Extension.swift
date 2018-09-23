//
//  Extension.swift
//  PieGraphSampler
//
//  Created by 須藤将史 on 2018/08/23.
//  Copyright © 2018年 須藤将史. All rights reserved.
//

import UIKit

extension UIView {
    
    /*
     * 中心
     */
    
    var centerPoint: CGPoint {
        guard bounds.width != bounds.height else {
            // 正方形
            return center
        }
        
        // 長方形
        if bounds.width > bounds.height {
            let size = CGSize(width: bounds.height, height: bounds.height)
            return UIView(frame: CGRect(origin: CGPoint(x: bounds.origin.x + (bounds.width - bounds.height) / 2, y: bounds.origin.y), size: size)).center
        } else {
            let size = CGSize(width: bounds.width, height: bounds.width)
            return UIView(frame: CGRect(origin: CGPoint(x: bounds.origin.x, y: bounds.origin.y + (bounds.height - bounds.width) / 2), size: size)).center
        }
    }
    
    /*
     * 直径
     */
    
    private var diameter: Double {
        let diameter = min(bounds.width, bounds.height)
        return Double(diameter * 0.75)
    }
    
    /*
     * 半径
     */
    
    var radius: Double {
        return diameter / 2
    }
    
    /*
     * 扇型のテキストの位置
     */
    
    func arcTextPoint(arcCenter: CGPoint, radian: Double, radius: Double) -> CGPoint {
        // 半径の大きさで扇型の内側か外側にテキストをレイアウト
        let x: Double = cos(radian) * radius
        let y: Double = sin(radian) * radius
        return CGPoint(x: arcCenter.x + CGFloat(x), y: arcCenter.y + CGFloat(y))
    }
}

extension Double {
    
    /*
     * 角度(degree) -> 弧度(radian)
     * radian（弧度 略:rad）= degrees（角度 略:deg） * PI（π）/ 180
     */
    
    var radianValue: Double {
        if #available(iOS 10.0, *) {
            let degreeMeasurement = Measurement(value: self, unit: UnitAngle.degrees)
            let radianMeasurement = degreeMeasurement.converted(to: .radians)
            return radianMeasurement.value
        } else {
            return self / 180 * .pi
        }
    }

    /*
     * 弧度(radian) -> 角度(degree)
     */
    
    var degreeValue: Double {
        if #available(iOS 10.0, *) {
            let radianMeasurement = Measurement(value: self, unit: UnitAngle.radians)
            let degreeMeasurement = radianMeasurement.converted(to: .degrees)
            return degreeMeasurement.value
        } else {
            return self * 180 / .pi
        }
    }
}

extension String {
    
    /*
     * 文字列を中央に描画
     */
    
    @discardableResult
    func drawCentering(origin: CGPoint, color: UIColor, font: UIFont) -> CGPoint {
        
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color, .font: font]
        let bounding = (self as NSString).boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        (self as NSString).draw(at: CGPoint(x: origin.x - bounding.width / 2, y: origin.y - bounding.height / 2), withAttributes: attributes)
        let tailPoint = CGPoint(x: origin.x + ceil(bounding.width), y: origin.y + ceil(bounding.height))
        return tailPoint
    }
    
    /*
     * 文字列のサイズ
     */
    
    func size(font: UIFont) -> CGSize {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left
        
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        
        let bounding = (self as NSString).boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        return CGSize(width: ceil(bounding.width), height: ceil(bounding.height))
    }
}

extension UIColor {
    
    /*
     * ランダムにカラー生成
     */
    
    static var random: UIColor {
        return UIColor(red:   .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue:  .random(in: 0...1),
                       alpha: 1.0)
    }
}

extension NSObjectProtocol {
    static var className: String {
        return String(describing: Self.self)
    }
}
