//
//  ChatMessageCell.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-08.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class ChatMessageCell: UITableViewCell {

    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var messagePicture: PictureView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.selectionStyle = .None
    }


}
