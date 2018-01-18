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
	
	@IBOutlet weak var plotOriginalWidth: NSLayoutConstraint!
	
	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var listenButton: UIButton!
	//MARK: Properties
	
	var recording: Recording!
	
	
	//AudioKit properties
	var microphone: 		AKMicrophone!
	var freqTracker: 		AKFrequencyTracker!
	var freqSilence: 		AKBooster!
	var microphonePlot: AKNodeOutputPlot!
	var player : 				EZAudioPlayer!
	
	//Pitch engine properties
	var pitchEngine : 			PitchEngine!
	var lastDetectedPitch : Pitch?
	var maxPitch = 500.0
	var minPitch = 30.0
	
	
	weak var timer: Timer!
	
	//MAKR: Lifecycle Methods
	
	override func viewDidLoad() {
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
		setupOroginalPitchGraph()
		
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
		
		let waveFormData = self.recording.infoData.audioFile.getWaveformData()
		let time = self.recording.infoData.audioFile.duration
		let factor = 36.5
		
		//Adjust the plot of the audiofile to match the size of the screen
		self.plotOriginalWidth.constant = CGFloat(time * factor)
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
			value = self.maxPitch
		}else {
			value = pitch.frequency
		}
		
		let percent = value/maxPitch
		
		self.pitchViewNew.addMeteringLevel(Float(percent))
		
	}
	
	//Sets up the pitch graph for the received audio file
	func setupOroginalPitchGraph(){
		self.pitchViewOriginal.meteringLevelBarWidth = 2.5
		self.pitchViewOriginal.meteringLevelBarInterItem = 1.0
		self.pitchViewOriginal.meteringLevelBarCornerRadius = 1.0
		self.pitchViewOriginal.audioVisualizationMode = .write
		self.pitchViewOriginal.gradientStartColor = UIColor.white
		self.pitchViewOriginal.gradientEndColor = UIColor.black
		
		for value in recording.infoData.pitches {
			pitchViewOriginal.addMeteringLevel(value)
		}
		
	}
	
	
	/// Uptades the pitch graph with a new value every second
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
	
	
	/// Function that stops the recording after a certain amount of time has passed
	@objc func stopRecoring(){
		self.pitchEngine.stop()
		
		AudioKit.stop()
		
		if timer.isValid {
			timer.invalidate()
		}
		
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
		timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,   selector: (#selector(RecordViewController.updatePitchPlot)), userInfo: nil, repeats: true)
		
		unowned let unownedSelf = self
		
		let deadlineTime = DispatchTime.now() + self.recording.infoData.audioFile.duration
		DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
			unownedSelf.stopRecoring()
		})
	}
	
	//MARK: Action Outlests
	@IBAction func recordClicked(_ sender: Any) {
		recordButton.isEnabled = false
		startSignalRead()
		
	}
	
	@IBAction func listenClicked(_ sender: Any) {
		listenButton.isEnabled = false
		self.player.playAudioFile(recording.infoData.audioFile)
		
		startSignalRead()
	}
}

extension PlayViewController : PitchEngineDelegate {
	func pitchEngine(_ pitchEngine: PitchEngine, didReceivePitch pitch: Pitch) {
		lastDetectedPitch = pitch
	}
	
	func pitchEngine(_ pitchEngine: PitchEngine, didReceiveError error: Error) {
		print(error)
	}
	
	func pitchEngineWentBelowLevelThreshold(_ pitchEngine: PitchEngine) {
		print("TRESH: \(pitchEngine.levelThreshold)")
	}
	
}
