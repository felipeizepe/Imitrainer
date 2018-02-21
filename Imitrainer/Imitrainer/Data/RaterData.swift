//
//  RaterData.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 21/02/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import UIKit

class RaterData {
	//MARK: Properties
	//Pitch proeperties
	var pitchOriginal: [Float]
	var pitchNew 		:	[Float]
	
	//Graph voice properties
	var pointsOriginal : UnsafeMutablePointer<CGPoint>
	var pointsNew				: UnsafeMutablePointer<CGPoint>
	
	/// Rater objects that calculastes the grade of the imitation based on the passed atributes during
	///the initialization
	/// - Parameters:
	///   - pitchOriginal: array of floats with the original pitches values that are being based
	///   - pitchNew: new pitch values received to compare to the original ones
	///   - pointsOriginal: pointer to the CGPoints Array of the original graph recorded
	///   - pointsNew: poiter to the CGPoints Array of the new recorded graph
	init(pitchOriginal: [Float], pitchNew: [Float],
			 pointsOriginal:  UnsafeMutablePointer<CGPoint>,
			 pointsNew:  UnsafeMutablePointer<CGPoint>) {
		self.pitchNew = pitchNew
		self.pitchOriginal = pitchOriginal
		self.pointsNew = pointsNew
		self.pointsOriginal = pointsOriginal
	}
	
}
