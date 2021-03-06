//
//  ListViewCell.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 11/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import UIKit
import Cosmos
import FDWaveformView

class ListViewCell: UITableViewCell {
	
	//MARK: Outlets
	@IBOutlet weak var recordNameLabel: UILabel!
	@IBOutlet weak var ratingView: 			CosmosView!
	
	@IBOutlet weak var waveformView: FDWaveformView!
	//MARK: Properties
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
			
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
