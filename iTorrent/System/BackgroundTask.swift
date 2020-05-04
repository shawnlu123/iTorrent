//
//  BackgroundTask.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import AVFoundation

class BackgroundTask {
    static var player: AVAudioPlayer?
    static var timer = Timer()
    static var backgrounding = false

    static func startBackgroundTask() {
        if !backgrounding {
            backgrounding = true
            BackgroundTask.playAudio()
        }
    }

    static func stopBackgroundTask() {
        if backgrounding {
            backgrounding = false
            player?.stop()
        }
    }

    fileprivate static func playAudio() {
        do {
            let bundle = Bundle.main.path(forResource: "3", ofType: "wav")
            let alertSound = URL(fileURLWithPath: bundle!)
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            BackgroundTask.player = try AVAudioPlayer(contentsOf: alertSound)
            BackgroundTask.player?.numberOfLoops = -1
            BackgroundTask.player?.volume = 0.01
            BackgroundTask.player?.prepareToPlay()
            BackgroundTask.player?.play()
        } catch {
            print(error)
        }
    }

    static func startBackground() -> Bool {
        if UserPreferences.background {
            if Core.shared.torrents.values.contains(where: { (status) -> Bool in
                getBackgroundConditions(status)
            }) {
                startBackgroundTask()
                return true
            }
        }
        return false
    }

    static func checkToStopBackground() {
        if !Core.shared.torrents.values.contains(where: { getBackgroundConditions($0) }) {
            if backgrounding {
                Core.shared.saveTorrents()
                stopBackgroundTask()
            }
        }
    }

    static func getBackgroundConditions(_ status: TorrentModel) -> Bool {
        // state conditions
        (status.displayState == .downloading ||
            status.displayState == .metadata ||
            status.displayState == .hashing ||
            (status.displayState == .seeding &&
                UserPreferences.backgroundSeedKey &&
                status.seedMode) ||
            (UserPreferences.ftpKey &&
                UserPreferences.ftpBackgroundKey)) &&
            // zero speed limit conditions
            ((UserPreferences.zeroSpeedLimit > 0 &&
                    Core.shared.torrentsUserData[status.hash]?.zeroSpeedTimeCounter ?? 0 < UserPreferences.zeroSpeedLimit) ||
                UserPreferences.zeroSpeedLimit == 0)
    }
}
