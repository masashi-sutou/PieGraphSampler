//
//  PieGraphView.swift
//  PieGraphSampler
//
//  Created by 須藤将史 on 2018/08/23.
//  Copyright © 2018年 須藤将史. All rights reserved.
//

import UIKit
import CoreGraphics

@IBDesignable
final class PieGraphView: UIView {
    
    var isDonuts: Bool = true
    var selectedIndex: Int?
    private var centerCircleRadiusScale: Double {
        return isDonuts ? 0.4 : 0.2
    }
    private var centerCirclePath: UIBezierPath?
    private var arcPaths: [UIBezierPath] = []
    private let graphData: [GraphData] = GraphData.proposal
    private let graphDataTotal: Double
    
    override init(frame: CGRect) {
        
        graphDataTotal = graphData.reduce(0, { $0 + $1.value })
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        graphDataTotal = graphData.reduce(0, { $0 + $1.value })
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        
        super.draw(rect)
        
        // 背景色
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.lightGray.cgColor)
        context.fill(rect)
        
        guard !graphData.isEmpty else {
            // 中央に白い円を置く
            centerCirclePath = UIBezierPath(arcCenter: centerPoint, radius: CGFloat(radius), startAngle: CGFloat(0.0.radianValue), endAngle: CGFloat(360.0.radianValue), clockwise: true)
            UIColor.white.setFill()
            centerCirclePath?.fill()
            "データがありません".drawCentering(origin: centerPoint, color: .black, font: .systemFont(ofSize: 11))
            return
        }
        
        arcPaths.removeAll()
        
        // 0時の位置から開始
        var startRad: Double = -90.0.radianValue
        
        for (index, data) in graphData.enumerated() {
            // 割合
            let ratio: Double = 360 * (data.value / graphDataTotal)
            // ラジアン（略：rad）
            let rad: Double = ratio.radianValue
            // 扇型の半径
            let arcRadius: Double = (index == selectedIndex) ? radius * 1.1 : radius
            // 扇型
            let arcPath = UIBezierPath(arcCenter: centerPoint, radius: CGFloat(arcRadius), startAngle: CGFloat(startRad), endAngle: CGFloat(startRad + rad), clockwise: true)
            arcPath.addLine(to: centerPoint)
            arcPath.close()
            arcPath.lineWidth = (graphData.count > 1) ? 1 : 0
            data.color.setFill()
            UIColor.white.setStroke()
            arcPath.fill()
            arcPath.stroke()
            arcPaths.append(arcPath)
            
            // 扇型のテキストの位置
            let arcTextRadius: Double = (radius + radius * centerCircleRadiusScale) / 2
            let arcTextPoint: CGPoint = self.arcTextPoint(arcCenter: centerPoint, radian: startRad + rad / 2, radius: arcTextRadius)
            // テキスト描画
            data.title.drawCentering(origin: arcTextPoint, color: .white, font: .boldSystemFont(ofSize: 11))
            
            startRad += rad
        }
        
        if isDonuts {
            // 中央に白い円を置く
            centerCirclePath = UIBezierPath(arcCenter: centerPoint, radius: CGFloat(radius * centerCircleRadiusScale), startAngle: CGFloat(0.0.radianValue), endAngle: CGFloat(360.0.radianValue), clockwise: true)
            UIColor.white.setFill()
            centerCirclePath?.fill()
            let fontSize: CGSize = "2018".size(font: .systemFont(ofSize: 11))
            let tailpoint: CGPoint = "2018".drawCentering(origin: CGPoint(x: centerPoint.x, y: centerPoint.y - fontSize.height / 2), color: .black, font: .systemFont(ofSize: 11))
            "iOSDC CfP".drawCentering(origin: CGPoint(x: centerPoint.x, y: tailpoint.y), color: .black, font: .systemFont(ofSize: 11))
        } else {
            centerCirclePath = nil
        }
    }
    
    // MARK: - タッチイベント
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touchLocation: CGPoint = touches.first?.location(in: self) else {
            selectedIndex = nil
            setNeedsDisplay()
            return
        }
        
        if isDonuts {
            guard let centerCirclePath = self.centerCirclePath, !centerCirclePath.contains(touchLocation) else {
                // 中央の円を押した
                selectedIndex = nil
                setNeedsDisplay()
                return
            }
        }
        
        for (index, path) in arcPaths.enumerated() {
            if path.contains(touchLocation) {
                // 扇型を押した
                selectedIndex = (index == selectedIndex) ? nil : index
                setNeedsDisplay()
                return
            }
        }
        
        // 円グラフの外側をタップ
        selectedIndex = nil
        setNeedsDisplay()
    }
}
