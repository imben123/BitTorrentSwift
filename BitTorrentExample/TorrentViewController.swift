//
//  TorrentViewController.swift
//  BitTorrentExample
//
//  Created by Ben Davis on 13/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import UIKit
import BitTorrent

class TorrentViewController: UIViewController {
    
    static let refreshRate: TimeInterval = 1
    
    let tableView = UITableView()
    let torrentClient: TorrentClient
    
    lazy var refreshTimer: Timer = {
        return Timer.scheduledTimer(timeInterval: TorrentViewController.refreshRate,
                                    target: self,
                                    selector: #selector(TorrentViewController.timerFired),
                                    userInfo: nil,
                                    repeats: true)
    }()
    
    init(torrentClient: TorrentClient) {
        self.torrentClient = torrentClient
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        if tableView.contentInset == .zero {
            tableView.contentInset = view.safeAreaInsets
            tableView.contentOffset = .zero
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshTimer.fire()
    }
    
    @objc private func timerFired() {
        tableView.reloadData()
    }
}

extension TorrentViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return torrentClient.status == .stopped ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return TorrentInfoRowData.numberOfRows
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return cellForTorrentInfoSection(at: indexPath, tableView: tableView)
        } else {
            let startCell = UITableViewCell(style: .default, reuseIdentifier: nil)
            startCell.textLabel?.text = "Start"
            startCell.textLabel?.textAlignment = .center
            startCell.textLabel?.textColor = .blue
            return startCell
        }
    }
    
    func cellForTorrentInfoSection(at indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        let cellReuseIdentifier = "Cell"
        
        let cell: UITableViewCell
        if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) {
            cell = dequeuedCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cellReuseIdentifier)
        }
        
        setupCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func setupCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let row = TorrentInfoRowData(rawValue: indexPath.row) else { return }
        cell.textLabel?.text = row.titleText
        cell.detailTextLabel?.text = row.value(using: torrentClient)
    }
}

extension TorrentViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 25
        } else {
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        cell.setSelected(false, animated: false)
        
        if indexPath.section == 1 {
            torrentClient.start()
            tableView.reloadData()
        }
    }
    
}
