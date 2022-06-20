//
//  ViewController.swift
//  TurtleWhisper
//
//  Created by mahit and hebertco on 30/03/2022.
//

import UIKit
import AVFoundation
import Foundation
import CoreAudio

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

class ViewController: UIViewController {

    @IBOutlet var recordButton: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var levelTimer = Timer()
    
    var randomTimeGenerate: Double = 0
    
    var cstsol: CGFloat = 200
    
    var ensaut: Int = 0
    
    var score: Int = 0
    
    var startGame: Bool = true
    
    @IBOutlet weak var TurtleY: UIImageView!
    
    
    @IBOutlet weak var ObstacleX: UIImageView!
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        // failed to record
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        TurtleY.frame = CGRect(x: TurtleY.frame.origin.x, y: 200, width: TurtleY.frame.width, height: TurtleY.frame.height)
        ObstacleX.frame = CGRect(x: 900, y: ObstacleX.frame.origin.y, width: ObstacleX.frame.width, height: ObstacleX.frame.height)
    }
    
    func loadRecordingUI() {
        recordButton.isHidden = false
        recordButton.setTitle("Start Game", for: .normal)
    }
    
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: false)
        }
    }
    
    
    // MARK: - Recording

    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            audioRecorder.isMeteringEnabled = true
            recordButton.setTitle("Pause", for: .normal)
            
            if startGame {
                startGame = false
                self.levelTimer = Timer.scheduledTimer(timeInterval : 0.02, target: self, selector: #selector(levelTimerCallback), userInfo: nil, repeats: true)
            }
            
        } catch {
            finishRecording(success: false)
        }
    }
    
    @objc func levelTimerCallback() {
        if (audioRecorder != nil) {
            audioRecorder.updateMeters()
            if (audioRecorder.averagePower(forChannel: 0) > -50) {
                if (TurtleY.frame.origin.y < cstsol) {
                    moveTurtle(position: +5.0)
                }
                else if (TurtleY.frame.origin.y == cstsol && audioRecorder.averagePower(forChannel: 0) > -10) {
                    ensaut = -350
                }
            }
            
            if (ensaut < 0) {
                moveTurtle(position: -10)
                ensaut += 10
            }
            
            score += 15
            
            if (randomTimeGenerate <= 0) {
                randomTimeGenerate = Double.random(in: 3..<4)
                ObstacleX.frame = CGRect(x: 900, y: ObstacleX.frame.origin.y, width: ObstacleX.frame.width, height: ObstacleX.frame.height)
            }
            else {
                randomTimeGenerate -= 0.02
                ObstacleX.frame = CGRect(x: ObstacleX.frame.origin.x - 10, y: ObstacleX.frame.origin.y, width: ObstacleX.frame.width, height: ObstacleX.frame.height)
            }
            
            if (hitboxDetect()) {
                finishRecording(success: true)
            }
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            self.loadRecordingUI()
            TurtleY.frame = CGRect(x: TurtleY.frame.origin.x, y: 200, width: TurtleY.frame.width, height: TurtleY.frame.height)
            ObstacleX.frame = CGRect(x: 900, y: ObstacleX.frame.origin.y, width: ObstacleX.frame.width, height: ObstacleX.frame.height)
        } else {
            recordButton.setTitle("Reprendre", for: .normal)
        }
    }
    
    func moveTurtle(position: Double) {
        if (TurtleY.frame.origin.y + position) > cstsol {
            TurtleY.frame = CGRect(x: TurtleY.frame.origin.x, y: cstsol, width: TurtleY.frame.width, height: TurtleY.frame.height)
        } else {
            TurtleY.frame = CGRect(x: TurtleY.frame.origin.x, y: TurtleY.frame.origin.y + position, width: TurtleY.frame.width, height: TurtleY.frame.height)
        }
    }
    
    func hitboxDetect() -> Bool {
        if (TurtleY.frame.origin.x+TurtleY.frame.width >= ObstacleX.frame.origin.x && TurtleY.frame.origin.x <= ObstacleX.frame.origin.x && TurtleY.frame.origin.y+TurtleY.frame.height >= ObstacleX.frame.origin.y) {
            return true
        }
        return false
    }
}

extension ViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
}


