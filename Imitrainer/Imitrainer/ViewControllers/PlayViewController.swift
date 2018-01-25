//
//  PlayViewController.swift
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
import Beethoven
import Pitchy

class PlayViewController : UIViewController {
	
	//MARK: Outlets
	@IBOutlet weak var recordingNameLabel: UILabel!
	@IBOutlet weak var audioPlotOriginal: EZAudioPlot!
	@IBOutlet weak var audioPlotNew: 			EZAudioPlot!
	@IBOutlet weak var pitchViewOriginal: AudioVisualizationView!
	@IBOutlet weak var pitchViewNew: 			AudioVisualizationView!
	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var listenButton: UIButton!
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	@IBOutlet weak var countdownLabel: UILabel!
	
	
	//Outlets of constraints
	@IBOutlet weak var plotOriginalWidth: NSLayoutConstraint!
	
	@IBOutlet weak var pitchViewOriginalWidth: NSLayoutConstraint!
	
	//MARK: Properties
	var recording: Recording!
	//value found by testing the speed, it enables the view to move acordingly to
	//accomodate for long audios
	static let PIXEL_DRAW_SPEED_FACTOR = 36.5
	
	//AudioKit properties
	var microphone: 		AKMicrophone!
	var freqTracker: 		AKFrequencyTracker!
	var freqSilence: 		AKBooster!
	var microphonePlot: AKNodeOutputPlot!
	var player : 				EZAudioPlayer!
	
	//Pitch engine properties
	var pitchEngine: 				PitchEngine!
	var lastDetectedPitch: 	Pitch?
	var maxPitch = 700.0
	var minPitch = 20.0
	weak var moveTimer: 		Timer!
	
	weak var timer: Timer!
	
	//MAKR: Lifecycle Methods
	
	override func viewDidLoad() {
		
		//Sets up and starts the activity indicator
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
		
		//Loads View basic layout properties
		recordingNameLabel.text = recording.name
		
		//MARK: Audiokit microphone setup
		self.microphone = AKMicrophone()
		self.freqTracker = AKFrequencyTracker(microphone, hopSize: 10, peakCount: 500)
		self.freqSilence = AKBooster(freqTracker, gain: 0)
		self.player = EZAudioPlayer()
		
		setupMicrophonePlot()
		setupRecordPlot()
		
		//MARK: Pitch graph setup
		setupPitchListener()
		setupPitchGraph()
		setupOriginalPitchGraph()
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		//Stops the activity indicator
		self.activityIndicator.stopAnimating()
		self.activityIndicator.isHidden = true
	}
	
	//MARK: Auxiliary Methods
	
	/// Setus up the plot of the microphone audio
	func setupMicrophonePlot() {
		let waveFormData = self.recording.infoData.audioFile.getWaveformData()
		let size = Int32(bitPattern: (waveFormData?.bufferSize)!)
		let plot = AKNodeOutputPlot(microphone, frame: audioPlotNew.bounds)
		plot.plotType = .rolling
		plot.shouldFill = true
		plot.shouldMirror = true
		plot.color = UIColor.white
		plot.backgroundColor = ColorConstants.playRed
		plot.setRollingHistoryLength(size)

		//Plot adaptation to the screen
		plot.fadeout = true
		plot.gain = 2.5
		audioPlotNew.addSubview(plot)
		audioPlotNew.sendSubview(toBack: plot)
		
		self.microphonePlot = plot
	}
	
	
	/// Sets up the plot of the graph of the recording file
	func setupRecordPlot(){
		
		//Gets the waform data and the recording time from the file
		let waveFormData = self.recording.infoData.audioFile.getWaveformData()
		let time = self.recording.infoData.audioFile.duration
		
		//Adjust the plot of the audiofile to match the size of the screen
		self.plotOriginalWidth.constant = CGFloat(time * PlayViewController.PIXEL_DRAW_SPEED_FACTOR)
		self.view.updateConstraints()
		
		self.audioPlotOriginal.shouldFill = true
		self.audioPlotOriginal.shouldMirror = true
		self.audioPlotOriginal.color = UIColor.white
		
		//Plot adaptation to the screen
		self.audioPlotOriginal.fadeout = true
		self.audioPlotOriginal.gain = 2.5
		self.audioPlotOriginal.updateBuffer(waveFormData?.buffers[0], withBufferSize: waveFormData!.bufferSize)
		
	}
	
	
	/// Sets up the pitch input reader
	func setupPitchListener(){
		let config = Config(bufferSize: 4096, estimationStrategy: .yin, audioUrl: nil)
		self.pitchEngine = PitchEngine(config: config, signalTracker: nil, delegate: self)
		FrequencyValidator.minimumFrequency = 20.0
		FrequencyValidator.maximumFrequency = 600.0
	}
	
	
	/// Sets up the pitch graph
	func setupPitchGraph(){
		self.pitchViewNew.meteringLevelBarWidth = 2.5
		self.pitchViewNew.meteringLevelBarInterItem = 1.0
		self.pitchViewNew.meteringLevelBarCornerRadius = 1.0
		self.pitchViewNew.audioVisualizationMode = .write
		self.pitchViewNew.gradientStartColor = UIColor.white
		self.pitchViewNew.gradientEndColor = UIColor.black
	}
	
	
	/// Adds a value of pitch to the graph
	///
	/// - Parameter pitch: pitch to be added
	func addBarToPitchGraph(pitch : Pitch){
		
		var value : Double
		
		if pitch.frequency > self.maxPitch {
			value = FrequencyValidator.maximumFrequency
		}else {
			value = pitch.frequency
		}
		
		let percent = value/maxPitch
		
		self.pitchViewNew.addMeteringLevel(Float(percent))
		
	}
	
