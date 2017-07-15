//
//  ViewController.swift
//  Wukong
//
//  Created by Qusic on 4/20/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class ViewController: UIViewController {

    fileprivate let appURL = URL(string: "https://wukongmusic.us")!
    fileprivate let audioPlayer = AudioPlayer()
    fileprivate let dataLoader = DataLoader()
    fileprivate var defaults = UserDefaults.standard

    override var prefersStatusBarHidden: Bool { return false }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
