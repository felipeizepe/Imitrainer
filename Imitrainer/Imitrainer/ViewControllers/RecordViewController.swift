//
//  RecordViewController.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 12/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import UIKit
import AudioKit
import AudioKitUI
import Pitchy
import Beethoven
import SoundWave
import AVFoundation

class RecordViewController : UIViewController {
	
	//MARK: Outlets
	
	@IBOutlet weak var recordinNameField: UITextField!
	
	@IBOutlet weak var graphMicPlot: EZAudioPlot!
	
	@IBOutlet weak var pitchAudioView: AudioVisualizationView!
	
	@IBOutlet weak var saveButton: UIBarButtonItem!
	
	@IBOutlet weak var recordButton: UIButton!
	
	@IBOutlet weak var stopButton: UIButton!
	
	//MARK: Properties
	
	
	//AudioKit properties
	var microphone: AKMicrophone!
	var freqTracker: AKFrequencyTracker!
	var freqSilence: AKBooster!
	
	
	//Pitch engine properties
	var pitchEngine : PitchEngine!
	var maxPitch = 500.0
	var minPitch = 30.0
	var lastDetectedPitch : Pitch?
	
	weak var timer: Timer!
	
	//AVAudioRecord properties
	var avRecordingSession: AVAudioSession!
	var avAudioRecorder: AVAudioRecorder!
	
	
	//MAKR: Lifecycle Methods
	override func viewDidLoad() {
		//Keyboard dismiss setup
		let tap = UITapGestureRecognizer(target: self, action: (#selector(RecordViewController.dismissKeyboard)))
		
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)
		
		self.recordinNameField.delegate = self
		
		//MARK: Audiokit microphone setup
		self.microphone = AKMicrophone()
		self.freqTracker = AKFrequencyTracker(microphone, hopSize: 10, peakCount: 500)
		self.freqSilence = AKBooster(freqTracker, gain: 0)
		
		setupMicrophonePlot()
		
		//MARK: Pitch setup
		
		setupPitchListener()
		setupPitchGraph()
		
		//MARK: Setup AV session
		saveButton.isEnabled = false
		stopButton.isEnabled = false
	}
	
	override func viewDidAppear(_ animated: Bool) {
		
		//MARK: AudioKit output setup
		AudioKit.output = self.freqSilence
		

	}
	
	//MARK: Auxiliary Methods
	
	/// Setus up the plot of the microphone audio
	func setupMicrophonePlot() {
		let plot = AKNodeOutputPlot(microphone, frame: graphMicPlot.bounds)
		plot.plotType = .rolling
		plot.shouldFill = true
		plot.shouldMirror = true
		plot.color = UIColor.white
		plot.backgroundColor = ColorConstants.playRed
		
		//Plot adaptation to the screen
		plot.fadeout = true
		plot.gain = 2.5
		graphMicPlot.addSubview(plot)
		graphMicPlot.sendSubview(toBack: plot)
	}
	
	func setupPitchListener(){
		let config = Config(bufferSize: 4096, estimationStrategy: .yin, audioUrl: nil)
		self.pitchEngine = PitchEngine(config: config, signalTracker: nil, delegate: self)
	}
	
	func setupPitchGraph(){
		
		self.pitchAudioView.meteringLevelBarWidth = 2.5
		self.pitchAudioView.meteringLevelBarInterItem = 1.0
		self.pitchAudioView.meteringLevelBarCornerRadius = 1.0
		self.pitchAudioView.audioVisualizationMode = .write
		self.pitchAudioView.gradientStartColor = UIColor.white
		self.pitchAudioView.gradientEndColor = UIColor.black
		
	}
	
	func setupAVSession(){
		avRecordingSession = AVAudioSession.sharedInstance()
		
		do {

			try avRecordingSession.setActive(true)
		} catch {
			print("Can`t record!")
		}
	}
	
	func startRecording() {
		let audioFilename = RecordViewController.getDocumentsDirectory().appendingPathComponent("\(recordinNameField.text!).m4a")
		
		let settings = [
			AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
			AVSampleRateKey: 12000,
			AVNumberOfChannelsKey: 1,
			AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
		]
		
		do {
			avAudioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
			avAudioRecorder.delegate = self
			avAudioRecorder.record()
		} catch {
			finishRecording(success: false)
		}
	}
	
	func finishRecording(success: Bool) {
		avAudioRecorder.stop()
		avAudioRecorder = nil
		
		do{
			
			let url = RecordViewController.getDocumentsDirectory().appendingPathComponent("\(recordinNameField.text!).sinfo")
			
			
			try NSArray(array: pitchAudioView.meteringLevelsArray).write(to: url, atomically: false)
			
			
		}catch {
			print(error)
		}
		
		
		
		
		
	}
	
	func addBarToPitchGraph(pitch : Pitch){
		
		if pitch.frequency > self.minPitch {
			
			var value : Double
			
			if pitch.frequency > self.maxPitch {
				value = self.maxPitch
			}else {
				value = pitch.frequency
			}
			
			let percent = value/maxPitch
			
			self.pitchAudioView.addMeteringLevel(Float(percent))
			
		}
		
	}
	
	@objc func updatePitchPlot(){
		do{
			var pitchToDraw : Pitch? = nil
		
		if let pitch = lastDetectedPitch {
			pitchToDraw = pitch
		}else {
			pitchToDraw = try Pitch(frequency: 0.0)
			}
		
		addBarToPitchGraph(pitch: pitchToDraw!)
		lastDetectedPitch = nil
		
		} catch {
			print(error)
		}
	}
	
	static func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentsDirectory = paths[0]
		return documentsDirectory
	}
	
	@objc func dismissKeyboard(){
		self.view.endEditing(true)
	}
	
	//MARK: Outlet Button Actions
	@IBAction func recordPress(_ sender: Any) {
		setupAVSession()
		
		AudioKit.start()
		self.pitchEngine.start()
		
		if avAudioRecorder == nil {
			startRecording()
		}else {
			avAudioRecorder.record()
		}
		
		saveButton.isEnabled = false
		recordButton.isEnabled = false
		stopButton.isEnabled = true
		
		//setup the timer
		timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,   selector: (#selector(RecordViewController.updatePitchPlot)), userInfo: nil, repeats: true)
		
	}
	
	@IBAction func stopPress(_ sender: Any) {
		self.pitchEngine.stop()

		avAudioRecorder.pause()
		
		AudioKit.stop()
		
		if timer.isValid {
			timer.invalidate()
		}
		
		saveButton.isEnabled = true
		recordButton.isEnabled = true
		stopButton.isEnabled = false
	}
	
	@IBAction func savePressed(_ sender: Any) {
		if avAudioRecorder != nil {
			finishRecording(success: true)
		}
		
		self.navigationController?.popViewController(animated: true)
	}
}

//MARK: Pitch Listener Extension
extension RecordViewController : PitchEngineDelegate {
	func pitchEngine(_ pitchEngine: PitchEngine, didReceivePitch pitch: Pitch) {
		self.lastDetectedPitch = pitch
	}
	
	func pitchEngine(_ pitchEngine: PitchEngine, didReceiveError error: Error) {
		//print(error)
	}
	
	func pitchEngineWentBelowLevelThreshold(_ pitchEngine: PitchEngine) {
		print("TRESH: \(pitchEngine.levelThreshold)")
	}
}

//MARK: AVRecorder Delegate
extension RecordViewController : AVAudioRecorderDelegate {

	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		if !flag {
			if avAudioRecorder != nil {
				finishRecording(success: true)
			}
		}
	}
	
}

//MARK: Text Field delegate
extension RecordViewController : UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}

