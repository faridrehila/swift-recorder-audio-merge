//
//  ViewController.swift
//  iOS-AudioRecorder
//
//  Created by mac on 2018/9/3.
//  Copyright © 2018 HelloTalk. All rights reserved.
//

//Standard UI Kit
import UIKit
// Module with AV Functions
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var infoMsg: UILabel!
    
    //AVAudioRecorder provides audio recording capability.
    var audioRecorder: AVAudioRecorder!
    //AVAudioPlayer plays back audio from file or memory.
    var audioPlayer: AVAudioPlayer!
    var fileName : String = "audio" + String(Int.random(in: 0..<1000)) + ".m4a"
    var recordingTrack: String = ""
    var playerTrack: String = ""
    var isFirstTime = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        recordingSetup()
        play.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getDocumentsDirector() -> URL {
        // Grab CWD and set to paths
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func recordingSetup() {
        let recordSetting = [AVFormatIDKey : kAudioFormatAppleLossless, AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue, AVEncoderBitRateKey : 32000, AVNumberOfChannelsKey : 2, AVSampleRateKey : 44100.2] as [String: Any]
        // Append the filename to path
        if (isFirstTime) {
            recordingTrack = fileName
            playerTrack = fileName
        }
        let audioFileName = getDocumentsDirector().appendingPathComponent(recordingTrack)
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: recordSetting)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
            print("Recorder is ready")
        } catch {
            print(error)
        }
    }
    
    func playerSetup() {
        let audioFileName = getDocumentsDirector().appendingPathComponent(self.playerTrack)
        
        do {
            // Whats going on here? Defining a constant does not resolve the indentifier in the function call
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileName)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            print("Player is ready")
            audioPlayer.volume = 1
    
        } catch {
            print(error)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        record.isEnabled = true
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        play.isEnabled = true
        record.setTitle("Record", for : .normal)
    }
    
    
    @IBAction func recordAction(_ sender: Any) {
        // UI Label needs to be marked with '?'
        if record.titleLabel?.text == "Record" {
            audioRecorder.record()
            // UIControlState --> .normal
            record.setTitle("Stop", for: .normal)
            play.isEnabled = false
            
        } else {
            audioRecorder.stop()
            
            if (isFirstTime) {
                isFirstTime = false
                recordingTrack = "recording" + String(Int.random(in: 0..<1000)) + ".m4a"
                recordingSetup()
            } else {
                self.infoMsg.text = "Merging...."
                mergeTracks()
            }
            
            record.setTitle("Record", for: .normal)
            play.isEnabled = false
        }
    }
    
    func mergeTracks() {
        do {
          let mainTrackFileUrl = getDocumentsDirector().appendingPathComponent(fileName)
          // let mainTrackAvAsset = AVURLAsset.init(url: mainTrackFileUrl, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
          let mainTrackAvAsset = AVURLAsset.init(url: mainTrackFileUrl)
        
          let branchTrackFileUrl = getDocumentsDirector().appendingPathComponent(recordingTrack)
          // let branchTrackAvAsset = AVURLAsset.init(url: branchTrackFileUrl, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
          let branchTrackAvAsset = AVURLAsset.init(url: branchTrackFileUrl)
        
          let composition = AVMutableComposition()
          
          let assetTimeRange = CMTimeRange(start: kCMTimeZero, duration: mainTrackAvAsset.duration)
          try composition.insertTimeRange(assetTimeRange,
          of: mainTrackAvAsset,
          at: kCMTimeZero)
            // APPENDING
            let branchTimeRange = CMTimeRange(start: kCMTimeZero, duration: branchTrackAvAsset.duration)
            try composition.insertTimeRange(branchTimeRange, of: branchTrackAvAsset, at: mainTrackAvAsset.duration)
          
          
          let exportSession =
              AVAssetExportSession(
                asset:composition,
                presetName:AVAssetExportPresetAppleM4A)

          exportSession?.outputFileType = AVFileType.m4a
            self.playerTrack = "new_audio_" + String(Int.random(in: 0..<1000)) + ".m4a"
            exportSession?.outputURL = getDocumentsDirector().appendingPathComponent(self.playerTrack)
          // exportSession?.metadata = ...

           exportSession?.exportAsynchronously {
              switch exportSession?.status {
                case .unknown?: break
                case .waiting?: break
  
              case .exporting?:
                  print("Exporting...")
                  break
                case .completed?:
                  print("Completed!")
                  self.infoMsg.text = "Merge completed"
                  // Reseting the recorder for further tests
                  self.fileName = "audio" + String(Int.random(in: 0..<1000)) + ".m4a"
                  self.recordingTrack = self.fileName
                  
                  /* Clean up (delete partial recordings, etc.) */
                  // DELETING main track file
                  
                  // self.deleteAudio(path: mainTrackPath)
                  // DELETING branch track file
                  // self.deleteAudio(path: branchTrackPath)
                  // resolve(["state": exportSession?.outputURL])
                  break
                case .failed?:
                  print("Failed!")
                  break
                case .cancelled?: break
                case .none: break
              }
          }
        } catch {
            print("Error")
        }
    }
    
    func deleteAudio(path: String) {
      let fileManager = FileManager.default
      do {
          try fileManager.removeItem(atPath: path)
          print("Ok audio deleted")
      } catch {
          print("Could not delete the file: \(error)")
      }
    }
    
    
    @IBAction func playAction(_ sender: Any) {
        if play.titleLabel?.text == "Play" {
            play.setTitle("Stop", for: .normal)
            record.isEnabled = false
            playerSetup()
            audioPlayer.play()
        } else {
            playerSetup()
            audioPlayer.stop()
            play.setTitle("Play", for: .normal)
        }
    }

}
