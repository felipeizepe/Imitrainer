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
import SoundWave
import AVFoundation

class RecordViewController : UIViewController {
	
	//MARK: Outlets
	
	@IBOutlet weak var recordinNameField: UITextField!
	
	@IBOutlet weak var graphMicPlot: 		EZAudioPlot!
	@IBOutlet weak var pitchAudioView: 	AudioVisualizationView!
	
	@IBOutlet weak var saveButton: 		UIBarButtonItem!
	@IBOutlet weak var recordButton: 	UIButton!
	@IBOutlet weak var stopButton: 		UIButton!
	
	@IBOutlet weak var errorMssgName: UILabel!
	
	@IBOutlet weak var errorLabel: UILabel!
	
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	
	@IBOutlet weak var countdownLabel: UILabel!
	//MARK: Properties
	
	//AudioKit properties
	var microphone: 	AKMicrophone!
	var freqTracker: 	AKFrequencyTracker!
	var freqSilence: 	AKBooster!
	
	
	//Pitch engine properties
	var pitchControl: PitchController!
	var pitchesArray: [Float]!
	var maxNumberCount = 60
	
	//AVAudioRecord properties
	var avRecordingSession: AVAudioSession!
	var avAudioRecorder: 		AVAudioRecorder!
	
	
	//MAKR: Lifecycle Methods
	override func viewDidLoad() {
		
		//Setup and starts the actibity indicator
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
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
		pitchControl = PitchController()
		pitchControl.delegate = self
		PlotCotroller.setupPitchGraph(pitchGraph: self.pitchAudioView)
		
		//MARK: Setup AV session
		saveButton.isEnabled = false
		stopButton.isEnabled = false
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		//MARK: AudioKit output setup
		//Initial setup so that the audiokit is set at silence level
		AudioKit.output = self.freqSilence
		
		pitchesArray = [Float]()
		
		self.activityIndicator.stopAnimating()
		self.activityIndicator.isHidden = true
	}
	
	deinit {
		//Checks if the recording is still ongoin so the file wont be currupted
		if avAudioRecorder != nil {
			if avAudioRecorder.isRecording {
				stopRecording()
			}
			finishRecording(success: false)
		}
		
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		//Checks if the recording is still ongoin so the file wont be currupted
		if avAudioRecorder != nil {
			if avAudioRecorder.isRecording {
				stopRecording()
			}
			finishRecording(success: false)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		//Checks if the recording is still ongoin so the file wont be currupted
		if avAudioRecorder != nil {
			if avAudioRecorder.isRecording {
				stopRecording()
			}
			finishRecording(success: false)
		}
	}
	
	//MARK: Auxiliary Methods
	
	/// Setus up the plot of the microphone audio
	func setupMicrophonePlot() {
		let plot = PlotCotroller.getMicPlot(mic: microphone,bounds: graphMicPlot.bounds)
		graphMicPlot.addSubview(plot)
		graphMicPlot.sendSubview(toBack: plot)
	}
	
	/// Sets up the avSession to start the recording
	func setupAVSession(){
		avRecordingSession = AVAudioSession.sharedInstance()
		do {
			try avRecordingSession.setActive(true)
		} catch {
			errorLabel.text = "Couldn't generate recording file"
			errorLabel.isHidden = false
		}
	}
	
	
	/// Starts the recording of the received audio
	func startRecording() {
		
		//Gets the path where the audio should be recorded
		let audioFilename = RecordViewController.getDocumentsDirectory().appendingPathComponent("\(recordinNameField.text!).m4a")
		
		let settings = [
			AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
			AVSampleRateKey: 12000,
			AVNumberOfChannelsKey: 1,
			AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
		]
		
		//Generates the file for the recording
		do {
			avAudioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
			avAudioRecorder.delegate = self
			avAudioRecorder.record()
		} catch {
			finishRecording(success: false)
		}
	}
	
	
	/// Stops the current recording
	func stopRecording()  {
		//Pauses the receiving of data and inputs
		pitchControl.stop()
		avAudioRecorder.pause()
		AudioKit.stop()
		
		//re-enables the buttons
		saveButton.isEnabled = true
		recordButton.isEnabled = true
		stopButton.isEnabled = false
	}
	
	
	/// Finishes the recording process and generates de m4a file with the sound
	///
	/// - Parameter success: indicates whether the operation of the recording was succesful or not
	func finishRecording(success: Bool) {
		avAudioRecorder.stop()
		avAudioRecorder = nil
		
		self.navigationItem.hidesBackButton = false
			//Writes the pitch array info to a file
			let url = RecordViewController.getDocumentsDirectory().appendingPathComponent("\(recordinNameField.text!).sinfo")
			NSArray(array: pitchesArray).write(to: url, atomically: false)
		
	}
	
	/// Function that gets the ducument darectory of the project to save/read files
	///
	/// - Returns: path to the directory of the program
	static func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentsDirectory = paths[0]
		return documentsDirectory
	}
	
	func startDelayedRecording(){
		
		//starts all the recordings and input receiving
		setupAVSession()
		AudioKit.start()
		self.pitchControl.start()
		
		if avAudioRecorder == nil {
			startRecording()
		}else {
			avAudioRecorder.record()
		}
		
		//Disables the buttons
		saveButton.isEnabled = false
		recordButton.isEnabled = false
		stopButton.isEnabled = true
		countdownLabel.isHidden = true
		
	}
	
	
	/// Object that dismisses the keyboard
	@objc func dismissKeyboard(){
		self.view.endEditing(true)
	}
	
	//MARK: Outlet Button Actions
	
	@IBAction func recordPress(_ sender: Any) {
		//Checks if a name for the recording has been typed
		if recordinNameField.text == "" {
			errorMssgName.isHidden = false
			return
		}
		
		//Setup view
		self.navigationItem.hidesBackButton = true
	
		//Cleans the errors if the record press was succesful
		errorMssgName.isHidden = true
		errorLabel.isHidden = true
		
		//Starts the countdown to the recording
		countdownLabel.isHidden = false
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
			self.countdownLabel.text = "3"
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
				self.countdownLabel.text = "2"
				
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
					self.countdownLabel.text = "1"
					
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
						self.startDelayedRecording()
					})
					
				})
				
			})
			
		})
		
		
	}
	
	@IBAction func stopPress(_ sender: Any) {
		stopRecording()
		countdownLabel.text = "Count"
	}
	
	@IBAction func savePressed(_ sender: Any) {
		if avAudioRecorder != nil {
			finishRecording(success: true)
		}
		//returns to the list of recordings
		self.navigationController?.popViewController(animated: true)
	}
}

//MARK: Pitch Listener Extension
extension RecordViewController : PitchReceiver {
	func receivePitch(pitch: Double?) {
		
		if pitch == nil {
			let percent = PitchController.minPitch/PitchController.maxPitch
			self.pitchAudioView.addMeteringLevel(Float(percent))
			pitchesArray.append(Float(percent))
			return
		}
		
		let percent = pitch!/PitchController.maxPitch
		
		self.pitchAudioView.addMeteringLevel(Float(percent))
		pitchesArray.append(Float(percent))
		
		//Restricts the number of pitch values to be recorded so that they don`t go off the screen on the play screen
		//TODO: adjust the pitch graph movement and recording to enable longer recording sessions
		if pitchAudioView.meteringLevelsArray.count > maxNumberCount {
			stopRecording()
			countdownLabel.text = "Count"
			self.recordButton.isEnabled = false
		}
		
	}
	
	
}

//MARK: AVRecorder Delegate
extension RecordViewController : AVAudioRecorderDelegate {
	
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		//Cloeses the recording if it was successful
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

