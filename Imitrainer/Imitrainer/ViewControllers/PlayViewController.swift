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
import Cosmos

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
	
	
	@IBOutlet weak var volumeSlider: UISlider!
	//Outlets of constraints
	@IBOutlet weak var plotOriginalWidth: NSLayoutConstraint!
	
	@IBOutlet weak var pitchViewOriginalWidth: NSLayoutConstraint!
	
	//MARK: rating outlets
	@IBOutlet weak var ratingView: CosmosView!
	
	//MARK: Properties
	var recording: Recording!
	var pitchControl: PitchController!
	//value found by testing the speed, it enables the view to move acordingly to
	//accomodate for long audios
	static let PIXEL_DRAW_SPEED_FACTOR = 36.5
	
	//AudioKit properties
	var microphone: 		AKMicrophone!
	var freqTracker: 		AKFrequencyTracker!
	var freqSilence: 		AKBooster!
	var microphonePlot: AKNodeOutputPlot!
	var player : 				EZAudioPlayer!
	//Attribute tha indicates whether the received sound values are suposed to be rated at the end
	var isRating = false

	weak var moveTimer: 		Timer!
	
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
		
		self.pitchControl = PitchController()
		self.pitchControl.delegate = self
		
		setupMicrophonePlot()
		setupRecordPlot()
		
		//MARK: Pitch graph setup
		PlotCotroller.setupPitchGraph(pitchGraph: self.pitchViewNew)
		PlotCotroller.setupPitchGraph(pitchGraph: self.pitchViewOriginal, toPlot: recording.infoData.pitches)
		
		//Rating setup
		ratingView.settings.updateOnTouch = false
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		//Stops the activity indicator
		self.activityIndicator.stopAnimating()
		self.activityIndicator.isHidden = true
	}
	
	//MARK: Auxiliary Methods
	
	/// Setus up the plot of the microphone audio
	func setupMicrophonePlot() {
		self.microphonePlot = PlotCotroller.getMicPlot(mic: microphone,bounds: audioPlotNew.bounds)
		audioPlotNew.addSubview(microphonePlot)
		audioPlotNew.sendSubview(toBack: microphonePlot)
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
		self.audioPlotOriginal.gain = 1.3
		self.audioPlotOriginal.updateBuffer(waveFormData?.buffers[0], withBufferSize: waveFormData!.bufferSize)
	}
	
	/// Function that stops the recording after a certain amount of time has passed
	@objc func stopRecoring(){
		pitchControl.stop()
		AudioKit.stop()

		countdownLabel.text = "Count"
		
		listenButton.isEnabled = true
		recordButton.isEnabled = true
		
		if isRating {
			rateImitation()
			isRating = false
		}
	}
	
	
	/// Functios that start the signal reading and recording
	func startSignalRead(){
		
		self.microphonePlot.resetHistoryBuffers()
		self.pitchViewNew.reset()
		
		AudioKit.start()
		pitchControl.start()
		
		unowned let unownedSelf = self
		
		let deadlineTime = DispatchTime.now() + self.recording.infoData.audioFile.duration
		DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
			unownedSelf.stopRecoring()
			//Setup view
			self.navigationItem.hidesBackButton = false
		})
	}
	
	
	/// Function that deals with ratig the imitation and updateing the UI
	func rateImitation(){
		
		let rate = RaterData(pitchOriginal: recording.infoData.pitches,
															 pitchNew: pitchViewNew.meteringLevelsArray,
															 pointsOriginal: audioPlotOriginal.points,
															 pointsNew: microphonePlot.points)
		//TODO: Updatede the UI to show the grade
		
		ratingView.rating = Rater.rate(precisionRate: 0.70, pointCount: audioPlotOriginal.pointCount, data: rate)
		recording.lastRatign = ratingView.rating
		UserDefaults.standard.setValue(ratingView.rating, forKey: "\(recording.name)")
	}
	
	//MARK: Action Outlests
	@IBAction func recordClicked(_ sender: Any) {
		
		recordButton.isEnabled = false
		
		countdownLabel.isHidden = false
		
		//Setup view
		self.navigationItem.hidesBackButton = true
		
		isRating = true
		ratingView.rating = 0.0
		
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
		
		//Setup view
		self.navigationItem.hidesBackButton = true
		
		startSignalRead()
		self.player.playAudioFile(recording.infoData.audioFile)
		
		self.activityIndicator.stopAnimating()
		self.activityIndicator.isHidden = true
	}
	
	@IBAction func changeVolume(_ sender: Any) {
		player.volume = volumeSlider.value
	}
	
}

extension PlayViewController : PitchReceiver {
	func receivePitch(pitch: Double?) {
		
		if pitch == nil {
			let percent = PitchController.minPitch/PitchController.maxPitch
			self.pitchViewNew.addMeteringLevel(Float(percent))
			return
		}
		
		let percent = pitch!/PitchController.maxPitch
		
		self.pitchViewNew.addMeteringLevel(Float(percent))
	}
}
