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
    fileprivate var emitMessages: ([String]) -> Void = { _ in }

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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(webView, at: 0)
        webView.frame = view.bounds
        webView.load(URLRequest(url: appURL.appendingPathComponent("/test")))
    }

}

extension ViewController: WKScriptMessageHandler {

    func addHandlers(_ userContentController: WKUserContentController) {
        userContentController.add(self, name: "mount")
        userContentController.add(self, name: "unmount")
        userContentController.add(self, name: "update")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        switch message.name {
        case "mount":
            guard let emitters = body["messageEmitters"] as? String else { return }
            emitMessages = { [unowned self] (messages) in
                let script = messages.map({"\(emitters).\($0)"}).joined(separator: "\n")
                self.webView.evaluateJavaScript(script, completionHandler: nil)
            }
            audioPlayer.start()
        case "unmount":
            emitMessages = { _ in }
            audioPlayer.stop()
        case "update":
            guard let newData = body["newData"] as? [String: Any], let oldData = body["oldData"] as? [String: Any] else { return }
            let reload = newData["reload"] as? Bool ?? false
            let id = newData["id"] as? String ?? ""
            let time = newData["time"] as? TimeInterval ?? 0
            let oldId = oldData["id"] as? String ?? ""
            let oldTime = oldData["time"] as? TimeInterval ?? 0
            if reload || id != oldId || abs(time - oldTime) > 10 {
                if let file = newData["playingFile"] as? String, let url = URL(string: file, relativeTo: appURL) {
                    dataLoader.load(url: url) { [weak self] (data) in
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
                        let title = newData["title"] as? String
                        let album = newData["album"] as? String
                        let artist = newData["artist"] as? String
                        wself.audioPlayer.update(title: title, album: album, artist: artist, artwork: nil)
                        if let file = newData["playingArtwork"] as? String, let url = URL(string: file, relativeTo: wself.appURL) {
                            wself.dataLoader.load(url: url) { [weak self] (data) in
                                guard let wself = self else { return }
                                guard let data = data else { return }
                                wself.audioPlayer.update(title: title, album: album, artist: artist, artwork: UIImage(data: data))
                            }
                        }
                    }
                    if reload {
                        emitMessages(["reloaded()"])
                    }
                }
            }
            if let file = newData["preloadFile"] as? String, let url = URL(string: file, relativeTo: appURL) {
                dataLoader.load(url: url)
            }
            if let file = newData["preloadArtwork"] as? String, let url = URL(string: file, relativeTo: appURL) {
                dataLoader.load(url: url)
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

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }

}
