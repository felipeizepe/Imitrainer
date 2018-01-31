//
//  ListViewCell.swift
//  Imitrainer
//
//  Created by Felipe Izepe on 11/01/18.
//  Copyright © 2018 Felipe Izepe. All rights reserved.
//

import UIKit
import Cosmos

class ListViewCell: UITableViewCell {
	
	//MARK: Outlets
	@IBOutlet weak var recordNameLabel: UILabel!
	@IBOutlet weak var recordImage: 		UIImageView!
	@IBOutlet weak var ratingView: 			CosmosView!
	
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
