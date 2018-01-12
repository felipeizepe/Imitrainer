//
//  RecordingAPIMock.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 11/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation

class RecordingAPIMock : RecordingAPI {
	
	func getRecordings( completion: @escaping (_ success: Bool, _ message: String?, _ event: [Recording]?) -> Void){
		completion(true,nil, RecordDataMock.recordingList)
	}
	
	
}
