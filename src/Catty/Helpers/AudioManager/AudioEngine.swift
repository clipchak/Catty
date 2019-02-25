/**
 *  Copyright (C) 2010-2019 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */

import Foundation
import AudioKit

@objc class AudioEngine:NSObject {

    @objc static let sharedInstance = AudioEngine()

    var speechSynth: AVSpeechSynthesizer
    var mainOut: AKMixer
    var channels: [String : AudioChannel]
    var recorder: AKNodeRecorder?
    var tape: AKAudioFile?


    override init() {
        speechSynth = AVSpeechSynthesizer()
        mainOut = AKMixer()
        AudioKit.output = mainOut
        channels = [String : AudioChannel]()
        do {
            try AudioKit.start()
        } catch {
            print("could not start audio engine")
        }

        do {
            tape = try AKAudioFile()
            recorder = try AKNodeRecorder(node: mainOut, file: tape)
            AKLog((recorder?.audioFile?.directoryPath.absoluteString)!)
            AKLog((recorder?.audioFile?.fileNamePlusExtension)!)
        } catch {

        }

        do {
            try recorder?.record()
        } catch {
            AKLog("Couldn't record")
        }
    }

    func playSound(fileName: String, key: String, filePath: String) {
        let channel = getAudioChannel(key: key)
        channel.playSound(fileName: fileName, filePath: filePath)
    }

    func setVolumeTo(percent: Double, key: String) {
        let channel = getAudioChannel(key: key)
        channel.setVolumeTo(percent: percent)
    }

    func changeVolumeBy(percent: Double, key: String) {
        let channel = getAudioChannel(key: key)
        channel.changeVolumeBy(percent: percent)
    }

    @objc func pauseAllAudioPlayers()
    {
        for (_, channel) in channels {
            channel.pauseAllAudioPlayers()
        }
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Could not deactivate audio engine")
        }
    }

    @objc func resumeAllAudioPlayers()
    {
        for (_, channel) in channels {
            channel.resumeAllAudioPlayers()
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Could not deactivate audio engine")
        }
    }

    @objc func stopAllAudioPlayers()
    {
        for (_, channel) in channels {
            channel.stopAllAudioPlayers()
        }
    }

    func getSpeechSynth() -> AVSpeechSynthesizer {
        return speechSynth;
    }

    func getOutputVolumeOfChannel(objName: String) -> Double? {
        return channels[objName]?.getOutputVolume()
    }

    private func getAudioChannel(key: String) -> AudioChannel {
        if let channel = channels[key] {
            return channel
        } else {
            let channel = AudioChannel()
            channel.connectTo(node: mainOut)
            channels[key] = channel
            return channel
        }
    }

    @objc func stopNodeRecorder(){
        recorder?.stop()
        tape?.exportAsynchronously(name: "test", baseDir: .documents, exportFormat: .caf){ [weak self] _, _ in}
        AKLog(recorder?.recordedDuration)
    }
}