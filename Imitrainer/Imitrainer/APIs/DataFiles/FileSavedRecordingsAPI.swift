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
		
		var result = [Recording]()
		
		let documentsUrl = RecordViewController.getDocumentsDirectory()
		
		do {
			// Get the directory contents urls (including subfolders urls)
			let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
			
			// if you want to filter the directory contents you can do like this:
			let mp3Files = directoryContents.filter{ $0.pathExtension == "m4a" }
			let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
			
			
			for count1 in 0..<mp3Files.count {
				let url = mp3Files[count1]
				let names = mp3FileNames[count1]
				
				let audioFile = EZAudioFile(url: url)!
				let info = AudioInfo(recordedAudioFile: audioFile, recordedFrequencies: [0.0,0.0], recordedPitches: [0.0,0.0])
				let currentRecording = Recording(recordingName: names, recordedInfo: info)
				
				result.append(currentRecording)
			}
			
		} catch {
			print(error.localizedDescription)
			completion(false, error.localizedDescription, result)
		}
		
		completion(true, nil, result)
		
	}
	
	
	
	
}
