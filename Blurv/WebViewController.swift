//
//  WebViewController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-03-29.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import SVProgressHUD

class WebViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    var url:NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.delegate = self
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if url != nil {
            let request = NSURLRequest(URL: self.url!)
            SVProgressHUD.show()
            webView.loadRequest(request)
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        SVProgressHUD.dismiss()
    }

}
