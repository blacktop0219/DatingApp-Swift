//
//  DiscoveryPreferencesController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-19.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import MARKRangeSlider
import SVProgressHUD

let DISCOVERY_MAX_DISTANCE:Float = 150
let DISCOVERY_MIN_DISTANCE:Float = 2
let DISCOVERY_MAX_AGE:Float = 55
let DISCOVERY_MIN_AGE:Float = 18

enum DiscoveryGender:Int {
    case Male = 0, Female = 1, Both = 2
}



class DiscoveryPreferencesController: UITableViewController {

    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var ageRangeSlider: MARKRangeSlider!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var ageRangeLabel: UILabel!
    
    @IBOutlet weak var discoveryGenderLabel: UILabel!
    
    var ageUpper:Float = 55
    var ageLower:Float = 16
    
    var creatingProfile = false
    
    var distance:Float = 600
    var discoveryGender:DiscoveryGender = DiscoveryGender(rawValue:BLUser.currentUser()!.discoverGender)! {
        didSet {
            updateDiscoveryGenderLabel()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.interactivePopGestureRecognizer?.enabled = false
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        setupSliders()
        loadUserPreferences()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        setNavigationBarTitle()
        setSliderValues()
        updateDiscoveryGenderLabel()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(0.3) { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    override func viewDidDisappear(animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.enabled = true
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func setNavigationBarTitle() {
       // let blurv_color = UIColor(hue: 0, saturation: 0.0, brightness: 1, alpha: 1)
        let navbar_font = UIFont(name: "Montserrat-Bold", size: 16.0)!
        let navigationBarTitleFontAttributes = [NSFontAttributeName:navbar_font, NSForegroundColorAttributeName:blurv_color]
        UINavigationBar.appearance().titleTextAttributes = navigationBarTitleFontAttributes
    }
    
    func setupSliders() {
        // DISTANCE SLIDER
        distanceSlider.addTarget(self, action: #selector(DiscoveryPreferencesController.distanceSliderValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        let trackImage = UIImage(named: "slider_track")!.resizableImageWithCapInsets(UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4))
        let bgTrackImage = UIImage(named: "slider_bg_track")!.resizableImageWithCapInsets(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 25))
        let thumbImg = UIImage(named: "slider_knob")!
        distanceSlider.setMinimumTrackImage(trackImage, forState: .Normal)
        distanceSlider.setMaximumTrackImage(bgTrackImage, forState: .Normal)
        distanceSlider.setThumbImage(thumbImg, forState: .Normal)
        
        // AGE RANGE SLIDER
        ageRangeSlider.addTarget(self, action: #selector(DiscoveryPreferencesController.ageRangeSliderValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        ageRangeSlider.trackImage = bgTrackImage
        ageRangeSlider.rangeImage = trackImage
        ageRangeSlider.leftThumbImage = thumbImg
        ageRangeSlider.rightThumbImage = thumbImg
        ageRangeSlider.backgroundColor = UIColor.clearColor()
        
        distanceSlider.minimumValue = 203/802
        distanceSlider.maximumValue = 1
        distanceSlider.value = 0.5
        
        ageRangeSlider.setMinValue(CGFloat(DISCOVERY_MIN_AGE), maxValue: CGFloat(DISCOVERY_MAX_AGE))
        ageRangeSlider.minimumDistance = 2
    }
    func setSliderValues() {
        distanceSlider.value = distanceToFactor(self.distance)
        ageRangeSlider.setLeftValue(CGFloat(ageLower), rightValue: CGFloat(ageUpper))
        
        updateDistanceLabel()
        updateAgeRangeLabel()
    }
    
    func ageRangeSliderValueChanged(slider:MARKRangeSlider) {
        ageLower = Float(slider.leftValue)
        ageUpper = Float(slider.rightValue)
        updateAgeRangeLabel()
    }
    func distanceSliderValueChanged(slider:UISlider) {
        distance = factorToDistance(slider.value)
        updateDistanceLabel()
    }
    func distanceToFactor(distance:Float) -> Float {
        return (203 + sqrt(3208*distance + 38001)) / 1604
    }
    func factorToDistance(factor:Float) -> Float {
        let factor_2 = pow(factor, 2)
        let result = 802 * factor_2 - 203 * factor + 1
        return result
    }
    
    func updateDistanceLabel() {
        distanceLabel.text = String(format: NSLocalizedString("%dkm", comment:""), Int(round(distance)))
    }
    func updateAgeRangeLabel() {
        if ageUpper >= DISCOVERY_MAX_AGE {
            ageRangeLabel.text = "\(Int(round(ageLower)))-\(Int(round(DISCOVERY_MAX_AGE)))+"
        }
        else {
            ageRangeLabel.text = "\(Int(round(ageLower)))-\(Int(round(ageUpper)))"
        }
    }
    func updateDiscoveryGenderLabel() {
        switch discoveryGender {
        case .Male:
            discoveryGenderLabel?.text = NSLocalizedString("Male only", comment: "")
        case .Female:
            discoveryGenderLabel?.text = NSLocalizedString("Female only", comment: "")
        case .Both:
            discoveryGenderLabel?.text = NSLocalizedString("Everyone", comment: "")
        }
    }
    func loadUserPreferences() {
        let user = BLUser.currentUser()!
        if user.profileComplete == true {
            self.distance = Float(user.discoveryDistance)
            self.ageLower = Float(user.discoveryAgeMin)
            self.ageUpper = Float(user.discoveryAgeMax)
            self.discoveryGender = DiscoveryGender(rawValue: user.discoverGender)!
        }
    }
    
    
    @IBAction func changeShowGender(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let maleAction = UIAlertAction(title: NSLocalizedString("Male only", comment: ""), style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
            self.discoveryGender = .Male
        }
        let femaleAction = UIAlertAction(title: NSLocalizedString("Female only", comment: ""), style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
            self.discoveryGender = .Female
        }
        let bothAction = UIAlertAction(title: NSLocalizedString("Both", comment: ""), style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
            self.discoveryGender = .Both
        }
        
        alertController.addAction(maleAction)
        alertController.addAction(femaleAction)
        alertController.addAction(bothAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    
    
    @IBAction func save(sender: AnyObject) {
        let user = BLUser.currentUser()!
        
        user.profileComplete = true
        
        user.discoveryDistance = Int(round(distance))
        user.discoveryAgeMin = Int(round(ageLower))
        let theUpperAge = Int(round(ageUpper))
        if theUpperAge >= Int(DISCOVERY_MAX_AGE) {
            user.discoveryAgeMax = 1000
        }
        else {
            user.discoveryAgeMax = theUpperAge
        }
        user.discoverGender = self.discoveryGender.rawValue
        
        SVProgressHUD.show()
        user.saveInBackgroundWithBlock { (success:Bool, error:NSError?) -> Void in
            SVProgressHUD.dismiss()
            if success {
                NSNotificationCenter.defaultCenter().postNotificationName("NOTIFICATION_DISCOVERY_CHANGED", object: nil)
                self.dismiss()
            }
            else {
                SVProgressHUD.showErrorWithStatus(NSLocalizedString("Could not save discovery settings.", comment: ""))
            }
        }
        
    }
    
    func dismiss() {
        if creatingProfile == true {
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
        else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    
}









