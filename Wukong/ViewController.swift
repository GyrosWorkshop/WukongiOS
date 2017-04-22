//
//  ViewController.swift
//  Wukong
//
//  Created by Qusic on 4/20/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import MediaPlayer
import SafariServices

class AudioPlayer: NSObject {

    var player: AVAudioPlayer?
    weak var delegate: AVAudioPlayerDelegate?

    init(avDelegate: AVAudioPlayerDelegate) {
        delegate = avDelegate
        super.init()
    }

    func play(_ data: Data, time: Date) {
        player = try? AVAudioPlayer(data: data)
        guard let player = player else { return }
        player.delegate = delegate
        player.prepareToPlay()
        player.play(atTime: -time.timeIntervalSinceNow)
    }

}

class DataLoader: NSObject {

    let session: URLSession
    var callbacks: [URL: (_ data: Data?) -> Void] = [:]

    init(directory: String) {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: Int.max, diskPath: directory)
        session = URLSession(configuration: configuration)
        super.init()
    }

    func load(_ url: URL, callback: ((_ data: Data?) -> Void)?) {
        if let callback = callback {
            callbacks[url] = callback
        }
        session.getAllTasks { (tasks) in
            guard !tasks.contains(where: { $0.originalRequest?.url == url }) else { return }
            self.session.dataTask(with: url, completionHandler: { (data, response, error) in
                self.callbacks[url]?(data)
                self.callbacks.removeValue(forKey: url)
            }).resume()
        }
    }

}

class ViewController: UIViewController {

    let appURL = URL(string: "https://wukongmusic.us")!
    var audioPlayer: AudioPlayer!
    var dataLoader: DataLoader!
    var webView: WKWebView!

    var messageEmitters: String?
    override var prefersStatusBarHidden: Bool { return false }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        audioPlayer = AudioPlayer(avDelegate: self)
        dataLoader = DataLoader(directory: "Wukong")
    }

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

    func emitMessage(_ message: String) {
        guard let emitters = messageEmitters else { return }
        webView.evaluateJavaScript("\(emitters).\(message)", completionHandler: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        switch message.name {
        case "mount":
            messageEmitters = body["messageEmitters"] as? String
            break
        case "unmount":
            messageEmitters = nil
            break
        case "update":
            guard let newData = body["newData"] as? [String: Any],
                let oldData = body["oldData"] as? [String: Any] else { return }
            let reload = newData["reload"] as? Bool ?? false
            let id = newData["id"] as? String ?? ""
            let time = newData["time"] as? TimeInterval ?? 0
            let oldId = oldData["id"] as? String ?? ""
            let oldTime = oldData["time"] as? TimeInterval ?? 0
            if reload || id != oldId || abs(time - oldTime) > 10 {
                if let file = newData["playingFile"] as? String,
                    let url = URL(string: file, relativeTo: appURL) {
                    dataLoader.load(url, callback: { (data) in
                        guard let data = data else { return }
                        self.audioPlayer.play(data, time: Date(timeIntervalSince1970: time))
                        let infoCenter = MPNowPlayingInfoCenter.default()
                        var info: [String: Any] = [
                            MPMediaItemPropertyTitle: newData["title"] as? String ?? "",
                            MPMediaItemPropertyAlbumTitle: newData["album"] as? String ?? "",
                            MPMediaItemPropertyArtist: newData["artist"] as? String ?? ""
                        ]
                        infoCenter.nowPlayingInfo = info
                        if let file = newData["playingArtwork"] as? String,
                            let url = URL(string: file, relativeTo: self.appURL) {
                            self.dataLoader.load(url, callback: { (data) in
                                guard let data = data,
                                    let image = UIImage(data: data) else { return }
                                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ in image })
                                infoCenter.nowPlayingInfo = info
                            })
                        }
                    })
                    if reload {
                        emitMessage("reloaded()")
                    }
                }
            }
            if let file = newData["preloadFile"] as? String,
                let url = URL(string: file, relativeTo: appURL) {
                dataLoader.load(url, callback: nil)
            }
            if let file = newData["preloadArtwork"] as? String,
                let url = URL(string: file, relativeTo: appURL) {
                dataLoader.load(url, callback: nil)
            }
            break
        default:
            break
        }
    }

}

extension ViewController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            emitMessage("ended()")
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
