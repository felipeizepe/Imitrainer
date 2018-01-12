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
	
	init(recordedAudioFile: AVAudioFile, recordedFrequencies: [Float], recordedPitches: [Float]) {
		self.audioFile = recordedAudioFile
		self.frequencies = recordedFrequencies
		self.pitches = recordedPitches
	}
	
}
