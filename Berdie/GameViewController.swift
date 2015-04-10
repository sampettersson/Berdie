//
//  GameViewController.swift
//  TheLostKiwi
//
//  Created by Sam Pettersson (Skolan) on 03/09/14.
//  Copyright (c) 2014 lesr. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit
import iAd

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

struct GameStoreDictionary {
    
    var name: String
    var image: UIImage?
    var price: Int
    
    init(setName: String, setImage: String, setPrice: Int) {
        
        name = setName
        image = UIImage(named: setImage)
        price = setPrice
        
    }
    
}

class GameViewController: UIViewController, GKGameCenterControllerDelegate, ADBannerViewDelegate {
    
    var gameCenterEnabled = false
    var leaderboardIdentifier: String!
    var adView: ADBannerView!
    var iAdsVisible: Bool!
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        
        iAdsVisible = true
        
        if self.adView == nil {
            //Skip
            return
        }
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            
            self.adView.alpha = 1
            
        })
        
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        
        iAdsVisible = false
        
        hideAds()
        
    }
    
    func showAds() {
        
        adView = ADBannerView(frame: CGRectZero)
        adView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        adView.delegate = self
        
        adView.frame = CGRectMake(0, self.view.frame.height - adView.frame.height, adView.frame.width, adView.frame.height)
        adView.alpha = 0
        
        self.view.addSubview(adView)
        
    }
    
    func hideAds() {
        
        if self.adView == nil {
            
            // Skip
            return
        
        }
    
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            
            self.adView.alpha = 0
            
        })
        
        Async.main(after: 0.2) { () -> Void in
         
            if self.adView != nil {
                
                self.adView.removeFromSuperview()
                self.adView = nil
                
            }
            
        }
        
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        var appdelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        showAds()
        
        let scene = appdelegate.getScene();
        
        // Configure the view.
        let skView = self.view as SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = SKSceneScaleMode.AspectFill
        
        skView.presentScene(scene)
        
        authenticateLocalPlayer(false)
        
    }
    
    func authenticateLocalPlayer(show: Bool) {
        var localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {(viewController : UIViewController!, error : NSError!) -> Void in
            if viewController != nil {
                self.presentViewController(viewController, animated: true, completion: nil)
            } else {
                if localPlayer.authenticated {
                    
                    self.gameCenterEnabled = true
                    
                    localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({ (leaderboardIdentifier : String!, error : NSError!) -> Void in
                        if error != nil {
                            //println(error.localizedDescription)
                        } else {
                            self.leaderboardIdentifier = leaderboardIdentifier
                        }
                    })
                    
                    if show == true {
                        self.showGameCenter()
                    }
                    
                } else {
                    self.gameCenterEnabled = false
                }
                
                self.createGameScene()
                
            }
        }
    }
    
    func sendHighScore(score: Int) {
        
        if gameCenterEnabled == false {
            return
        }
        
        var highscore: GKScore = GKScore(leaderboardIdentifier: leaderboardIdentifier)
        highscore.value = Int64(score)
        
        GKScore.reportScores([highscore], withCompletionHandler: { (error) -> Void in
            
            
        })
        
        if score > 1 {
            
            reportAchievement("first_level_completed", percentComplete: 100.0)
            
        }
        
    }
    
    func showGameCenter() {
        
        var gameCenterViewController: GKGameCenterViewController? = GKGameCenterViewController()
        
        if gameCenterViewController != nil {
            
            gameCenterViewController!.gameCenterDelegate = self
            
            self.presentViewController(gameCenterViewController!, animated: true, completion: nil)
            
        }
        
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func reportAchievement(identifier: String, percentComplete: Double) {
        
        var achievement = GKAchievement(identifier: identifier)
        
        if achievement != nil {
            
            achievement.percentComplete = percentComplete
            
            GKAchievement.reportAchievements([achievement], withCompletionHandler: { (error) -> Void in
                
                
                
            })
            
        }
        
    }
    
    func createGameScene() {
        
        var appdelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let scene = appdelegate.getScene();
        
        scene.size = self.view.frame.size
        
        scene.physicsWorld.contactDelegate = scene
        
        scene.iAdCallback = { (show: Bool) -> Void in
            
            if self.adView == nil && show == true {
                self.showAds()
            } else if show == false {
                self.hideAds()
            }
            
        }
        
        scene.launchGameCenterCallback = { () -> Bool in
        
            if self.gameCenterEnabled == false {
                
                return false
                
            }
            
            self.showGameCenter()
            
            return true
            
        }
        
        scene.highScoreGameCenterCallback = { (score: Int) -> Void in
            
            self.sendHighScore(score)
            
        }
        
        scene.gameCenterStatus = { () -> Bool in
            
            return self.gameCenterEnabled
            
        }
        
        scene.initialize()
                            
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
}

class GameStoreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var background: UIImage = UIImage.alloc()
    
    @IBOutlet var StoreNavigationBar: UINavigationBar!
    @IBOutlet var StoreItemsView: UITableView!
    @IBAction func CloseClick(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBOutlet var CellLabel: UILabel!
    
    var items: [GameStoreDictionary] = [
        
        GameStoreDictionary(
            setName: "We",
            setImage: "background-1",
            setPrice: 100
        ),
        GameStoreDictionary(
            setName: "Heart Elias Was Here",
            setImage: "swift  ",
            setPrice: 3000
        ),
        
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(patternImage: background)
        StoreNavigationBar.backgroundColor = UIColor.clearColor()
        
        StoreItemsView.layoutMargins = UIEdgeInsetsZero;
        StoreItemsView.backgroundColor = UIColor.clearColor()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: GameStoreCell = tableView.dequeueReusableCellWithIdentifier("GameStoreCell", forIndexPath: indexPath) as GameStoreCell
        let item: GameStoreDictionary = items[indexPath.row]
        
        var CellColorView = UIView()
        CellColorView.backgroundColor = UIColor.whiteColor()
        
        cell.selectedBackgroundView = CellColorView
        
        cell.Title!.text = item.name
        cell.Title!.textColor = UIColor.whiteColor()
        
        cell.Image!.layer.cornerRadius = CGFloat(5.0)
        cell.Image!.clipsToBounds = true
        cell.Image!.image = item.image
        
        cell.layoutMargins = UIEdgeInsetsZero
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = self.storyboard!.instantiateViewControllerWithIdentifier("GameStoreItem") as GameStoreItemViewController
        
        vc.background = background
        
        vc.item = items[indexPath.row]
        
        self.presentViewController(vc, animated: true, completion: nil)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }
    
}

class GameStoreCell: UITableViewCell {
    
    @IBOutlet var Title: UILabel!
    @IBOutlet var Image: UIImageView!
    
}

class GameStoreItemViewController: UIViewController {
    
    @IBOutlet var GameStoreItemNavigationItem: UINavigationItem!
    
    @IBOutlet var Buy: UIButton!
    @IBAction func GameStoreItemCloseClick(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var item: GameStoreDictionary?
    var background: UIImage = UIImage.alloc()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        GameStoreItemNavigationItem.title = item!.name
        
        Buy.layer.borderWidth = 2
        Buy.layer.borderColor = UIColor.whiteColor().CGColor
        Buy.layer.cornerRadius = 5
        Buy.layer.masksToBounds = true
        
        var WhiteSquare: UIImage = getSquareColorImage(UIColor.whiteColor())
        Buy.setBackgroundImage(WhiteSquare, forState: UIControlState.Highlighted)
        
        var priceTitle: String = String(item!.price)
        Buy.setTitle(priceTitle, forState: UIControlState.Normal)
        
        var BuySizeString: String = Buy.titleForState(UIControlState.Normal)!
        var BuySizeNSString: NSString = BuySizeString as NSString
        var BuySize: CGSize = BuySizeNSString.sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(15.0)])
        
        Buy.frame = CGRectMake(539, 8, BuySize.width + 15, BuySize.height + 12.5)
        
        view.backgroundColor = UIColor(patternImage: background)
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
}
