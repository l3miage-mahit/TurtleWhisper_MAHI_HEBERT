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
    
    @IBOutlet var turtleYConstraint: NSLayoutConstraint!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var levelTimer = Timer()
    
    var randomTimeGenerate: Double = 0
    
    var cstsol: CGFloat = 250
    
    var ensaut: Int = 0
    
    var startGame: Bool = true
    var bruit: Bool = false
    
    @IBOutlet weak var TurtleY: UIImageView!
    
    var listObstacles = [UIImageView]()
    
    var ObstacleX = UIImageView()
    
    let labelScore = UILabel()
    
    var score: Int = 0
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelScore.text = "Score: "+String(score)
        labelScore.frame = CGRect(x: self.view.frame.width-100, y: 10, width: 200, height: 50)
        self.view.addSubview(labelScore)
        
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            recordingSession.requestRecordPermission { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        TurtleY.frame = CGRect(x: TurtleY.frame.origin.x, y: cstsol+45, width: TurtleY.frame.width, height: TurtleY.frame.height)
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
        
        score = 0
        labelScore.text = "Score: "+String(score)
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("gameRecord.m4a")
        
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
            recordButton.setTitle("", for: .normal)
            
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
            
            if (audioRecorder.averagePower(forChannel: 0) > -20) {
                if (ensaut < 50) {
                    moveTurtle(position: -25.0)
                    ensaut += 5
                }
            }
            else {
                if (ensaut > 0) {
                    moveTurtle(position: +50)
                    ensaut -= 10
                }
            }
            
            if (randomTimeGenerate <= 0) {
                randomTimeGenerate = Double.random(in: 0..<3)
                createObstacle()
            }
            else {
                randomTimeGenerate -= 0.02
                
                var newlistobstacles = [UIImageView]()
                
                for obstacle in listObstacles {
                    obstacle.frame = CGRect(x: obstacle.frame.origin.x - 10, y: obstacle.frame.origin.y, width: obstacle.frame.width, height: obstacle.frame.height)
                    if (obstacle.frame.origin.x <= -100) {
                        obstacle.removeFromSuperview()
                    }
                    else {
                        newlistobstacles.append(obstacle)
                    }
                }
                
                listObstacles = newlistobstacles
            }
            
            if (hitboxDetect()) {
                finishRecording(success: true)
            }
            
            increaseScore()
            labelScore.text = "Score: "+String(score)
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            self.loadRecordingUI()

            turtleYConstraint.constant = cstsol
            
            for obstacle in listObstacles {
                obstacle.frame = CGRect(x: -100, y: obstacle.frame.origin.y, width: obstacle.frame.width, height: obstacle.frame.height)
                obstacle.removeFromSuperview()
            }
            listObstacles = [UIImageView]()

        } else {
            recordButton.setTitle("Reprendre", for: .normal)
        }
    }
    
    func moveTurtle(position: Double) {
        if (turtleYConstraint.constant + position) < 50 {
            turtleYConstraint.constant = 50
        }
        else if (turtleYConstraint.constant + position) > cstsol {
            turtleYConstraint.constant = cstsol
        }
        else {
            turtleYConstraint.constant += position
        }
    }
    
    func createObstacle() {
        let image = UIImage(named: "MitiaSauvage")
        ObstacleX = UIImageView(image: image!)
        ObstacleX.frame = CGRect(x: 900, y: 285, width: 75, height: 75)
        self.view.addSubview(ObstacleX)
        
        listObstacles.append(ObstacleX)
    }
    
    func increaseScore() {
        for obstacle in listObstacles {
            if (TurtleY.frame.origin.x+(TurtleY.frame.width/2)+5 >= obstacle.frame.origin.x && TurtleY.frame.origin.x+(TurtleY.frame.width/2)-5 <= obstacle.frame.origin.x) {
                score += 1
            }
        }
    }
    
    func hitboxDetect() -> Bool {
        for obstacle in listObstacles {
            if (TurtleY.frame.origin.x+TurtleY.frame.width >= obstacle.frame.origin.x && TurtleY.frame.origin.x <= obstacle.frame.origin.x && TurtleY.frame.origin.y+TurtleY.frame.height >= obstacle.frame.origin.y) {
                return true
            }
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


