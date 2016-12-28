//
//  DemoViewController.swift
//  ZLPhotographerDemo
//
//  Created by 朱子澜 on 16/12/21.
//  Copyright © 2016年 杉玉府. All rights reserved.
//

import UIKit

class DemoViewController: UIViewController {
    
    // MARK: Control
    
    fileprivate weak var navigationView: UIView!
    fileprivate weak var contentTableView: UITableView!
    
    // MARK: Init

    override func viewDidLoad() {
        super.viewDidLoad()
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        self.navigationView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 64))
            view.backgroundColor = UIColor.white
            
            let label = UILabel(frame: CGRect(x: 0, y: 20, width: screenWidth, height: 44))
            label.font = UIFont.systemFont(ofSize: 17)
            label.text = "Zilan's Photographer Demo"
            label.textColor = UIColor.black
            label.textAlignment = .center
            view.addSubview(label)
            
            let separator = CALayer()
            separator.frame = CGRect(x: 0, y: view.frame.height - 1, width: screenWidth, height: 1)
            separator.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
            view.layer.addSublayer(separator)
            
            self.view.addSubview(view)
            return view
        } ()
        
        self.contentTableView = {
            let originY = self.navigationView.frame.maxY
            let tableView = UITableView(frame: CGRect(x: 0, y: originY, width: screenWidth, height: screenHeight - originY), style: .grouped)
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.contentCellIdentifier)
            tableView.dataSource = self
            tableView.delegate = self
            self.view.addSubview(tableView)
            return tableView
        } ()
    }

}

extension DemoViewController {
    
    func openPhotographController() {
        let controller = ZLPhotoPickerController()
        let navigationController = UINavigationController(rootViewController: controller)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func openPhotoStoreController() {
        ldb("photo store")
    }
    
    func openWebsite() {
        ldb("")
    }
}

extension DemoViewController: UITableViewDataSource, UITableViewDelegate {
    
    private var contentDataSource: [[(icon: String, title: String, action: Selector)]] {
        return [
            [
                ("main_photograph", "Photograph", #selector(openPhotographController)),
                ("main_storage", "In-app Album", #selector(openPhotoStoreController))
            ],
            [
                ("main_website", "Website", #selector(openWebsite))
            ]
        ]
    }
    
    var contentCellIdentifier: String {
        return "DemoViewController.CellIdentifier"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.contentDataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contentDataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.contentCellIdentifier, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let indexedDataSource = self.contentDataSource[indexPath.section][indexPath.row]
        cell.imageView?.image = UIImage(named: indexedDataSource.icon)
        cell.textLabel?.text = indexedDataSource.title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let indexedDataSource = self.contentDataSource[indexPath.section][indexPath.row]
        UIControl().sendAction(indexedDataSource.action, to: self, for: nil)
    }
}

func ldb(_ object: Any?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
    let message = (object == nil) ? "" : "\(object!)"
    let splittedFilename = fileName.components(separatedBy: "/").last ?? ""
    print("\(splittedFilename): \(lineNumber) [\(functionName)] \(message)")
}
