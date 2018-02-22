//
//  RecordingController.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 21/02/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import AVFoundation

class RecordingController {
	//MARK: Properties
	//AVAudioRecord properties
	var avRecordingSession: AVAudioSession!
	var avAudioRecorder: 		AVAudioRecorder!
	
	//Recoridng properties
	var name: String!
	var isRecording: Bool {
		get {
			if avAudioRecorder == nil {
				return false
			}
			return avAudioRecorder.isRecording
		}
	}
	
	//MARK: Auxiliar Methods
	
	/// Sets up the avSession to start the recording
	///
	/// - Returns: Boolean indicating if the setup was successful
	func setupAVSession() -> Bool{
		avRecordingSession = AVAudioSession.sharedInstance()
		do {
			try avRecordingSession.setActive(true)
		} catch {
			return false
		}
		return true
	}
	
	
	/// Starts ou resumes the recording
	func record(){
		if avAudioRecorder == nil {
			startRecording()
		}else {
			avAudioRecorder.record()
		}
	}
	
	/// Starts the recording of the received audio
	func startRecording() {
		
		//Gets the path where the audio should be recorded
		let audioFilename = RecordingController.getDocumentsDirectory().appendingPathComponent("\(name!).m4a")
		
		let settings = [
			AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
			AVSampleRateKey: 12000,
			AVNumberOfChannelsKey: 1,
			AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
		]
		
		//Generates the file for the recording
		do {
			avAudioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
			avAudioRecorder.record()
		}catch {
				avAudioRecorder.stop()
				avAudioRecorder = nil
			}
	}
	
	//Pauses the recording
	func pauseRecording(){
			avAudioRecorder.pause()
	}
	
	/// Finishes the recording process and generates de m4a file with the sound
	///
	/// - Parameter success: indicates whether the operation of the recording was succesful or not
	func finishRecording(success: Bool, pitchesArray: [Float]) {
		if avAudioRecorder == nil {
			return
		}
		avAudioRecorder.stop()
		avAudioRecorder = nil
		
		
		//Writes the pitch array info to a file
		let url = RecordingController.getDocumentsDirectory().appendingPathComponent("\(name!).sinfo")
		NSArray(array: pitchesArray).write(to: url, atomically: false)
		
	}
	
	/// Function that gets the ducument darectory of the project to save/read files
	///
	/// - Returns: path to the directory of the program
	static func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentsDirectory = paths[0]
		return documentsDirectory
	}
	
}
