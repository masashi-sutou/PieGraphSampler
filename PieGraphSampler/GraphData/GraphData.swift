//
//  GraphData.swift
//  PieGraphSampler
//
//  Created by 須藤将史 on 2018/08/23.
//  Copyright © 2018年 須藤将史. All rights reserved.
//

import UIKit

struct GraphData {
    let value: Double
    let title: String
    let color: UIColor
    
    init(value: Double = Double.random(in: 5...25), title: String = "", color: UIColor = UIColor.random) {
        self.value = value
        self.title = title
        self.color = color
    }
    
    static var random: [GraphData] {
        var random: [GraphData] = []
        let count = Int.random(in: 0...5)
        guard count > 0 else {
            return random
        }
        
        for _ in 1...count {
            random.append(GraphData())
        }
        // 降順
        return random.sorted { $0.value > $1.value }
    }
    
    static var proposal: [GraphData] {
        return [GraphData(value: 410, title: "非採択", color: UIColor.darkGray), GraphData(value: 130, title: "採択", color: UIColor.blue)]
    }
}
