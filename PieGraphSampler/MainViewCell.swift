//
//  MainViewCell.swift
//  PieGraphSampler
//
//  Created by 須藤将史 on 2018/08/23.
//  Copyright © 2018年 須藤将史. All rights reserved.
//

import UIKit

final class MainViewCell: UITableViewCell {
    
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        graphView.subviews.forEach({ $0.removeFromSuperview() })
    }
}
