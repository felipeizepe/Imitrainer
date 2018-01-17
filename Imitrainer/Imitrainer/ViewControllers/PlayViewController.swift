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
	
	@IBOutlet weak var audioPlotNew: EZAudioPlot!
	

	@IBOutlet weak var pitchViewOriginal: AudioVisualizationView!
	
	
	@IBOutlet weak var pitchViewNew: AudioVisualizationView!
	
	//MARK: Properties
	
	var recording: Recording!
	
	
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
	
	//MAKR: Lifecycle Methods
	
	override func viewDidLoad() {
		//Loads View basic layout properties
		recordingNameLabel.text = recording.name
		
		//MARK: Audiokit microphone setup
		self.microphone = AKMicrophone()
		self.freqTracker = AKFrequencyTracker(microphone, hopSize: 10, peakCount: 500)
		self.freqSilence = AKBooster(freqTracker, gain: 0)
		
		setupMicrophonePlot()
		setupRecordPlot()
		
		//MARK: Pitch setup
		
		setupPitchListener()
		setupPitchGraph()
		
		
	}
	
	//MARK: Auxiliary Methods
	
	/// Setus up the plot of the microphone audio
	func setupMicrophonePlot() {
		let plot = AKNodeOutputPlot(microphone, frame: audioPlotNew.bounds)
		plot.plotType = .rolling
		plot.shouldFill = true
		plot.shouldMirror = true
		plot.color = UIColor.white
		plot.backgroundColor = ColorConstants.playRed
		
		//Plot adaptation to the screen
		plot.fadeout = true
		plot.gain = 2.5
		audioPlotNew.addSubview(plot)
		audioPlotNew.sendSubview(toBack: plot)
	}
	
	func setupRecordPlot(){
		do {
			let waveFormData = self.recording.infoData.audioFile.getWaveformData()
			
			
			self.audioPlotOriginal.shouldFill = true
			self.audioPlotOriginal.shouldMirror = true
			self.audioPlotOriginal.color = UIColor.white
			
			//Plot adaptation to the screen
			self.audioPlotOriginal.fadeout = true
			self.audioPlotOriginal.gain = 2.5
			
			self.audioPlotOriginal.updateBuffer(waveFormData?.buffers[0], withBufferSize: waveFormData!.bufferSize)

		}catch {
			print(error)
		}
		
		
		
	}
	
	func setupPitchListener(){
		let config = Config(bufferSize: 4096, estimationStrategy: .yin, audioUrl: nil)
		self.pitchEngine = PitchEngine(config: config, signalTracker: nil, delegate: self)
	}
	
	func setupPitchGraph(){
		
		self.pitchViewNew.meteringLevelBarWidth = 2.5
		self.pitchViewNew.meteringLevelBarInterItem = 1.0
		self.pitchViewNew.meteringLevelBarCornerRadius = 1.0
		self.pitchViewNew.audioVisualizationMode = .write
		self.pitchViewNew.gradientStartColor = UIColor.white
		self.pitchViewNew.gradientEndColor = UIColor.black
		
	}
	
}

extension PlayViewController : PitchEngineDelegate {
	func pitchEngine(_ pitchEngine: PitchEngine, didReceivePitch pitch: Pitch) {
		
	}
	
	func pitchEngine(_ pitchEngine: PitchEngine, didReceiveError error: Error) {
		print(error)
	}
	
	func pitchEngineWentBelowLevelThreshold(_ pitchEngine: PitchEngine) {
		print("TRESH: \(pitchEngine.levelThreshold)")
	}
	
	
}
