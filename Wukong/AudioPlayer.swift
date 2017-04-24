//
//  AudioPlayer.swift
//  Wukong
//
//  Created by Qusic on 4/23/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class AudioPlayer: NSObject, AVAudioPlayerDelegate {

    private let session: AVAudioSession = {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(AVAudioSessionCategoryPlayback)
        return session
    }()
    private var commands: [Any] = []
    private var player: AVAudioPlayer?
    private var info: [String: Any] = [:]
    private var timer: Timer?
    private var callback: ((_ player: AVAudioPlayer?) -> Void)?

    func start() {
        try? session.setActive(true)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        registerControlEvents()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(callout), userInfo: nil, repeats: true)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        info.removeAll()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        deregisterControlEvents()
        UIApplication.shared.endReceivingRemoteControlEvents()
        try? session.setActive(false)
    }

    func play(data: Data, time: Date, _ eventCallback: ((_ player: AVAudioPlayer?) -> Void)? = nil) {
        player = try? AVAudioPlayer(data: data)
        callback = eventCallback
        guard let player = player else { return }
        player.delegate = self
        player.currentTime = -time.timeIntervalSinceNow;
        player.play()
        update()
    }

    func update(title: String?, album: String?, artist: String?, artwork: UIImage?) {
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        info[MPMediaItemPropertyTitle] = title ?? ""
        info[MPMediaItemPropertyAlbumTitle] = album ?? ""
        info[MPMediaItemPropertyArtist] = artist ?? ""
        if let artwork = artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        }
        update()
    }

    func update() {
        info[MPMediaItemPropertyPlaybackDuration] = player?.duration ?? 0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func callout() {
        callback?(player)
    }

    private func registerControlEvents() {
        let center = MPRemoteCommandCenter.shared()
        center.pauseCommand.isEnabled = true
        center.playCommand.isEnabled = true
        center.stopCommand.isEnabled = false
        center.togglePlayPauseCommand.isEnabled = false
        center.enableLanguageOptionCommand.isEnabled = false
        center.disableLanguageOptionCommand.isEnabled = false
        center.changePlaybackRateCommand.isEnabled = false
        center.changeRepeatModeCommand.isEnabled = false
        center.changeShuffleModeCommand.isEnabled = false
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
        center.seekForwardCommand.isEnabled = false
        center.seekBackwardCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = false
        center.ratingCommand.isEnabled = false
        center.likeCommand.isEnabled = false
        center.dislikeCommand.isEnabled = false
        center.bookmarkCommand.isEnabled = false
        commands.append(contentsOf: [
            center.pauseCommand.addTarget { [unowned self] _ in
                guard let player = self.player else { return .noActionableNowPlayingItem }
                player.pause()
                self.update()
                return .success
            },
            center.playCommand.addTarget { [unowned self] _ in
                guard let player = self.player else { return .noActionableNowPlayingItem }
                player.play()
                self.update()
                return .success
            }
        ])
    }

    private func deregisterControlEvents() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        commands.removeAll()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        timer?.fire()
    }

}
