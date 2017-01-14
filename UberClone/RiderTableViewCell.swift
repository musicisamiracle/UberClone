//
//  RiderTableViewCell.swift
//  UberClone
//
//  Created by Dane Thomas on 1/13/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit

class RiderTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
