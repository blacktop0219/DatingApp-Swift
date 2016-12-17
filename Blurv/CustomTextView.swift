//
//  CustomTextView.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import KMPlaceholderTextView


@IBDesignable
class CustomTextView: KMPlaceholderTextView {
    
    @IBInspectable var horizontalPadding: CGFloat = 0 {
        didSet {
            self.textContainerInset.left = horizontalPadding
            self.textContainerInset.right = horizontalPadding
        }
    }
    @IBInspectable var verticalPadding: CGFloat = 0 {
        didSet {
            self.textContainerInset.top = verticalPadding
            self.textContainerInset.bottom = verticalPadding
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.CGColor
        }
    }
    
    
}
