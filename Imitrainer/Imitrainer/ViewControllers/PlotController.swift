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


/// Class which defines methods that are commom among all the view that will plot the graphs
class PlotCotroller {
	
	
	/// gets a commom generated instance of AKNodeOutput to be used in a view
	///
	/// - Parameters:
	///   - mic: mic to get the input to draw the graph
	///   - bounds: size of the graph to be drawn
	/// - Returns: returns the view plot
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
	
	
	/// Sets up the a pitch graph commom to the views
	///
	/// - Parameter pitchGraph: pitchGraph to be setup
	static func setupPitchGraph(pitchGraph: AudioVisualizationView){
		pitchGraph.reset()
		pitchGraph.meteringLevelBarWidth = 2.5
		pitchGraph.meteringLevelBarInterItem = 1.0
		pitchGraph.meteringLevelBarCornerRadius = 1.0
		pitchGraph.audioVisualizationMode = .write
		pitchGraph.gradientStartColor = UIColor.white
		pitchGraph.gradientEndColor = UIColor.black
	}
	
	
	/// Setus up a pitch graph commom to the view based on a received flot array of vaues to plot
	///
	/// - Parameters:
	///   - pitchGraph: graph to be setup
	///   - toPlot: values to be plotted in the graph
	static func setupPitchGraph(pitchGraph: AudioVisualizationView, toPlot: [Float]){
		PlotCotroller.setupPitchGraph(pitchGraph: pitchGraph)
		
		//Loads the value of the recordings pitches to the pitch original graph
		for value in toPlot {
			pitchGraph.addMeteringLevel(value)
		}
	}
	
}
