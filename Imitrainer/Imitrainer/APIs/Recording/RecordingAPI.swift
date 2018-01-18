//
//  RecordingAPI.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 11/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation

class SharedRecordingAPI {
	
	//MARK: Properties
	
	//Shared singleton instance
	static let shared: RecordingAPI = FileSavedRecordingsAPI()
	
}


//MARK: Recording protocol
protocol RecordingAPI {
	
	
	/// Method that returns a list of recordings that was saved in the phone
	///
	/// - Parameter completion: method to be called after the completion of the retrival of the list, successfully or not
	func getRecordings( completion: @escaping (_ success: Bool, _ message: String?, _ event: [Recording]?) -> Void)
	
	
	/// Deletes the given recornding from the files on the system
	///
	/// - Parameters:
	///   - recording: recording to be deletes
	///   - completion: completion method to be called after the files are deleted
	func deleteRecording( recording: Recording, completion: @escaping (_ success: Bool, _ message: String?) -> Void)
	
}
