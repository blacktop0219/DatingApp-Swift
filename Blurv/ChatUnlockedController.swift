//
//  ChatUnlockedController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-01.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import SVProgressHUD


class ChatUnlockedController: UIViewController {

    @IBOutlet weak var phraseLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var pictureView: PictureView!
    
    var game:Game!
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        phraseLabel.alpha = 0
        let phrase = BlurvClient.sharedClient.getRandomPhraseWithType("chat_unlocked", genderIsMale: BLUser.currentUser()!.isMale)
        self.phraseLabel.text = phrase.content
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.phraseLabel.alpha = 1
        })
        
        descriptionLabel.alpha = 0
        let adjective = BlurvClient.sharedClient.getRandomAdjective(self.game.otherUser!.isMale)
        var text:String = "You can now chat with the \(adjective.content) \(self.game.otherUser!.firstName)"
        if BlurvClient.languageShortCode() == "fr" {
            if self.game.otherUser!.isMale {
                let desc = adjective.content.firstLetterIsVowel() ? "l'":"le "
                text = "Vous pouvez à présent discuter libremement avec \(desc)\(adjective.content) \(self.game.otherUser!.firstName)"
            }
            else {
                let desc = adjective.content.firstLetterIsVowel() ? "l'":"la "
                text = "Vous pouvez à présent discuter libremement avec \(desc)\(adjective.content) \(self.game.otherUser!.firstName)"
            }
        }
        
        self.descriptionLabel.text = text
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.descriptionLabel.alpha = 1
        })
        pictureView.pictureId = game.otherUser!.currentPictureIds[2]
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func readyToChat(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
        GameManager.sharedManager.setReadyForChat(game)
    }
    
    
}
