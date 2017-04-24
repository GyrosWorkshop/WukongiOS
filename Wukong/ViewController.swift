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
    fileprivate var webView: WKWebView!
    fileprivate var defaults = UserDefaults.standard

    fileprivate enum Key: String {
        case emitters
        case location
    }

    override var prefersStatusBarHidden: Bool { return false }

    override func awakeFromNib() {
        super.awakeFromNib()
        let configuration = WKWebViewConfiguration()
        addHandlers(configuration.userContentController)
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height, left: 0, bottom: 0, right: 0)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        addObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(webView, at: 0)
        webView.frame = view.bounds
        loadState()
    }

}

extension ViewController {

    fileprivate func loadState() {
        let location = defaults.string(forKey: Key.location.rawValue) ?? "/"
        webView.load(URLRequest(url: appURL.appendingPathComponent(location)))
    }

    fileprivate func saveState() {
        if let url = webView.url {
            defaults.set(url.path, forKey: Key.location.rawValue)
        }
    }

}

extension ViewController {

    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }

    func handleNotification(_ notification: Notification) {
        switch notification.name {
        case Notification.Name.UIApplicationWillResignActive:
            saveState()
        default:
            break
        }
    }

}

extension ViewController: WKScriptMessageHandler {

    fileprivate func addHandlers(_ userContentController: WKUserContentController) {
        userContentController.add(self, name: "mount")
        userContentController.add(self, name: "unmount")
        userContentController.add(self, name: "update")
    }

    private func emitMessages(_ messages: [String]) {
        guard let emitters = defaults.string(forKey: Key.emitters.rawValue) else { return }
        let script = messages.map({"\(emitters).\($0)"}).joined(separator: "\n")
        webView.evaluateJavaScript(script)
    }

    private func playFile(id: String, time: TimeInterval, file: Any?, title: Any?, album: Any?, artist: Any?, artwork: Any?) {
        guard let file = file as? String, let url = URL(string: file, relativeTo: appURL) else { return }
        dataLoader.load(key: "\(id).\(url.pathExtension)", url: url) { [weak self] (data) in
            guard let wself = self else { return }
            guard let data = data else { return }
            var running = false
            var elapsed = 0.0
            var duration = 0.0
            wself.audioPlayer.play(data: data, time: Date(timeIntervalSince1970: time)) { [weak self] (player) in
                guard let wself = self else { return }
                var newRunning = false
                var newElapsed = 0.0
                var newDuration = 0.0
                if let player = player {
                    newRunning = player.isPlaying
                    newElapsed = player.currentTime
                    newDuration = player.duration
                } else {
                    newRunning = false
                    newElapsed = 0
                    newDuration = 0
                }
                var messages: [String] = []
                if running != newRunning {
                    messages.append("running(\(newRunning))")
                }
                if elapsed != newElapsed {
                    messages.append("elapsed(\(newElapsed))")
                }
                if duration != newDuration {
                    messages.append("duration(\(newDuration))")
                }
                if running && !newRunning && duration - elapsed < 1 {
                    messages.append("ended()")
                }
                running = newRunning
                elapsed = newElapsed
                duration = newDuration
                if messages.count > 0 {
                    wself.emitMessages(messages)
                }
            }
            let title = title as? String
            let album = album as? String
            let artist = artist as? String
            wself.audioPlayer.update(title: title, album: album, artist: artist, artwork: nil)
            if let file = artwork as? String, let url = URL(string: file, relativeTo: wself.appURL) {
                wself.dataLoader.load(key: "\(id).\(url.pathExtension)", url: url) { [weak self] (data) in
                    guard let wself = self else { return }
                    guard let data = data else { return }
                    wself.audioPlayer.update(title: title, album: album, artist: artist, artwork: UIImage(data: data))
                }
            }
        }
    }

    private func preloadFile(id: String, file: Any?) {
        guard let file = file as? String, let url = URL(string: file, relativeTo: appURL) else { return }
        dataLoader.load(key: "\(id).\(url.pathExtension)", url: url)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        switch message.name {
        case "mount":
            guard let emitters = body["messageEmitters"] as? String else { return }
            defaults.set(emitters, forKey: Key.emitters.rawValue)
            audioPlayer.start()
        case "unmount":
            defaults.removeObject(forKey: Key.emitters.rawValue)
            audioPlayer.stop()
        case "update":
            guard let newData = body["newData"] as? [String: Any], let oldData = body["oldData"] as? [String: Any] else { return }
            if let id = newData["id"] as? String, let time = newData["time"] as? TimeInterval {
                let reload = newData["reload"] as? Bool ?? false
                let oldId = oldData["id"] as? String ?? ""
                let oldTime = oldData["time"] as? TimeInterval ?? 0
                if reload || id != oldId || abs(time - oldTime) > 10 {
                    playFile(id: id, time: time, file: newData["file"], title: newData["title"], album: newData["album"], artist: newData["artist"], artwork: newData["artwork"])
                }
                if reload {
                    emitMessages(["reloaded()"])
                }
            }
            if let id = newData["preloadId"] as? String {
                preloadFile(id: id, file: newData["preloadFile"])
                preloadFile(id: id, file: newData["preloadArtwork"])
            }
        default:
            break
        }
    }

}

extension ViewController: WKNavigationDelegate, WKUIDelegate, SFSafariViewControllerDelegate {

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            let safariController = SFSafariViewController(url: url)
            safariController.delegate = self
            present(safariController, animated: true, completion: nil)
        }
        return nil
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loadState()
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }

}
