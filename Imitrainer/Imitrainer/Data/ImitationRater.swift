//
//  ImitationRater.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 29/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import UIKit
import AudioKitUI

class ImitationRater {
	
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
	
	
	/// Generates a rating for the imitation based on the precision and the number of points of the
	///graph
	/// - Parameters:
	///   - precisionRate: number from 0 to 1 that determines how precise the value has to be when compared to the original, 0 being always right and 1 being 100% precision required
	///   - pointCount: number of point to be considered
	/// - Returns: Value of the grade from 0 to 5
	func rate(precisionRate: Float, pointCount: UInt32) -> Double {
		var grade = 0.0
		var hit = 0
		var miss = 0
		
		//Check every pitch and if it is inside the precision required adds a hit, if not adds a miss
		for pitchIndex in 0..<pitchOriginal.count {
			
			let pitchValue = pitchNew[pitchIndex]
			let pitchTarget = pitchOriginal[pitchIndex]
			
			if pitchValue * precisionRate >= pitchTarget && pitchValue * (1 + (1 - precisionRate)) >= pitchTarget{
				hit += 1
			}else {
				miss += 1
			}
		}
		var pointArray = [CGPoint]()
		var originalPointArray = [CGPoint]()
		
		//Creates the array of CGPoints from the pointers
		for point in UnsafeBufferPointer(start: pointsNew, count: Int(pointCount)) {
			pointArray.append(point)
		}
		
		for point in UnsafeBufferPointer(start: pointsOriginal, count: Int(pointCount)) {
			originalPointArray.append(point)
		}
		
		//Verifyes every point in the graph, with a 1 point in the x axis of precision and with the precision rate passed in the y axis
		for index in 0..<pointArray.count {
			
			let point = pointArray[index]
			var target = originalPointArray[index]
			
			//If either of the y values are 0 it is considered a error in recording and not accounted for
			if point.y == 0 || target.y == 0 {
				continue
			}
			
			//Checks for the hits
			if(pointHit(point1: point, point2: target, precision: precisionRate)){
				hit += 1
				continue
			}
			
			target = originalPointArray[index + 1]
			
			if(pointHit(point1: point, point2: target, precision: precisionRate)){
				hit += 1
				continue
			}
			
			if index > 0{
				
				target = originalPointArray[index - 1]
				
				if(pointHit(point1: point, point2: target, precision: precisionRate)){
					hit += 1
					continue
				}

			}
			//Counts a miss in case there were no hits
			miss += 1
			
		}
		
		//Calculates the grade
		grade = Double(hit) / Double(hit + miss) * 5

		return grade
	}
	
	
	/// Verifyes if two points are considered a hit based on the precision rate
	///
	/// - Parameters:
	///   - point1: first point to compare
	///   - point2: second point to copare
	///   - precision: precision rate of the hit
	/// - Returns: true if the hit was successful, false if not
	func pointHit(point1: CGPoint, point2: CGPoint, precision: Float) -> Bool {
		
		if(point1.y >= CGFloat(precision) * point2.y && point1.y <= point2.y * CGFloat(1 + (1 - precision)) ){
			return true
		}
		
		return false
		
	}
	
}
