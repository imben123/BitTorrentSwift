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
    
    let tableView = UITableView()
    let torrentClient: TorrentClient
    
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
}

extension TorrentViewController: UITableViewDataSource {
    
    enum TableViewRow: Int {
        case name = 0
        case size, percentageComplete, status, seeds, peers, downloadSpeed, uploadSpeed, eta, uploaded
        
        static var numberOfRows: Int = 10
        
        var titleText: String {
            switch self {
            case .name:
                return "Name"
            case .size:
                return "Size"
            case .percentageComplete:
                return "Completed"
            case .status:
                return "Status"
            case .seeds:
                return "Seeds"
            case .peers:
                return "Peers"
            case .downloadSpeed:
                return "↓ Speed"
            case .uploadSpeed:
                return "↑ Speed"
            case .eta:
                return "ETA"
            case .uploaded:
                return "Uploaded"
            }
        }
        
        func value(using client: TorrentClient) -> String {
            switch self {
            case .name:
                return client.metaInfo.info.name
            case .size:
                return bytesToString(client.metaInfo.info.length)
            case .percentageComplete:
                let percentageComplete = client.progress.percentageComplete
                let progressString = twoDecimalPlaceFloat(percentageComplete * 100)
                return "\(progressString)%"
            case .status:
                return client.status.toString
//            case .seeds:
//                return "Seeds"
//            case .peers:
//                return "Peers"
//            case .downloadSpeed:
//                return "↓ Speed"
//            case .uploadSpeed:
//                return "↑ Speed"
//            case .eta:
//                return "ETA"
//            case .uploaded:
//                return "Uploaded"
            default:
                return "????"
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableViewRow.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
        guard let row = TableViewRow(rawValue: indexPath.row) else { return }
        cell.textLabel?.text = row.titleText
        cell.detailTextLabel?.text = row.value(using: torrentClient)
    }
}
