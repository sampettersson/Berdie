//
//  CreditsViewController.swift
//  Berdie
//
//  Created by Sam Pettersson (Skolan) on 06/11/14.
//  Copyright (c) 2014 lesr. All rights reserved.
//

import UIKit

class CreditsViewController: UIViewController {
    
    @IBAction func AuthorClick(sender: AnyObject) {
        
        UIApplication.sharedApplication().openURL(NSURL(string: "http://sampettersson.com")!)
        
    }
    
    @IBOutlet var NavBar: UINavigationBar!
    var callback: (() -> Void)?
    
    @IBAction func CancelTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        callback?()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        
        NavBar.setBackgroundImage(UIImage.imageFromColor(UIColor(rgb: 0x1AD6FD)), forBarPosition: UIBarPosition.Any, barMetrics: UIBarMetrics.Default)
        
        NavBar.shadowImage = UIImage.imageFromColor(UIColor.whiteColor())
        
    }
    
    
}
