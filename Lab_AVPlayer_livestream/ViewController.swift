//
//  ViewController.swift
//  Lab_AVPlayer_livestream
//
//  Created by Samuel on 2023/04/27.
//

import AVKit
import UIKit

class ViewController: UIViewController {
    var slider: UISlider!

    var isPlaybackBufferEmptyListener: NSKeyValueObservation?
    var isPlaybackBufferFullListener: NSKeyValueObservation?
    var isPlaybackLikelyToKeepUpListener: NSKeyValueObservation?
    var seekableTimeRangesListener: NSKeyValueObservation?

    var unionSeekableRange: CMTimeRange? {
        guard let ranges = player.currentItem?.seekableTimeRanges else {
            return nil
        }

        let timeRanges = ranges.map(\.timeRangeValue)
        guard let first = timeRanges.first else { return nil }
        return timeRanges.reduce(first) { partialResult, nex in
            CMTimeRangeGetUnion(partialResult, otherRange: nex)
        }
    }

    var player: AVPlayer!

    lazy var playerItem = {
        let url = URL(string: "https://fcc3ddae59ed.us-west-2.playback.live-video.net/api/video/v1/us-west-2.893648527354.channel.YtnrVcQbttF0.m3u8")!

//        let url = URL(string: "https://flutter.github.io/assets-for-api-docs/assets/videos/hls/bee.m3u8")!

        let item = AVPlayerItem(url: url)

        isPlaybackBufferEmptyListener?.invalidate()
        isPlaybackBufferEmptyListener = item.observe(\.isPlaybackBufferEmpty, options: [.initial, .new]) { _, change in
            guard let new = change.newValue else { return }
            print("isPlaybackBufferEmpty ---> \(new)")
        }

        isPlaybackBufferEmptyListener = item.observe(\.seekableTimeRanges, options: [.initial, .new]) { _, change in
            guard let new = change.newValue else { return }
            // print("seekableTimeRanges ---> \(new)")
        }

        isPlaybackBufferFullListener?.invalidate()
        isPlaybackBufferFullListener = item.observe(\.isPlaybackBufferFull, options: [.initial, .new]) { [weak self] _, change in
            guard let new = change.newValue else { return }
            print("isPlaybackBufferFull ---> \(new)")
        }

        isPlaybackLikelyToKeepUpListener?.invalidate()
        isPlaybackLikelyToKeepUpListener = item.observe(\.isPlaybackLikelyToKeepUp, options: [.initial, .new]) { [weak self] _, change in
            guard let new = change.newValue else { return }
            print("isPlaybackLikelyToKeepUp ---> \(new)")
        }
        return item
    }()

    @objc func onClickPlay(_ sender: Any) {
        player.play()
    }

    @objc func onValueChanged(_ sender: UISlider) {
        guard let range = unionSeekableRange else {
            return
        }
        let duration = range.duration

        let new = CMTime(value: CMTimeValue(Float(duration.value) * sender.value), timescale: duration.timescale)

        player.currentItem?.cancelPendingSeeks()
        player.currentItem?.seek(to: range.start + new) { [weak self] _ in
            self?.player?.play()
        }
    }

    func updateProgress() {
        guard let range = unionSeekableRange else {
            return
        }
        let time = player.currentTime().seconds
        let duration = range.duration.seconds
        slider.setValue(Float(time / duration), animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        player = AVPlayer(playerItem: playerItem)
        player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 60), queue: .main) { [weak self] _ in
            self?.updateProgress()
        }

        let layoutGuide = view.safeAreaLayoutGuide

        let playerView = PlayerView()
        view.insertSubview(playerView, at: 0)
        playerView.player = player
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            playerView.heightAnchor.constraint(equalTo: view.heightAnchor),
            playerView.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
            playerView.centerYAnchor.constraint(equalTo: layoutGuide.centerYAnchor),
        ])

        let button = UIButton(type: .custom)
        button.contentEdgeInsets = .init(top: 10, left: 20, bottom: 10, right: 20)
        button.backgroundColor = .cyan
        button.setTitle("Play", for: .normal)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onClickPlay), for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -50),
            button.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
        ])

        slider = UISlider()
        slider.isContinuous = false
        view.addSubview(slider)
        slider.addTarget(self, action: #selector(onValueChanged(_:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -50),
        ])
    }
}

class PlayerView: UIView {
    // Override the property to make AVPlayerLayer the view's backing layer.
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    // The associated player object.
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
