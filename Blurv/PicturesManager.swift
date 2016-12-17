//
//  PicturesManager.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-19.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Parse


class PicturesManager: NSObject {

    static let sharedInstance = PicturesManager()
    
    let loadImageQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    
    
    // MARK: Facebook
    class func getProfilePictureIds(callback:(pictureIds:[String]?, error:NSError?) -> Void) {
        let fbAlbumsRequest = FBSDKGraphRequest(graphPath: "me/albums", parameters: ["fields":"name"])
        fbAlbumsRequest.startWithCompletionHandler { (connection:FBSDKGraphRequestConnection!, albums:AnyObject!, error:NSError!) -> Void in
            if albums != nil {
                let albumList = albums.objectForKey("data") as! [AnyObject]
                for album in albumList {
                    if (album.objectForKey("name") as? String) == "Profile Pictures" {
                        let albumId = album.objectForKey("id") as! String
                        
                        let fbPhotosRequest = FBSDKGraphRequest(graphPath: "/\(albumId)/photos", parameters: ["fields":"id"])
                        fbPhotosRequest.startWithCompletionHandler({ (connection2:FBSDKGraphRequestConnection!, photos:AnyObject!, error:NSError!) -> Void in
                            if photos != nil {
                                var ids:[String] = []
                                let data = photos.objectForKey("data") as! [AnyObject]
                                for item in data {
                                    ids.append(item.objectForKey("id") as! String)
                                }
                                callback(pictureIds: ids, error: nil)
                            }
                            else {
                                callback(pictureIds: nil, error: error)
                            }
                        })
                    }
                }
            }
            else {
                callback(pictureIds: nil, error: error)
            }
        }
    }
    
