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
	
	func getRecordings( completion: @escaping (_ success: Bool, _ message: String?, _ event: [Recording]?) -> Void)
	
}
