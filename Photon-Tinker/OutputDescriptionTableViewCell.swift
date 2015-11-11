//
//  OutputDescriptionTableViewCell.swift
//  ParticleE131
//
//  Created by James Adams on 11/11/15.
//  Copyright © 2015 spark. All rights reserved.
//

import Foundation

class OutputDescriptionTableViewCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var pixelsLabel: UILabel!
}