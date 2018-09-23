//
//  PieGraphAnimationView.swift
//  PieGraphSampler
//
//  Created by 須藤将史 on 2018/08/23.
//  Copyright © 2018年 須藤将史. All rights reserved.
//

import UIKit
import CoreGraphics

enum InfinityRotationAnimation {
    case ready
    case working
    case stop
    
    static let key: String = "rotationAnimation"
    static let keyPath: String = "transform.rotation"
}

final class PieGraphAnimationView: UIView {
    
    // グラフの状態
    var isDonuts: Bool = true
    var selectedIndex: Int?
    private var centerCircleRadiusScale: Double {
        return isDonuts ? 0.4 : 0.2
    }
    private(set) var infinityRotationStatus: InfinityRotationAnimation = .ready {
        didSet {
            switch infinityRotationStatus {
            case .ready, .stop:
                isUserInteractionEnabled = true
            case .working:
                isUserInteractionEnabled = false
            }
        }
    }
    
    // グラフデータ
    private let graphData: [GraphData] = GraphData.random
    private let graphDataTotal: Double
    
    // レイヤー
    private var centerCircleLayer: CAShapeLayer?
    private var centerCircleTextLayer: CATextLayer?
    private var arcLayers: [CAShapeLayer] = []
    private var arcTextLayers: [CATextLayer] = []
    
    // 表示アニメーション
    private let curve: GraphAnimationCurve = .ease
    private lazy var unitBezier = UnitBezier(p1: curve.p1, p2: curve.p2)
    private var displayLink: CADisplayLink?
    private var startTimeInterval: CFTimeInterval?
    
    // ドラッグで回転
    private var startDragPoint: CGPoint = .zero
    private var currentRotationRadian: CGFloat = CGFloat(-90.0.radianValue)
    
    // MARK: - 初期化
    
    override init(frame: CGRect) {
        
        graphDataTotal = graphData.reduce(0, { $0 + $1.value })
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        graphDataTotal = graphData.reduce(0, { $0 + $1.value })
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        
        guard !graphData.isEmpty else {
            let centerCircleLayer = CAShapeLayer()
            centerCircleLayer.fillColor = UIColor.white.cgColor
            self.centerCircleLayer = centerCircleLayer
            
            let text = "データがありません"
            let font = UIFont.systemFont(ofSize: 11)
            let textLayer: CATextLayer = CATextLayer()
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.string = text
            textLayer.foregroundColor = UIColor.black.cgColor
            textLayer.fontSize = font.pointSize
            textLayer.font = font
            textLayer.frame = CGRect(origin: .zero, size: text.size(font: font))
            textLayer.alignmentMode = .center
            centerCircleLayer.addSublayer(textLayer)
            self.centerCircleTextLayer = textLayer
            self.centerCircleLayer?.isHidden = true
            self.centerCircleTextLayer?.isHidden = true
            self.layer.addSublayer(centerCircleLayer)
            
            /*
             * DeployMent Target が10.0の場合、layoutSubviewsの処理が遅くなる
             * DeployMent Target が11.0の場合、layoutSubviewsの処理が速くなり遅延実行しなくても意図したレイアウトになる
             */
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.setupPathAnimation()
            }
            
            return
        }
        
        setupGesture()
        
        graphData.forEach {
            let arcLayer = CAShapeLayer()
            arcLayer.fillColor = $0.color.cgColor
            arcLayer.strokeColor = UIColor.white.cgColor
            arcLayer.lineWidth = (graphData.count > 1) ? 1 : 0
            arcLayers.append(arcLayer)
            
            let text = String(format: "%0.1f%%", ($0.value / graphDataTotal) * 100)
            let font = UIFont.boldSystemFont(ofSize: 11)
            let textLayer: CATextLayer = CATextLayer()
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.string = text
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.fontSize = font.pointSize
            textLayer.font = font
            textLayer.frame = CGRect(origin: .zero, size: text.size(font: font))
            textLayer.isHidden = true
            textLayer.alignmentMode = .center
            arcLayer.addSublayer(textLayer)
            arcTextLayers.append(textLayer)
            self.layer.addSublayer(arcLayer)
        }
        
