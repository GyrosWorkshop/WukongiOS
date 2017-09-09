//
//  ConfigViewController.swift
//  Wukong
//
//  Created by Qusic on 7/29/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Eureka

class ConfigViewController: FormViewController {

    fileprivate var data = Data()
    fileprivate struct Data {
        var listenOnly = false
        var connection = 0
        var audioQuality = 2
        var sync = ""
        var cookie = ""
    }

    init() {
        super.init(style: .grouped)
        title = "Config"
        tabBarItem = UITabBarItem(title: "Config", image: #imageLiteral(resourceName: "ConfigUnselected"), selectedImage: #imageLiteral(resourceName: "ConfigSelected"))
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        form.delegate = self
    }

    override func valueHasBeenChanged(for: BaseRow, oldValue: Any?, newValue: Any?) {
        super.valueHasBeenChanged(for: `for`, oldValue: oldValue, newValue: newValue)
        dispatchValues()
    }

    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        dispatchValues()
    }

    fileprivate func reloadForm() {
        let client = WukongClient.sharedInstance
        form.removeAll()
        form
        +++ Section()
        <<< SwitchRow(Constant.State.listenOnly.rawValue) { (row) in
            row.title = "Listen Only"
            row.value = self.data.listenOnly
        }
        <<< SwitchRow(Constant.State.connection.rawValue) { (row) in
            row.title = "Use CDN"
            row.value = self.data.connection > 0
        }
        +++ Section("Audio Quality")
        <<< SegmentedRow<String>(Constant.State.audioQuality.rawValue) { (row) in
            row.options = ["Low", "Medium", "High", "Lossless"]
            row.value = row.options[self.data.audioQuality]
        }
        +++ Section()
        <<< ButtonRow() { (row) in
            row.title = "Sync Playlist"
            row.onCellSelection({ (cell, row) in
                client.dispatchAction([.Song, .sync], [])
            })
        }
        +++ MultivaluedSection(header: "Playlist Links") { (section) in
            section.tag = Constant.State.sync.rawValue
            section.multivaluedOptions = [.Insert, .Delete, .Reorder]
            section.addButtonProvider = { (section) in
                return ButtonRow() { (row) in
                    row.title = "Add New Playlist"
                }
            }
            section.multivaluedRowToInsertAt = { (index) in
                return TextRow()
            }
            self.data.sync.components(separatedBy: "\n").filter({!$0.isEmpty}).forEach { (playlist) in
                section <<< TextRow() { (row) in
                    row.value = playlist
                }
            }
        }
        +++ MultivaluedSection(header: "Cookie Entries") { (section) in
            section.tag = Constant.State.cookie.rawValue
            section.multivaluedOptions = [.Insert, .Delete, .Reorder]
            section.addButtonProvider = { (section) in
                return ButtonRow() { (row) in
                    row.title = "Add New Cookie"
                }
            }
            section.multivaluedRowToInsertAt = { (index) in
                return TextRow()
            }
            self.data.cookie.components(separatedBy: "\n").filter({!$0.isEmpty}).forEach { (cookie) in
                section <<< TextRow() { (row) in
                    row.value = cookie
                }
            }
        }
        +++ Section()
        <<< ButtonRow() { (row) in
            row.title = "Reload Current Track"
            row.onCellSelection({ (cell, row) in
                AudioPlayer.sharedInstance.stop()
                client.dispatchAction([.Player, .reload], [true])
            })
        }
        <<< ButtonRow() { (row) in
            row.title = "Restart Virtual Machine"
            row.onCellSelection({ (cell, row) in
                AudioPlayer.sharedInstance.stop()
                client.reload()
            })
        }
    }

    private func dispatchValues() {
        let values: [String: Any] = [
            Constant.State.listenOnly.rawValue: {
                var result = data.listenOnly
                defer { data.listenOnly = result }
                guard let row = form.rowBy(tag: Constant.State.listenOnly.rawValue) as? SwitchRow else { return result }
                guard let value = row.value else { return result }
                result = value
                return result
            }(),
            Constant.State.connection.rawValue: {
                var result = data.connection
                defer { data.connection = result }
                guard let row = form.rowBy(tag: Constant.State.connection.rawValue) as? SwitchRow else { return result }
                guard let value = row.value else { return result }
                result = value ? 1 : 0
                return result
            }(),
            Constant.State.audioQuality.rawValue: {
                var result = data.audioQuality
                defer { data.audioQuality = result }
                guard let row = form.rowBy(tag: Constant.State.audioQuality.rawValue) as? SegmentedRow<String> else { return result }
                guard let value = row.value else { return result }
                guard let index = row.options.index(of: value) else { return result }
                result = index
                return result
            }(),
            Constant.State.sync.rawValue: {
                var result = data.sync
                defer { data.sync = result }
                guard let section = form.sectionBy(tag: Constant.State.sync.rawValue) as? MultivaluedSection else { return result }
                let values = section
                    .flatMap { ($0 as? TextRow)?.value }
                    .filter { !$0.isEmpty }
                result = values.joined(separator: "\n")
                return result
            }(),
            Constant.State.cookie.rawValue: {
                var result = data.cookie
                defer { data.cookie = result }
                guard let section = form.sectionBy(tag: Constant.State.cookie.rawValue) as? MultivaluedSection else { return result }
                let values = section
                    .flatMap { ($0 as? TextRow)?.value }
                    .filter { !$0.isEmpty }
                result = values.joined(separator: "\n")
                return result
            }()
        ]
        WukongClient.sharedInstance.dispatchAction([.User, .preferences], [values])
    }

}

extension ConfigViewController: AppComponent {

    func appDidLoad() {
        data = Data()
        let client = WukongClient.sharedInstance
        client.subscribeChange {
            var preferencesChanged = false
            defer {
                if preferencesChanged {
                    self.reloadForm()
                }
            }
            if let listenOnly = client.getState([.user, .preferences, .listenOnly]) as Bool? {
                preferencesChanged = preferencesChanged || self.data.listenOnly != listenOnly
                self.data.listenOnly = listenOnly
            }
            if let connection = client.getState([.user, .preferences, .connection]) as Int? {
                preferencesChanged = preferencesChanged || self.data.connection != connection
                self.data.connection = connection
            }
            if let audioQuality = client.getState([.user, .preferences, .audioQuality]) as Int? {
                preferencesChanged = preferencesChanged || self.data.audioQuality != audioQuality
                self.data.audioQuality = audioQuality
            }
            if let sync = client.getState([.user, .preferences, .sync]) as String? {
                preferencesChanged = preferencesChanged || self.data.sync != sync
                self.data.sync = sync
            }
            if let cookie = client.getState([.user, .preferences, .cookie]) as String? {
                preferencesChanged = preferencesChanged || self.data.cookie != cookie
                self.data.cookie = cookie
            }
        }
        reloadForm()
    }

}