    func getProfilePictureForFacebookId(facebookId:String, callback:(picture:UIImage?) -> Void) {
        let pictureURL = "https://graph.facebook.com/\(facebookId)/picture?width=1000"
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { () -> Void in
            if let data = NSData(contentsOfURL: NSURL(string: pictureURL)!) {
                let image = UIImage(data: data)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(picture: image)
                })
            }
            else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(picture: nil)
                })
            }
        }
    }
    
    class func getFacebookImageURLForPictureID(pictureId:String, minimumSize:CGFloat, callback:(url:String?, error:NSError?) -> Void) {
        let fbRequest = FBSDKGraphRequest(graphPath: "\(pictureId)", parameters: ["fields":"images"])
        
        fbRequest.startWithCompletionHandler { (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if result != nil {
                let images = result!.objectForKey("images") as! [AnyObject]
                
                var theImage:AnyObject = images.first!
                for image in images {
                    let width = image.objectForKey("width") as? CGFloat
                    let height = image.objectForKey("height") as? CGFloat
                    if width <= minimumSize || height <= minimumSize {
                        break
                    } else {
                        theImage = image
                    }
                }
                let theURL = theImage.objectForKey("source") as! String
                callback(url: theURL, error: nil)
            }
            else {
                callback(url: nil, error: error)
            }
        }
    }
    
    func getFeedPictureForUser(user:BLUser, callback:(picture:UIImage?) -> Void) {
        if let picId = user.currentPictureIds.first {
            self.getImageForPictureID(picId, minimumSize: UIScreen.mainScreen().nativeBounds.width, callback: { (image, error) in
                if image != nil {
                    callback(picture: image)
                }
            })
        }
    }
    
    // MARK: Caching
    func cachesDirectory() -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        if let cacheDir = paths.first {
            if NSFileManager.defaultManager().fileExistsAtPath(cacheDir) {
                return cacheDir
            }
            else {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(cacheDir, withIntermediateDirectories: false, attributes: nil)
                    return cacheDir
                }
                catch let err as NSError {
                    print("Error creating Cache directory: \(err)")
                    return nil
                }
            }
        }
        else {
            return nil
        }
    }
    
    func getPictureFromCache(pictureId:String) -> UIImage? {
        if let cachePath = self.cachesDirectory() {
            let fullURL = NSURL(string: cachePath)!.URLByAppendingPathComponent(pictureId)
            return UIImage(contentsOfFile: fullURL.absoluteString)
        }
        else {
            return nil
        }
    }
    
    
    func cacheData(data:NSData, pictureId:String) -> Bool {
        if let cacheDir = self.cachesDirectory() {
            let cacheUrl = NSURL(string: cacheDir)!
            let fullURL = cacheUrl.URLByAppendingPathComponent(pictureId)
            
            do {
                try data.writeToFile(fullURL.absoluteString, options: NSDataWritingOptions.AtomicWrite)
                return true
            }
            catch let error as NSError {
                print("error writing to file \(error)")
                return false
            }
        }
        else {
            return false
        }
    }
    
    
    func getImageForPictureID(pictureId:String?, minimumSize:CGFloat, callback:(image:UIImage?, error:NSError?) -> Void) {
        if pictureId == nil { return }
        if let cachedImage = self.getPictureFromCache(pictureId!) {
            if cachedImage.size.height > minimumSize && cachedImage.size.width > minimumSize {
                callback(image: cachedImage, error: nil)
                return
            }
        }
        PicturesManager.getFacebookImageURLForPictureID(pictureId!, minimumSize: minimumSize) { (url, urlError) -> Void in
            if url != nil {
                let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
                dispatch_async(backgroundQueue, { () -> Void in
                    let theURL = NSURL(string: url!)
                    if let data = NSData(contentsOfURL: theURL!) {
                        let image = UIImage(data: data)!
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            callback(image: image, error: nil)
                        })
                        // Add image to the cache
                        PicturesManager.sharedInstance.cacheData(data, pictureId: pictureId!)
                    }
                    else {
                        callback(image: nil, error: nil)
                    }
                })
            }
            else {
                let query = BLPicture.query()!
                query.whereKey("pictureId", equalTo: pictureId!)
                query.findObjectsInBackgroundWithBlock({ (results:[PFObject]?, queryError:NSError?) -> Void in
                    if results != nil {
                        if results!.count > 0 {
                            let picture = results!.first as! BLPicture
                            picture.file.getDataInBackgroundWithBlock({ (data:NSData?, dataError:NSError?) -> Void in
                                if data != nil {
                                    if let img = UIImage(data: data!) {
                                        callback(image: img, error: nil)
                                        PicturesManager.sharedInstance.cacheData(data!, pictureId: pictureId!)
                                    }
                                }
                                else {
                                    callback(image: nil, error: dataError)
                                }
                            })
                        }
                        else {
                            callback(image: nil, error: queryError)
                        }
                    }
                    else {
                        callback(image: nil, error: queryError)
                    }
                })
            }
        }
    }
    
    
    func checkIfPictureHasBeenSaved(fbPictureId:String, callback:(picture:BLPicture?, error:NSError?) -> Void) {
        let query = BLPicture.query()!
        query.whereKey("pictureId", equalTo: fbPictureId)
        query.findObjectsInBackgroundWithBlock { (result:[PFObject]?, error:NSError?) -> Void in
            if let pics = result {
                if pics.count > 0 {
                    callback(picture: (pics.first as! BLPicture), error: nil)
                }
                else {
                    callback(picture: nil, error: nil)
                }
            }
            else {
                callback(picture: nil, error: error)
            }
        }
    }
    
    func saveFBPictureToParse(pictureId:String, callback:(pic:BLPicture?, error:NSError?) -> Void) {
        self.checkIfPictureHasBeenSaved(pictureId) { (picture, error) -> Void in
            if picture != nil {
                callback(pic: picture!, error: nil)
            }
            else {
                let fbRequest = FBSDKGraphRequest(graphPath: pictureId, parameters: ["fields":"images"])
                fbRequest.startWithCompletionHandler { (connection:FBSDKGraphRequestConnection!, result:AnyObject!, fbError:NSError!) -> Void in
                    if result != nil && fbError == nil {
                        let biggest = (result.objectForKey("images") as! [AnyObject]).first!
                        let source = biggest.objectForKey("source") as! String
                        
                        let q = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
                        dispatch_async(q, { () -> Void in
                            if let data = NSData(contentsOfURL: NSURL(string: source)!) {
                                if let file = PFFile(name: pictureId, data: data) {
                                    let pic = BLPicture()
                                    pic.user = BLUser.currentUser()!
                                    pic.pictureId = pictureId
                                    pic.file = file
                                    
                                    pic.saveInBackgroundWithBlock({ (success:Bool, saveError:NSError?) -> Void in
                                        if success {
                                            callback(pic: pic, error: nil)
                                        }
                                        else {
                                            callback(pic: nil, error: saveError)
                                        }
                                    })
                                    
                                    self.cacheData(data, pictureId: pictureId)
                                }
                                else {
                                    callback(pic: nil, error: nil)
                                }
                            }
                            else {
                                callback(pic: nil, error: nil)
                            }
                        })
                    }
                    else {
                        callback(pic: nil, error: fbError)
                    }
                }
            }
        }
    }
    
}

































