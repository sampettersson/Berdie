//
//  AppDelegate.swift
//  TheLostKiwi
//
//  Created by Sam Pettersson (Skolan) on 03/09/14.
//  Copyright (c) 2014 lesr. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    
    let scene = GameScene.unarchiveFromFile("GameScene") as GameScene

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        // Override point for customization after application launch.
        
        return true
        
    }
    
    func application(application: UIApplication!, didFailToRegisterForRemoteNotificationsWithError error: NSError!) {
    }
    
    func showCredits() {
        
        var vc = self.window!.rootViewController
        vc!.performSegueWithIdentifier("credits", sender: self)
        
    }
    
    func getScene() -> GameScene {
        
        return scene
        
    }
    
    func setSound() {
        if AVAudioSession.sharedInstance().otherAudioPlaying == true {
            scene.soundEnabled = false
        } else {
            scene.soundEnabled = true
        }
    }

    func applicationWillResignActive(application: UIApplication!) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        setSound()
        
        if scene.playing == true {
            var pause = scene.getNode("pause")
            scene.removeNode(pause)
            scene.pause()
        }
        
        var vc = self.window!.rootViewController as GameViewController
        vc.hideAds()
        
    }

    func applicationDidEnterBackground(application: UIApplication!) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication!) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        if scene.playing == false && scene.physicsWorld.speed == 1.0 {
            var vc = self.window!.rootViewController as GameViewController
            vc.showAds()
        }
        
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        setSound()
    }

    func applicationWillTerminate(application: UIApplication!) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

