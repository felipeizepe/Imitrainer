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
	
	@IBOutlet weak var graphMicPlot: 		EZAudioPlot!
	@IBOutlet weak var pitchAudioView: 	AudioVisualizationView!
	
	@IBOutlet weak var saveButton: 		UIBarButtonItem!
	@IBOutlet weak var recordButton: 	UIButton!
	@IBOutlet weak var stopButton: 		UIButton!
	
	@IBOutlet weak var errorMssgName: UILabel!
	
	@IBOutlet weak var errorLabel: UILabel!
	
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	//MARK: Properties
	
	//AudioKit properties
	var microphone: 	AKMicrophone!
	var freqTracker: 	AKFrequencyTracker!
	var freqSilence: 	AKBooster!
	
	
	//Pitch engine properties
	var pitchEngine : 				PitchEngine!
		var lastDetectedPitch : Pitch?
	var maxPitch = 500.0
	var minPitch = 30.0
	var maxNumberCount = 70

	
	//Timer to add a pitch every second
	weak var timer: Timer!
	
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
		setupPitchListener()
		setupPitchGraph()
		
		//MARK: Setup AV session
		saveButton.isEnabled = false
		stopButton.isEnabled = false
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		//MARK: AudioKit output setup
		//Initial setup so that the audiokit is set at silence level
		AudioKit.output = self.freqSilence
		
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
	
	
	/// setus up the pitch input
	func setupPitchListener(){
		let config = Config(bufferSize: 4096, estimationStrategy: .yin, audioUrl: nil)
		self.pitchEngine = PitchEngine(config: config, signalTracker: nil, delegate: self)
		FrequencyValidator.minimumFrequency = 10.0
		FrequencyValidator.maximumFrequency = 400.0
	}
	
	
	
	/// Configures the pitch graph layout
	func setupPitchGraph(){
		self.pitchAudioView.meteringLevelBarWidth = 2.5
		self.pitchAudioView.meteringLevelBarInterItem = 1.0
		self.pitchAudioView.meteringLevelBarCornerRadius = 1.0
		self.pitchAudioView.audioVisualizationMode = .write
		self.pitchAudioView.gradientStartColor = UIColor.white
		self.pitchAudioView.gradientEndColor = UIColor.black
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
		self.pitchEngine.stop()
		
		avAudioRecorder.pause()
		AudioKit.stop()
		
		//Invalidates the timer to stop the pitch update
		if timer.isValid {
			timer.invalidate()
		}
		
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
		
		//Writes the pitch array info to a file
		let url = RecordViewController.getDocumentsDirectory().appendingPathComponent("\(recordinNameField.text!).sinfo")
		NSArray(array: pitchAudioView.meteringLevelsArray).write(to: url, atomically: false)
		
	}
	
	
	/// Method that add a pitch bar to the graph
	///
	/// - Parameter pitch: measure pitch to be added
	func addBarToPitchGraph(pitch : Pitch){
		
		//Verifies if the pitch if the pitch isn`t above the max
		
		var value : Double
		
		if pitch.frequency > self.maxPitch {
			value = self.maxPitch
		}else {
			value = pitch.frequency
		}
		
		let percent = value/maxPitch
		
		self.pitchAudioView.addMeteringLevel(Float(percent))
		
		//Restricts the number of pitch values to be recorded so that they don`t go off the screen on the play screen
		//TODO: adjust the pitch graph movement and recording to enable longer recording sessions
		if pitchAudioView.meteringLevelsArray.count > maxNumberCount {
			stopRecording()
		}
		
	}
	
	
	/// Function that causes the graph to update every second to maintain the syncrony
	@objc func updatePitchPlot(){
		do{
			var pitchToDraw : Pitch? = nil
			
			//Check if a pitch was detected, if not puts a value of pitch in the graph
			if let pitch = lastDetectedPitch {
				pitchToDraw = pitch
			}else {
				pitchToDraw = try Pitch(frequency: 10.0)
			}
			
			addBarToPitchGraph(pitch: pitchToDraw!)
			lastDetectedPitch = nil
			
		} catch {
			print(error)
			self.pitchAudioView.addMeteringLevel(10.0)
		}
	}
	
	
	/// Function that gets the ducument darectory of the project to save/read files
	///
	/// - Returns: path to the directory of the program
	static func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentsDirectory = paths[0]
		return documentsDirectory
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
	
		//Sets up and starts the activity indicator
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
		
		//Cleans the errors if the record press was succesful
		errorMssgName.isHidden = true
		errorLabel.isHidden = true
		
		//starts all the recordings and input receiving
		setupAVSession()
		AudioKit.start()
		self.pitchEngine.start()
		
		if avAudioRecorder == nil {
			startRecording()
		}else {
			avAudioRecorder.record()
		}
		
		//Disables the buttons
		saveButton.isEnabled = false
		recordButton.isEnabled = false
		stopButton.isEnabled = true
		
		//setup the timer
		timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,   selector: (#selector(RecordViewController.updatePitchPlot)), userInfo: nil, repeats: true)
		
		//Deactivates de activity indicator
		self.activityIndicator.stopAnimating()
		self.activityIndicator.isHidden = true
		
	}
	
	@IBAction func stopPress(_ sender: Any) {
		stopRecording()
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
extension RecordViewController : PitchEngineDelegate {
	func pitchEngine(_ pitchEngine: PitchEngine, didReceivePitch pitch: Pitch) {
		self.lastDetectedPitch = pitch
	}
	
	func pitchEngine(_ pitchEngine: PitchEngine, didReceiveError error: Error) {
		//Function that recieves errors of pitch readings, it is called constantly
	}
	
	func pitchEngineWentBelowLevelThreshold(_ pitchEngine: PitchEngine) {
		
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

