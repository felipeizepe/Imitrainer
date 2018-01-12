//
//  AudioInfo.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 11/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import AVFoundation

/// Class that defines the objetct which hold the information about the recoring audio file
class AudioInfo {

	//MARK: Properties
	var audioFile: AVAudioFile
	var frequencies: [Float]
	var pitches: [Float]
	
	//MARK: Methods
	
	
	/// Initializer for the AudioInfo class that has the necessary info for the recording
	///
	/// - Parameters:
	///   - recordedAudioFile: AVAudioFile with the sound of the recording
	///   - recordedFrequencies: array with the recorded frequencies
	///   - recordedPitches: array with the value for the recorded pitches
	init(recordedAudioFile: AVAudioFile, recordedFrequencies: [Float], recordedPitches: [Float]) {
		self.audioFile = recordedAudioFile
		self.frequencies = recordedFrequencies
		self.pitches = recordedPitches
	}
	
}
