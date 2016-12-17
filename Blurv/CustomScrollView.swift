//
//  CustomScrollView.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-10.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Koloda

class CustomScrollView: UIScrollView, UIGestureRecognizerDelegate {

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        nextResponder()?.touchesBegan(touches, withEvent: event)
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        nextResponder()?.touchesMoved(touches, withEvent: event)
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        nextResponder()?.touchesEnded(touches, withEvent: event)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.dragging {
            return true
        }
        return false
        
    }
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let isCell = otherGestureRecognizer.view is UITableViewCell
        let isSuperCell = otherGestureRecognizer.view?.superview is UITableViewCell
        let isKoloda = otherGestureRecognizer.view is DraggableCardView
        if isCell || isSuperCell || isKoloda || self.dragging {
            return true
        }
        return false
    }
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !self.dragging
    }
    
}
