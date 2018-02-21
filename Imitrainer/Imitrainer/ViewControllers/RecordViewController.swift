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
	
	//AVRecorder Properties
	var recordController: RecordingController!
	
	
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
		recordController = RecordingController()
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
			if recordController.isRecording {
				stopRecording()
				recordController.finishRecording(success: false, pitchesArray: pitchesArray)
				self.navigationItem.hidesBackButton = false
			}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		//Checks if the recording is still ongoin so the file wont be currupted
		if recordController.isRecording {
			stopRecording()
			recordController.finishRecording(success: false, pitchesArray: pitchesArray)
			self.navigationItem.hidesBackButton = false
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		//Checks if the recording is still ongoin so the file wont be currupted
		if recordController.isRecording {
			stopRecording()
			recordController.finishRecording(success: false, pitchesArray: pitchesArray)
			self.navigationItem.hidesBackButton = false
		}
	}
	
	//MARK: Auxiliary Methods
	
	/// Setus up the plot of the microphone audio
	func setupMicrophonePlot() {
		let plot = PlotCotroller.getMicPlot(mic: microphone,bounds: graphMicPlot.bounds)
		graphMicPlot.addSubview(plot)
		graphMicPlot.sendSubview(toBack: plot)
	}
	
	
	/// Stops the current recording
	func stopRecording()  {
		//Pauses the receiving of data and inputs
		pitchControl.stop()
		recordController.pauseRecording()
		AudioKit.stop()
		
		//re-enables the buttons
		saveButton.isEnabled = true
		recordButton.isEnabled = true
		stopButton.isEnabled = false
	}
	
	func startDelayedRecording(){
		
		//starts all the recordings and input receiving
		if !recordController.setupAVSession() {
			errorLabel.text = "Couldn't generate recording file"
			errorLabel.isHidden = false
			return
		}
		
		AudioKit.start()
		self.pitchControl.start()
		recordController.name = recordinNameField.text!
		recordController.record()
		recordController.avAudioRecorder.delegate = self
		
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
		recordController.finishRecording(success: true, pitchesArray: pitchesArray)
		//returns to the lisavAudioRecorder.stop()
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
			recordController.finishRecording(success: true, pitchesArray: pitchesArray)
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