        let centerCircleLayer = CAShapeLayer()
        centerCircleLayer.fillColor = UIColor.white.cgColor
        self.centerCircleLayer = centerCircleLayer
        
        let text = "2018/09/02"
        let font = UIFont.systemFont(ofSize: 11)
        let textLayer: CATextLayer = CATextLayer()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.string = text
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.fontSize = font.pointSize
        textLayer.font = font
        textLayer.frame = CGRect(origin: .zero, size: text.size(font: font))
        textLayer.alignmentMode = .center
        centerCircleLayer.addSublayer(textLayer)
        self.centerCircleTextLayer = textLayer
        self.centerCircleLayer?.isHidden = true
        self.centerCircleTextLayer?.isHidden = true
        self.layer.addSublayer(centerCircleLayer)
        
        /*
         * DeployMent Target が10.0の場合、layoutSubviewsの処理が遅くなる
         * DeployMent Target が11.0の場合、layoutSubviewsの処理が速くなり遅延実行しなくても意図したレイアウトになる
         */
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupPathAnimation()
        }
    }
    
    // MARK: - ジェスチャー登録
    
    private func setupGesture() {
        
        let signleTapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedView(_:)))
        signleTapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(signleTapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        addGestureRecognizer(panGesture)
    }
    
    // MARK: - 表示アニメーション
    
    private func setupPathAnimation() {
        
        startTimeInterval = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updatePathAnimation(_:)))
        displayLink?.add(to: .current, forMode: RunLoop.Mode.common)
    }
    
    @objc private func updatePathAnimation(_ sender: CADisplayLink) {
        
        guard let startTimeInterval = self.startTimeInterval else { return }
        
        // アニメーションは1.0秒
        let duration: TimeInterval = 1.0
        let elapsed: Double = CACurrentMediaTime() - startTimeInterval
        
        // アニメーション進捗率を計算
        let progress: CGFloat = (elapsed > duration) ? 1.0 : CGFloat(elapsed / duration)
        let animationProgress: CGFloat = unitBezier.solve(t: progress)
        
        // グラフを描画
        setup(progress: Double(animationProgress))
        if progress >= 1.0 {
            sender.invalidate()
        }
    }
    
    // MARK: - 無限回転アニメーション
    
    func startInfinityRotate() {
        
        guard infinityRotationStatus == .ready else {
            return
        }
        
        let rotationAnimation = CABasicAnimation(keyPath: InfinityRotationAnimation.keyPath)
        rotationAnimation.beginTime = 0
        rotationAnimation.fromValue = 0.0.radianValue
        rotationAnimation.toValue = 360.0.radianValue
        rotationAnimation.duration = 0
        rotationAnimation.speed = 0.5
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.autoreverses = false
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.fillMode = .forwards
        arcLayers.forEach {
            $0.add(rotationAnimation, forKey: InfinityRotationAnimation.key)
        }
        
        let reverseRotationAnimation = CABasicAnimation(keyPath: InfinityRotationAnimation.keyPath)
        reverseRotationAnimation.beginTime = 0
        reverseRotationAnimation.fromValue = 360.0.radianValue
        reverseRotationAnimation.toValue = 0.0.radianValue
        reverseRotationAnimation.duration = 0
        reverseRotationAnimation.speed = 0.5
        reverseRotationAnimation.repeatCount = .infinity
        reverseRotationAnimation.autoreverses = false
        reverseRotationAnimation.isRemovedOnCompletion = false
        reverseRotationAnimation.fillMode = .forwards
        arcTextLayers.forEach {
            $0.add(reverseRotationAnimation, forKey: InfinityRotationAnimation.key)
        }
        
        infinityRotationStatus = .working
    }
    
    func stopInfinityRotate() {
        
        guard infinityRotationStatus == .working else {
            return
        }
        
        arcLayers.forEach {
            let pausedTime = $0.convertTime(CACurrentMediaTime(), from: nil)
            $0.speed = 0.0
            $0.timeOffset = pausedTime
        }
        
        arcTextLayers.forEach {
            let pausedTime = $0.convertTime(CACurrentMediaTime(), from: nil)
            $0.speed = 0.0
            $0.timeOffset = pausedTime
        }
        
        infinityRotationStatus = .stop
    }
    
    func resumeInfinityRotate() {
        
        guard infinityRotationStatus == .stop else {
            return
        }
        
        arcLayers.forEach {
            let pauseTime = $0.timeOffset
            $0.speed = 1.0
            $0.timeOffset = 0.0
            $0.beginTime = 0.0
            let timeSincePause: CFTimeInterval = $0.convertTime(CACurrentMediaTime(), from: nil) - pauseTime
            $0.beginTime = timeSincePause
        }
        
        arcTextLayers.forEach {
            let pauseTime = $0.timeOffset
            $0.speed = 1.0
            $0.timeOffset = 0.0
            $0.beginTime = 0.0
            let timeSincePause: CFTimeInterval = $0.convertTime(CACurrentMediaTime(), from: nil) - pauseTime
            $0.beginTime = timeSincePause
        }
        
        infinityRotationStatus = .working
    }
    
    private func applyAnimatedTransformBeforeRemoveAnimation() {
        
        guard infinityRotationStatus == .stop else {
            return
        }
        
        // 無限回転が停止した座標に変換した後にアニメーション解除
        arcLayers.forEach {
            if let transform = $0.presentation()?.affineTransform() {
                $0.setAffineTransform(transform)
            }
            
            $0.removeAllAnimations()
            $0.speed = 1.0
        }
        // 無限回転が停止した座標に変換した後にアニメーション解除
        arcTextLayers.forEach {
            if let transform = $0.presentation()?.affineTransform() {
                $0.setAffineTransform(transform)
            }
            
            $0.removeAllAnimations()
            $0.speed = 1.0
        }
        // アニメーション解除したのでスタートに戻す
        infinityRotationStatus = .ready
    }
    
    // MARK: - グラフ作成
    
    private func setup(progress: Double, rotationRadian: Double = -90.0.radianValue) {
        
        guard 0...1 ~= progress else {
            return
        }
        
        guard !graphData.isEmpty else {
            // 中央に白い円を置く
            let centerCirclePath: UIBezierPath = UIBezierPath(arcCenter: .zero, radius: CGFloat(radius * progress), startAngle: CGFloat(-90.0.radianValue), endAngle: CGFloat(270.0.radianValue), clockwise: true)
            centerCirclePath.close()
            centerCircleLayer?.path = centerCirclePath.cgPath
            centerCircleTextLayer?.position = .zero
            centerCircleLayer?.isHidden = false
            centerCircleTextLayer?.isHidden = progress < 1.0
            return
        }
        
        // 0時の位置から開始
        var startRad: Double = rotationRadian
        
        for (index, data) in graphData.enumerated() {
            // 割合
            let ratio: Double = 360 * (data.value / graphDataTotal)
            // ラジアン（略：rad）
            let rad: Double = ratio.radianValue * progress
            // 扇型の半径
            let arcRadius: Double = (index == selectedIndex) ? radius * 1.1 : radius
            
            // 扇型
            let arcPath = UIBezierPath(arcCenter: .zero, radius: CGFloat(arcRadius), startAngle: CGFloat(startRad), endAngle: CGFloat(startRad + rad), clockwise: true)
            arcPath.addLine(to: .zero)
            arcPath.close()
            
            // レイヤー
            arcLayers[index].path = arcPath.cgPath
            
            // 扇型のテキストの位置
            let arcTextRadius: Double = (radius + radius * centerCircleRadiusScale) / 2
            let arcTextPoint: CGPoint = self.arcTextPoint(arcCenter: .zero, radian: startRad + rad / 2, radius: arcTextRadius)
            
            // テキスト描画
            arcTextLayers[index].position = arcTextPoint
            arcTextLayers[index].isHidden = progress < 1.0
            
            startRad += rad
        }
        
        if isDonuts {
            // 中央に白い円を置く
            let centerCircleRadius: Double = radius * centerCircleRadiusScale
            let centerCirclePath: UIBezierPath = UIBezierPath(arcCenter: .zero, radius: CGFloat(centerCircleRadius * progress), startAngle: CGFloat(-90.0.radianValue), endAngle: CGFloat(270.0.radianValue), clockwise: true)
            centerCirclePath.addLine(to: .zero)
            centerCirclePath.close()
            centerCircleLayer?.path = centerCirclePath.cgPath
            centerCircleTextLayer?.position = .zero
        }
        
        centerCircleLayer?.isHidden = !isDonuts
        
        if progress == 1.0 {
            centerCircleTextLayer?.isHidden = !isDonuts
        }
    }
    
    // MARK: - レイアウト
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        arcLayers.forEach {
            $0.frame.origin = centerPoint
        }
        
        centerCircleLayer?.frame.origin = centerPoint
    }
    
    func setNeedsGraphLayout() {
        
        applyAnimatedTransformBeforeRemoveAnimation()
        setup(progress: 1.0, rotationRadian: Double(currentRotationRadian))
    }
    
    // MARK: - 描画
    
    override func draw(_ rect: CGRect) {
        
        super.draw(rect)
        
        // 背景色
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.lightGray.cgColor)
        context.fill(rect)
    }
    
    // MARK: - グラフを初期状態に戻す
    
    private func resetNeedsTransform() {
        
        arcLayers.forEach {
            $0.removeAllAnimations()
            $0.speed = 1.0
            $0.transform = CATransform3DIdentity
        }
        arcTextLayers.forEach {
            $0.removeAllAnimations()
            $0.speed = 1.0
            $0.transform = CATransform3DIdentity
        }
        selectedIndex = nil
        startDragPoint = .zero
        infinityRotationStatus = .ready
        currentRotationRadian = CGFloat(-90.0.radianValue)
        setup(progress: 1.0)
    }
    
    // MARK: - ジェスチャーイベント
    
    @objc private func tappedView(_ gesture: UITapGestureRecognizer) {
        
        // 画面の中心ではなくグラフの中心に合わせてタップ位置を変換
        let centerOffset = CGAffineTransform(translationX: -centerPoint.x,
                                             y: -centerPoint.y)
        let tappedPoint: CGPoint = gesture.location(in: self)
            .applying(centerOffset)
        
        if isDonuts {
            guard let centerCirclePath = self.centerCircleLayer?.path,
                !centerCirclePath.contains(tappedPoint) else {
                    // 中央の円をタップ
                    resetNeedsTransform()
                    return
            }
        }
        
        for (index, layer) in arcLayers.enumerated() {
            guard let layerPath = layer.path else {
                return
            }
            
            // 無限回転が停止した座標を取得
            guard let animatedTransform: CGAffineTransform = layer.presentation()?.affineTransform() else {
                return
            }
            
            // 無限回転が停止した座標に変換して円グラフのコピーを生成
            let copyPath = UIBezierPath(cgPath: layerPath)
            copyPath.apply(animatedTransform)
            if copyPath.contains(tappedPoint) {
                // 扇型をタップ
                selectedIndex = (index == selectedIndex) ? nil : index
                setup(progress: 1.0, rotationRadian: Double(currentRotationRadian))
                return
            }
        }
        
        // 円グラフの外側をタップ
        resetNeedsTransform()
    }
    
    @objc private func draggedView(_ gesture: UIPanGestureRecognizer) {
        
        // 画面中心ではなくグラフの中心に合わせてタップ位置を変換
        let centerOffset = CGAffineTransform(translationX: -centerPoint.x, y: -centerPoint.y)
        let dragPoint: CGPoint = gesture.location(in: self).applying(centerOffset)
        
        // ドラッグ開始の角度
        let startDragRadian: CGFloat = atan2(startDragPoint.y, startDragPoint.x)
        // ドラッグ終了の角度
        let endDragRadian: CGFloat = atan2(dragPoint.y, dragPoint.x)
        // ドラッグで移動した角度
        let dragRadian: CGFloat = endDragRadian - startDragRadian
        
        switch gesture.state {
        case .began:
            applyAnimatedTransformBeforeRemoveAnimation()
            startDragPoint = dragPoint
        case .changed:
            setup(progress: 1.0, rotationRadian: Double(dragRadian + currentRotationRadian))
            arcTextLayers.forEach { $0.isHidden = true }
        case .ended:
            startDragPoint = .zero
            currentRotationRadian += dragRadian
            arcTextLayers.forEach { $0.isHidden = false }
        default:
            break
        }
    }
}
