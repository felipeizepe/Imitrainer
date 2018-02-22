//
//  Rater.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 21/02/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import UIKit

class Rater {
	
	/// Generates a rating for the imitation based on the precision and the number of points of the
	///graph
	/// - Parameters:
	///   - precisionRate: number from 0 to 1 that determines how precise the value has to be when compared to the original, 0 being always right and 1 being 100% precision required
	///   - pointCount: number of point to be considered
	///		-data: RaterData to calculate de rating of the recording
	/// - Returns: Value of the grade from 0 to 5
	static func rate(precisionRate: Float, pointCount: UInt32, data: RaterData) -> Double {
		var grade = 0.0
		var hit = 0
		var miss = 0
		
		var pointArray = [CGPoint]()
		var originalPointArray = [CGPoint]()
		
		//Creates the array of CGPoints from the pointers
		for point in UnsafeBufferPointer(start: data.pointsNew, count: Int(pointCount)) {
			pointArray.append(point)
		}
		
		for point in UnsafeBufferPointer(start: data.pointsOriginal, count: Int(pointCount)) {
			originalPointArray.append(point)
		}
		
		//Verifyes every point in the graph, with a 1 point in the x axis of precision and with the precision rate passed in the y axis
		for index in 0..<pointArray.count {
			
			let point = pointArray[index]
			var target = originalPointArray[index]
			
			
			//If either of the y values are 0 it is considered a error in recording and not accounted for
			if target.y < 0.025 || point.y == 0.0 {
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
		if hit == 0 && miss == 0 {
			return 0
		}
		
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
	static func pointHit(point1: CGPoint, point2: CGPoint, precision: Float) -> Bool {
		
		if(point1.y >= CGFloat(precision) * point2.y && point1.y <= point2.y * CGFloat(1 + (1 - precision)) ){
			return true
		}
		
		return false
		
	}
}
