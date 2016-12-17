//
//  NewPictureController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-01.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

protocol NewPictureControllerDelegate {
    func newPictureControllerDidClose(vc:NewPictureController)
}

class NewPictureController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var phraseLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var seeAnswerButton: CustomButton!
    
    var game:Game!
    var image:UIImage!
    
    var delegate:NewPictureControllerDelegate?
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()
        
        self.imageView.image = image
        
        phraseLabel.alpha = 0
        let phrase = BlurvClient.sharedClient.getRandomPhraseWithType("new_picture", genderIsMale: BLUser.currentUser()!.isMale)
        self.phraseLabel.text = phrase.content
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.phraseLabel.alpha = 1
        })
        
        descriptionLabel.alpha = 0
        let adjective = BlurvClient.sharedClient.getRandomAdjective(self.game.otherUser!.isMale)
        var text:String = "Here's a first picture of \(adjective.content) \(self.game.otherUser!.firstName)"
        if BlurvClient.languageShortCode() == "fr" {
            if self.game.otherUser!.isMale {
                let desc = adjective.content.firstLetterIsVowel() ? "de l'":"du "
                text = "Voilà une nouvelle photo \(desc)\(adjective.content) \(self.game.otherUser!.firstName)"
            }
            else {
                let desc = adjective.content.firstLetterIsVowel() ? "de l'":"de la "
                text = "Voilà une nouvelle photo \(desc)\(adjective.content) \(self.game.otherUser!.firstName)"
            }
        }
        
        self.descriptionLabel.text = text
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.descriptionLabel.alpha = 1
        })
        let descriptor = game.otherUser!.isMale ? NSLocalizedString("his", comment: ""):NSLocalizedString("her", comment: "")
        seeAnswerButton.setTitle(String(format: NSLocalizedString("See %@ answer", comment:""), descriptor), forState: .Normal)
        
    } 
    
    @IBAction func seeAnswer(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            var index = self.game.currentQuestionIndex()
            if self.game.currentQuestion().answers.count == 0 {
                index -= 1
            }
            AppDelegate.routeToGame(self.game, pushQuestion: index)
        }
    }

    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.delegate?.newPictureControllerDidClose(self)
        }
    }

}
