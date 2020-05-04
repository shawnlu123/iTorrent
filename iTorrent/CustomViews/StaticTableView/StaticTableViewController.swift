//
//  StaticTableViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10.11.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class StaticTableViewController: ThemedUIViewController {
    var tableView: StaticTableView!
    var data: [Section] = [] {
        didSet {
            tableView?.data = data
        }
    }

    init() {
        super.init(nibName: nil, bundle: Bundle.main)
        setup(style: .grouped)
    }

    init(style: UITableView.Style) {
        super.init(nibName: nil, bundle: Bundle.main)
        setup(style: style)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup(style: UITableView.Style = .grouped) {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        tableView = StaticTableView(frame: view.frame, style: style)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.colorType = .secondary
        view.addSubview(tableView)
        tableView.data = data
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //tableView.reloadData()
    }
}
