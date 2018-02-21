//
//  PlotController.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 21/02/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import Foundation
import UIKit
import AudioKitUI
import SoundWave

class PlotCotroller {
	
	static func getMicPlot(mic: AKMicrophone, bounds: CGRect ) -> AKNodeOutputPlot{
		let plot = AKNodeOutputPlot(mic, frame: bounds)
		plot.plotType = .rolling
		plot.shouldFill = true
		plot.shouldMirror = true
		plot.color = UIColor.white
		plot.backgroundColor = ColorConstants.playRed
		
		//Plot adaptation to the screen
		plot.fadeout = true
		plot.gain = 2.5
		return plot
	}
	
	static func setupPitchGraph(pitchGraph: AudioVisualizationView){
		pitchGraph.reset()
		pitchGraph.meteringLevelBarWidth = 2.5
		pitchGraph.meteringLevelBarInterItem = 1.0
		pitchGraph.meteringLevelBarCornerRadius = 1.0
		pitchGraph.audioVisualizationMode = .write
		pitchGraph.gradientStartColor = UIColor.white
		pitchGraph.gradientEndColor = UIColor.black
	}
	
	static func setupPitchGraph(pitchGraph: AudioVisualizationView, toPlot: [Float]){
		PlotCotroller.setupPitchGraph(pitchGraph: pitchGraph)
		
		//Loads the value of the recordings pitches to the pitch original graph
		for value in toPlot {
			pitchGraph.addMeteringLevel(value)
		}
	}
	
}
