//
//  FileSavedRecordingsAPI.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 16/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import AVFoundation
import AudioKit

class FileSavedRecordingsAPI : RecordingAPI {
	
	func getRecordings(completion: @escaping (Bool, String?, [Recording]?) -> Void) {
		
		EZAudioUtilities.setShouldExitOnCheckResultFail(false)
		
		var result = [Recording]()
		
		let documentsUrl = RecordViewController.getDocumentsDirectory()
		
		do {
			// Get the directory contents urls (including subfolders urls)
			let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
			
			// filters the contents for the m4a files and get their names without the extension
			let mp3Files = directoryContents.filter{ $0.pathExtension == "m4a" }
			let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
			
			//adds every audio found to the recording list
			for count1 in 0..<mp3Files.count {
				let url = mp3Files[count1]
				let name = mp3FileNames[count1]
				
				let audioFile = EZAudioFile(url: url)!
				
				//Reads the audio pitch recorded and adds to the properties 
				let urlPitch = RecordViewController.getDocumentsDirectory().appendingPathComponent("\(name).sinfo")
				
				let pitchArray = NSArray(contentsOf: urlPitch) as? [Float]
				
				let info = AudioInfo(recordedAudioFile: audioFile, recordedFrequencies: [0.0,0.0], recordedPitches: pitchArray!)
				let currentRecording = Recording(recordingName: name, recordedInfo: info)
				
				result.append(currentRecording)
			}
			
		} catch {
			print(error.localizedDescription)
			completion(false, error.localizedDescription, result)
		}
		
		completion(true, nil, result)
		
	}
	
	func deleteRecording(recording: Recording, completion: @escaping (Bool, String?) -> Void) {
		do {
			let fileManager = FileManager.default
			
			try fileManager.removeItem(at: recording.infoData.audioFile.url)
			
			let pitchUrl = RecordViewController.getDocumentsDirectory().appendingPathComponent("\(recording.name).sinfo")
			
			try fileManager.removeItem(at: pitchUrl)
			
			completion(true,nil)
			
		}catch {
			completion(false,error.localizedDescription)
		}
	}
	
	
}
