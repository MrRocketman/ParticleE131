//
//  IPAddressPickerTableViewCell.swift
//  Particle
//
//  Created by James Adams on 10/28/15.
//  Copyright © 2015 spark. All rights reserved.
//

import Foundation

class IPAddressPickerkTableViewCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBOutlet weak var pickerView: UIPickerView!
}