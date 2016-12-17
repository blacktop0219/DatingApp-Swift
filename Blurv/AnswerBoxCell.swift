//
//  AnswerBoxCell.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class AnswerBoxCell: UITableViewCell {

    @IBOutlet weak var textView: CustomTextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
