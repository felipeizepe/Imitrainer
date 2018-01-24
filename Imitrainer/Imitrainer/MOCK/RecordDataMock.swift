//
//  RecordDataMock.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 11/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import AVFoundation
import AudioKit

class RecordDataMock {
	
	static var recordingList: [Recording] = generateRecording()
	
	
	/// Method that generates the recodings as mocked data
	///
	/// - Returns: list of mocked recorded data
	static func generateRecording() -> [Recording] {
		var list = [Recording]()
		
		//Generate .waf file
		
		// get the documents folder url
		let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
		// create the destination url for the text file to be saved
		let fileURL = documentDirectory.appendingPathComponent("soundTest.wav")
		let text = " "
		do {
			// writing to disk
			try text.write(to: fileURL, atomically: false, encoding: .utf8)
		} catch {
			print("error writing to url:", fileURL, error)
		}
		
		//		let settings =  [AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
		//										 AVEncoderBitRateKey: 32,
		//										 AVNumberOfChannelsKey: 2,
		//										 AVSampleRateKey: 44100.0] as [String : Any]
		
		
		let audFile = EZAudioFile(url: fileURL)!
		
		let freqs = [Float(2.0), Float(3.0), Float(4.0), Float(5.0)]
		let pitchs = [Float(20.0), Float(30.0), Float(40.0), Float(50.0)]
		
		let ai1 = AudioInfo(recordedAudioFile: audFile, recordedFrequencies: freqs, recordedPitches: pitchs)
		
		let ai2 = AudioInfo(recordedAudioFile: audFile, recordedFrequencies: pitchs, recordedPitches: freqs)
		
		let r1 = Recording(recordingName: "Name1", recordedInfo: ai1)
		let r2 = Recording(recordingName: "Name2", recordedInfo: ai2)
		let r3 = Recording(recordingName: "N3", recordedInfo: ai1)
		
		list.append(r1)
		list.append(r2)
		list.append(r3)
		
		
		return list
	}
	
	
}
