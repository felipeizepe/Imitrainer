//
//  Recording.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 11/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation


/// Class of the Recorded Objects
class Recording  {
	
	//MARK: Properties
	var name : 				String
	var infoData: 		AudioInfo
	var lastRatign : 	Double?
	
	
	//MARK: Methods
	
	
	/// Initializer fot the recording class
	///
	/// - Parameters:
	///   - recordingName: Custom name for the recording
	///   - recordedInfo: Info about the recording in a AudioInfo class
	init(recordingName: String, recordedInfo: AudioInfo) {
		self.name = recordingName
		self.infoData = recordedInfo
	}
	
}
