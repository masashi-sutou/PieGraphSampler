//
//  MainViewController.swift
//  PieGraphSampler
//
//  Created by 須藤将史 on 2018/08/23.
//  Copyright © 2018年 須藤将史. All rights reserved.
//

import UIKit

final class MainViewController: UITableViewController {
    
    let graphs: [UIView.Type] = [PieGraphView.self, PieGraphAnimationView.self]
    let titles: [String] = [PieGraphView.className, PieGraphAnimationView.className]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        title = "PieGraphSampler"
        tableView.rowHeight = 330
        let nib = UINib(nibName: MainViewCell.className, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: MainViewCell.className)
        
        let refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return graphs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MainViewCell.className, for: indexPath) as? MainViewCell else { return UITableViewCell() }
        let graphView: UIView = graphs[indexPath.item].init(frame: cell.graphView.bounds)
        graphView.isUserInteractionEnabled = false
        graphView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.graphView.addSubview(graphView)
        cell.titleLabel.text = titles[indexPath.item]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let next = GraphViewController(xibName: titles[indexPath.item])
        next.title = titles[indexPath.item]
        navigationController?.pushViewController(next, animated: true)
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        
        tableView.reloadData()
        sender.endRefreshing()
    }
}
