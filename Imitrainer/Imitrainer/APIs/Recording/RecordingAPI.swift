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
	static let shared: RecordingAPI = RecordingAPIMock()
	
}


//MARK: Recording protocol
protocol RecordingAPI {
	
	
	/// Method that returns a list of recordings that was saved in the phone
	///
	/// - Parameter completion: method to be called after the completion of the retrival of the list, successfully or not
	func getRecordings( completion: @escaping (_ success: Bool, _ message: String?, _ event: [Recording]?) -> Void)
	
}
