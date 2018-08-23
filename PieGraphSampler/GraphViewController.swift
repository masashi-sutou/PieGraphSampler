//
//  GraphViewController.swift
//  PieGraphSampler
//
//  Created by 須藤将史 on 2018/08/23.
//  Copyright © 2018年 須藤将史. All rights reserved.
//

import UIKit

final class GraphViewController: UIViewController {
    
    private let xibName: String
    
    init(xibName: String) {
        
        self.xibName = xibName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        
        let nib = UINib(nibName: xibName, bundle: nil)
        self.view = nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "設定", style: .done, target: self, action: #selector(tappedRightBarButtonItem(_:)))
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (_) in
            
            self.view.frame.size = size
            
            switch self.xibName {
            case PieGraphView.className:
                self.view.setNeedsDisplay()
            case PieGraphAnimationView.className:
                (self.view as? PieGraphAnimationView)?.setNeedsGraphLayout()
            default:
                break
            }
        }, completion: { (_) in
        })
    }
    
    @objc private func tappedRightBarButtonItem(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        switch self.xibName {
        case PieGraphView.className:
            guard let pieGraphView = self.view as? PieGraphView else {
                return
            }
            
            if pieGraphView.isDonuts {
                alert.addAction(UIAlertAction(title: "ドーナッツをやめる", style: .default, handler: { (_) in
                    pieGraphView.isDonuts = false
                    pieGraphView.setNeedsDisplay()
                }))
            } else {
                alert.addAction(UIAlertAction(title: "ドーナッツにする", style: .default, handler: { (_) in
                    pieGraphView.isDonuts = true
                    pieGraphView.setNeedsDisplay()
                }))
            }
            
        case PieGraphAnimationView.className:
            guard let pieGraphAnimationView = self.view as? PieGraphAnimationView else {
                return
            }
            
            if pieGraphAnimationView.isDonuts {
                alert.addAction(UIAlertAction(title: "ドーナッツをやめる", style: .default, handler: { (_) in
                    pieGraphAnimationView.isDonuts = false
                    pieGraphAnimationView.setNeedsGraphLayout()
                }))
            } else {
                alert.addAction(UIAlertAction(title: "ドーナッツにする", style: .default, handler: { (_) in
                    pieGraphAnimationView.isDonuts = true
                    pieGraphAnimationView.setNeedsGraphLayout()
                }))
            }
            
        default:
            break
        }
        
        switch self.xibName {
        case PieGraphAnimationView.className:
            guard let pieGraphAnimationView = self.view as? PieGraphAnimationView else {
                return
            }
            
            switch pieGraphAnimationView.infinityRotationStatus {
            case .ready:
                alert.addAction(UIAlertAction(title: "スタート", style: .default, handler: { (_) in
                    pieGraphAnimationView.startInfinityRotate()
                }))
            case .working:
                alert.addAction(UIAlertAction(title: "ストップ", style: .default, handler: { (_) in
                    pieGraphAnimationView.stopInfinityRotate()
                }))
            case .stop:
                alert.addAction(UIAlertAction(title: "リスタート", style: .default, handler: { (_) in
                    pieGraphAnimationView.resumeInfinityRotate()
                }))
            }
        default:
            break
        }
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
