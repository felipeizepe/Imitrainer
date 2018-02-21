//
//  PitchController.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 21/02/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import Beethoven
import Pitchy

protocol PitchReceiver {
	func receivePitch(pitch: Double?)
}

class PitchController {
	
	//MARK: Pitch engine properties
	var pitchEngine: 				PitchEngine!
	var lastDetectedPitch: 	Pitch?
	static let maxPitch = 700.0
	static let minPitch = 20.0
	weak var timer: Timer!
	
	//Delegator
	var delegate: PitchReceiver?
	
	//MARK: Lifecycle methods
	init() {
		setupPitchListener()
	}
	
	//MARK: Auxiliar Methods
	/// Sets up the pitch input reader
	func setupPitchListener(){
		let config = Config(bufferSize: 4096, estimationStrategy: .yin, audioUrl: nil)
		self.pitchEngine = PitchEngine(config: config, signalTracker: nil, delegate: self)
		FrequencyValidator.minimumFrequency = 20.0
		FrequencyValidator.maximumFrequency = 600.0
	}
	
	func start(){
		self.pitchEngine.start()
		
		//setup the timer
		timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,   selector: (#selector(PitchController.signalPitch)), userInfo: nil, repeats: true)
	}
	
	func stop(){
		self.pitchEngine.stop()
		
		if timer.isValid {
			timer.invalidate()
		}
	}
	
	
	/// Uptades the pitch graph with a new value every milisecond
	@objc func signalPitch(){
		var pitchToDraw : Pitch? = nil
		do{
			if let pitch = lastDetectedPitch {
				pitchToDraw = pitch
			}else {
				pitchToDraw = try Pitch(frequency: 20.1)
			}
			lastDetectedPitch = nil
			
			if pitchToDraw!.frequency > PitchController.maxPitch {
				pitchToDraw = try Pitch(frequency: PitchController.maxPitch)
			}
			
			if pitchToDraw!.frequency < PitchController.minPitch {
				pitchToDraw = try Pitch(frequency: PitchController.minPitch)
			}
			
		} catch {
			print(error)
			
		}
		
		if delegate != nil {
			delegate!.receivePitch(pitch: pitchToDraw != nil ? pitchToDraw!.frequency : nil)
		}
		
	}
	
}

extension PitchController : PitchEngineDelegate {
	func pitchEngine(_ pitchEngine: PitchEngine, didReceivePitch pitch: Pitch) {
		lastDetectedPitch = pitch
	}
	
	func pitchEngine(_ pitchEngine: PitchEngine, didReceiveError error: Error) {
		
	}
	
	func pitchEngineWentBelowLevelThreshold(_ pitchEngine: PitchEngine) {
		
	}
	
}

