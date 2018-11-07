import UIKit
import AVFoundation
import MediaPlayer

class AudioPlayer: NSObject, AVAudioPlayerDelegate {

    static let sharedInstance = AudioPlayer()

    private var player: AVAudioPlayer?
    private var info: [String: Any] = [:]
    private var running: Bool = true
    private var timer: Timer?
    private var callback: ((_ playing: Bool, _ elapsed: TimeInterval, _ duration: TimeInterval, _ done: Bool) -> Void)?

    override init() {
        super.init()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, policy: .longForm)
        try? session.setActive(true)
        handleControlEvents()
        handleNotifications()
    }

    func play(data: Data, time: Date, _ eventCallback: ((_ playing: Bool, _ elapsed: TimeInterval, _ duration: TimeInterval, _ done: Bool) -> Void)? = nil) {
        player = try? AVAudioPlayer(data: data)
        guard let player = player else { return }
        player.delegate = self
        player.currentTime = -time.timeIntervalSinceNow;
        if running {
            player.play()
        }
        #if targetEnvironment(simulator)
            player.volume = 0.1
        #endif
        update()
        if let eventCallback = eventCallback {
            callback = eventCallback
            scheduleTimer()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        info.removeAll()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        callback = nil
        invalidateTimer()
    }

    func update(title: String?, album: String?, artist: String?, artwork: UIImage?) {
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        info[MPMediaItemPropertyTitle] = title ?? ""
        info[MPMediaItemPropertyAlbumTitle] = album ?? ""
        info[MPMediaItemPropertyArtist] = artist ?? ""
        if let artwork = artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { (size) in artwork }
        }
        update()
    }

    func update() {
        info[MPMediaItemPropertyPlaybackDuration] = player?.duration ?? 0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func handleControlEvents() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
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
        center.pauseCommand.addTarget { [unowned self] (event) in
            guard let player = self.player else { return .noActionableNowPlayingItem }
            self.running = false
            player.pause()
            self.update()
            return .success
        }
        center.playCommand.addTarget { [unowned self] (event) in
            guard let player = self.player else { return .noActionableNowPlayingItem }
            self.running = true
            player.play()
            self.update()
            return .success
        }
    }

    private func handleNotifications() {
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [unowned self] (notification) in
            self.scheduleTimer()
        }
        center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [unowned self] (notification) in
            self.invalidateTimer()
        }
        center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [unowned self] (notification) in
            guard self.running else { return }
            guard let userInfo = notification.userInfo else { return }
            guard let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
            guard let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            switch type {
            case .began:
                break
            case .ended:
                try? AVAudioSession.sharedInstance().setActive(true)
                self.player?.play()
            }
        }
        center.addObserver(forName: AVAudioSession.silenceSecondaryAudioHintNotification, object: nil, queue: nil) { [unowned self] (notification) in
            guard self.running else { return }
            guard let userInfo = notification.userInfo else { return }
            guard let typeValue = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt else { return }
            guard let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: typeValue) else { return }
            switch type {
            case .begin:
                self.player?.pause()
            case .end:
                self.player?.play()
            }
        }
    }

    private func scheduleTimer() {
        guard timer == nil else { return }
        if .background ~= UIApplication.shared.applicationState { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [unowned self] (timer) in
            self.timerDidFire(done: false)
        }
        timer?.tolerance = 0.5;
    }

    private func invalidateTimer() {
        guard timer != nil else { return }
        timer?.invalidate()
        timer = nil
    }

    private func timerDidFire(done: Bool) {
        callback?(player?.isPlaying ?? false, player?.currentTime ?? 0, player?.duration ?? 0, done)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        invalidateTimer()
        timerDidFire(done: true)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        invalidateTimer()
        timerDidFire(done: false)
    }

}