	//Sets up the pitch graph for the received audio file
	func setupOriginalPitchGraph(){
		self.pitchViewOriginal.reset()
		self.pitchViewOriginal.meteringLevelBarWidth = 2.5
		self.pitchViewOriginal.meteringLevelBarInterItem = 1.0
		self.pitchViewOriginal.meteringLevelBarCornerRadius = 1.0
		self.pitchViewOriginal.audioVisualizationMode = .write
		self.pitchViewOriginal.gradientStartColor = UIColor.white
		self.pitchViewOriginal.gradientEndColor = UIColor.black
		
		//Loads the value of the recordings pitches to the pitch original graph
		for value in recording.infoData.pitches {
			pitchViewOriginal.addMeteringLevel(value)
		}
	}
	
	/// Uptades the pitch graph with a new value every milisecond
	@objc func updatePitchPlot(){
		do{
			var pitchToDraw : Pitch? = nil
			
			if let pitch = lastDetectedPitch {
				pitchToDraw = pitch
			}else {
				pitchToDraw = try Pitch(frequency: 20.1)
			}
			
			addBarToPitchGraph(pitch: pitchToDraw!)
			lastDetectedPitch = nil
			
		} catch {
			print(error)
			self.pitchViewNew.addMeteringLevel(Float(20.1/FrequencyValidator.maximumFrequency))
		}
		
		
	}
	
	
	/// Function that stops the recording after a certain amount of time has passed
	@objc func stopRecoring(){
		self.pitchEngine.stop()
		
		AudioKit.stop()
		
		if timer.isValid {
			timer.invalidate()
		}
		
		countdownLabel.text = "Count"
		
		listenButton.isEnabled = true
		recordButton.isEnabled = true
	}
	
	
	/// Functios that start the signal reading and recording
	func startSignalRead(){
		
		self.microphonePlot.resetHistoryBuffers()
		self.pitchViewNew.reset()
		
		AudioKit.start()
		self.pitchEngine.start()
		
		//setup the timer
		timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,   selector: (#selector(PlayViewController.updatePitchPlot)), userInfo: nil, repeats: true)
		
		unowned let unownedSelf = self
		
		let deadlineTime = DispatchTime.now() + self.recording.infoData.audioFile.duration
		DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
			unownedSelf.stopRecoring()
		})
	}
	
	//MARK: Action Outlests
	@IBAction func recordClicked(_ sender: Any) {
		
		recordButton.isEnabled = false
		
		countdownLabel.isHidden = false
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
			self.countdownLabel.text = "3"
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
				self.countdownLabel.text = "2"
				
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
					self.countdownLabel.text = "1"
					
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
						self.startSignalRead()
						self.countdownLabel.isHidden = true
					})
					
				})
				
			})
			
		})
		
	}
	
	@IBAction func listenClicked(_ sender: Any) {
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
		
		listenButton.isEnabled = false
		
		startSignalRead()
		self.player.playAudioFile(recording.infoData.audioFile)
		
		self.activityIndicator.stopAnimating()
		self.activityIndicator.isHidden = true
	}
}

extension PlayViewController : PitchEngineDelegate {
	func pitchEngine(_ pitchEngine: PitchEngine, didReceivePitch pitch: Pitch) {
		lastDetectedPitch = pitch
	}
	
	func pitchEngine(_ pitchEngine: PitchEngine, didReceiveError error: Error) {

	}
	
	func pitchEngineWentBelowLevelThreshold(_ pitchEngine: PitchEngine) {
		
	}
	
}
