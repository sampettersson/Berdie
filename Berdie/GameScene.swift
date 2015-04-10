//
//  GameScene.swift
//  TheLostKiwi
//
//  Created by Sam Pettersson on 03/09/14.
//  Copyright (c) 2014 lesr. All rights reserved.
//

import SpriteKit
import CoreMotion
import AVFoundation
import GameKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var launchGameCenterCallback: (() -> Bool)?
    var highScoreGameCenterCallback: ((score: Int) -> Void)?
    var iAdCallback: ((show: Bool) -> Void)?
    var gameCenterStatus: (() -> Bool)?
    var enableGameCenter: (() -> Void)?
    
    let motionManager: CMMotionManager = CMMotionManager()
    let playerCategory: UInt32 = 0x00000001
    let coinCategory: UInt32 = 0x00000002
    let frameCategory: UInt32 = 0x00000003
    let enemyCategory: UInt32 = 0x00000004
    
    var initialized: Bool = false
    var playing: Bool = false
    
    var coinBalance: Int!
    var difficulty: Int!
    
    var coins: Int!
    var placedCoins: Int!
    
    var timeLeft: Int!
    var clouds: [SKSpriteNode] = [SKSpriteNode]()
    var thePhysicsWorld: SKPhysicsWorld!
    
    var soundPlayer = AVAudioPlayer()
    var backgroundPlayer = AVAudioPlayer()
    
    var soundEnabled: Bool = true
    
    var cloudTimer: NSTimer!
    var countdownTimer: NSTimer!
    
    private var countdownLabel = SKLabelNode(fontNamed: "VCR OSD Mono")
    private var difficultyLabel = SKLabelNode(fontNamed: "VCR OSD Mono")
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        var touch: UITouch = touches.anyObject() as UITouch
        var location: CGPoint = touch.locationInNode(self)
        var node: SKNode = self.nodeAtPoint(location)
        
        if node.name == "gameOverRetry" {
            
            runButtonActionOnNode(node, callback: { () -> Void in
              
                self.hideGameOver(true)
                
                self.difficulty = 0
                
                self.startGame()
                
            })
            
        } else if node.name == "mainPlay" {
            
            runButtonActionOnNode(node, callback: { () -> Void in
              
                self.hideMain()
                self.startGame()
                
            })
            
        } else if node.name == "gameOverStore" {
            
            runButtonActionOnNode(node, callback: { () -> Void in
              
                self.hideGameOver(false)
                self.showMain()
                
            })
            
        } else if node.name == "mainGameCenter" {
            
            var nodeName = node.name
            var nodePosition = node.position

            runButtonActionOnNode(node, callback: { () -> Void in
                
                self.launchGameCenterCallback?()
                node.name = nodeName
                node.position = nodePosition
                self.addNode(node)
                return
                
            })
            
        } else if node.name == "pause" {
            
            runButtonActionOnNode(node, callback: { () -> Void in
                
                self.pause()
                
            })
            
        } else if node.name == "pausePlay" {
            
            runButtonActionOnNode(node, callback: { () -> Void in
                
                self.pause()
                
            })
            
        } else if node.name == "pauseQuit" {
            
            runButtonActionOnNode(node, callback: { () -> Void in
                
                self.pause()
                self.stopGame()
                self.showMain()
                
            })
            
        } else if node.name == "mainCredits" {
            
            var nodeName = node.name
            var nodePosition = node.position
            
            runButtonActionOnNode(node, callback: { () -> Void in
                
                var appdelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                appdelegate.showCredits()
                node.name = nodeName
                node.position = nodePosition
                self.addNode(node)
                
            })
            
        } else if node.name == "mainSound" {
            
            var nodeName = node.name
            var nodePosition = node.position
            
            runButtonActionOnNode(node, callback: { () -> Void in
                
                var labelNode = node as? SKLabelNode
                
                var mainMusic = self.getNode("mainMusic") as? SKLabelNode

                if self.soundEnabled == true {
                
                    self.soundEnabled = false
                
                    labelNode?.text = "SOUND OFF"
                
                    self.backgroundPlayer.stop()
                    
                    self.hideNode(mainMusic)
                
                } else {
                
                    self.soundEnabled = true
                
                    labelNode?.text = "SOUND ON"
                    
                    if mainMusic?.text == "MUSIC ON" {
                     
                        var backgroundSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("background", ofType: "mp3")!)
                        self.backgroundPlayer = AVAudioPlayer(contentsOfURL: backgroundSound, error: nil)
                        self.backgroundPlayer.numberOfLoops = -1
                        self.backgroundPlayer.play()
                        
                    }
                    
                    self.showNode(mainMusic)
                
                }
                
                node.name = nodeName
                node.position = nodePosition
                self.addNode(node)
                
            })
            
        } else if node.name == "mainMusic" {
            
            var nodeName = node.name
            var nodePosition = node.position
            var labelNode = node as? SKLabelNode
            
            runButtonActionOnNode(node, callback: { () -> Void in
              
                if self.backgroundPlayer.playing == true {
                    
                    self.backgroundPlayer.stop()
                    labelNode?.text = "MUSIC OFF"
                    
                } else {
                    
                    var backgroundSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("background", ofType: "mp3")!)
                    self.backgroundPlayer = AVAudioPlayer(contentsOfURL: backgroundSound, error: nil)
                    self.backgroundPlayer.numberOfLoops = -1
                    self.backgroundPlayer.play()
                    labelNode?.text = "MUSIC ON"
                    
                }
                
                
                node.name = nodeName
                node.position = nodePosition
                self.addNode(node)
                
            })
            
        }
        
    }
    
    func runButtonActionOnNode(node: SKNode, callback: (() -> Void)?) {
        
        node.name = nil
        
        var moveUp = SKAction.moveByX(0, y: 5, duration: 0.1)
        var fadeOut = SKAction.fadeAlphaTo(0, duration: 0.2)
        var pause = SKAction.waitForDuration(0.2)
        var remove = SKAction.removeFromParent()
        var moveSequence = SKAction.sequence([moveUp, fadeOut, pause, remove])
        
        node.runAction(moveSequence, completion: { () -> Void in
            callback?()
            return
        })
        
    }
    
    func getNode(name: String) -> SKNode? {
        
        var node: SKNode?
        
        for child in self.children {
            
            if (child as? SKNode)?.name != nil {
                
                if child.name == name {
                    node = child as? SKNode
                }
                
            }
            
        }
        
        return node
        
    }
    
    func addNode(node: SKNode) {
        
        node.alpha = 0
        
        var fadeIn = SKAction.fadeAlphaTo(1, duration: 0.2)
        
        self.addChild(node)
        
        node.runAction(fadeIn)
        
    }
    
    func removeNode(node: SKNode!) {
        
        if node == nil {
            
            return
        
        }
    
        var fadeOut = SKAction.fadeAlphaTo(0, duration: 0.2)
        var pause = SKAction.waitForDuration(0.2)
        var removeFromParent = SKAction.removeFromParent()
        
        var actionSequence = SKAction.sequence([fadeOut, pause, removeFromParent])
        
        node.runAction(actionSequence)
    
    }
    
    func showNode(node: SKNode?) {
        
        if node == nil {
            //Skip
            return
        }
        
        var fadeIn = SKAction.fadeAlphaTo(1, duration: 0.2)
        
        node!.runAction(fadeIn)
        
    }
    
    func hideNode(node: SKNode!) {
        
        if node == nil {
            
            return
            
        }
        
        var fadeOut = SKAction.fadeAlphaTo(0, duration: 0.2)
        var pause = SKAction.waitForDuration(0.2)
        
        var actionSequence = SKAction.sequence([fadeOut, pause])
        
        node.runAction(actionSequence)
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        var coin: SKNode?
        
        if contact.bodyA.node?.name == "coin" {
            
            coin = contact.bodyA.node
            
        } else if contact.bodyB.node?.name == "coin" {
            
            coin = contact.bodyB.node
            
        }
        
        if coin != nil {
            
            coin!.physicsBody = nil
            
            removeNode(coin!)
            
            coinBalance = coinBalance + 1
            updateCoinBalance()
            generateCoins()
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            if soundEnabled == true {
                
                var coinSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("coin", ofType: "wav")!)
                soundPlayer = AVAudioPlayer(contentsOfURL: coinSound, error: nil)
                soundPlayer.play()
                
            }
            
            if coins == nil {
            
                coins = 1
                
            } else {
                
                coins = coins + 1
                
            }
            
            timeLeft = timeLeft + 1
            updateCountdownLabel()
            
            if coins == difficulty {
                
                coins = 0
                levelUp()
                
            }
            
        }
        
        var enemy: SKNode?
        
        if contact.bodyA.node?.name?.rangeOfString("enemy_") != nil {
            
            enemy = contact.bodyA.node
            
        } else if contact.bodyB.node?.name?.rangeOfString("enemy_") != nil {
            
            enemy = contact.bodyB.node
            
        }
        
        if enemy != nil {
            
            //enemy!.physicsBody = nil
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            var after1 = dispatch_time(DISPATCH_TIME_NOW, Int64(0.15 * Double(NSEC_PER_SEC)))
            var after2 = dispatch_time(DISPATCH_TIME_NOW, Int64(0.30 * Double(NSEC_PER_SEC)))
            var after3 = dispatch_time(DISPATCH_TIME_NOW, Int64(0.45 * Double(NSEC_PER_SEC)))
            
            dispatch_after(after1, dispatch_get_main_queue(), { () -> Void in
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
            })
            
            dispatch_after(after2, dispatch_get_main_queue(), { () -> Void in
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
            })
            
            dispatch_after(after3, dispatch_get_main_queue(), { () -> Void in
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
            })
            
            var emitter: SKEmitterNode = SKEmitterNode(fileNamed: "Explosion")
            emitter.position = enemy!.position
            emitter.numParticlesToEmit = 15
            
            var frame1: SKTexture = SKTexture(imageNamed: "bomb_activated_frame1")
            var frame2: SKTexture = SKTexture(imageNamed: "bomb_activated_frame2")
            var frame3: SKTexture = SKTexture(imageNamed: "bomb_activated_frame3")
            var frame4: SKTexture = SKTexture(imageNamed: "bomb_activated_frame4")
            var frame5: SKTexture = SKTexture(imageNamed: "bomb_activated_frame5")
            
            var frameSequence: [SKTexture] = [frame1, frame2, frame3, frame4, frame5]
            
            var action: SKAction = SKAction.animateWithTextures(frameSequence, timePerFrame: 0.15)
            
            enemy!.runAction(action, completion: { () -> Void in
                
                self.addNode(emitter)
                self.removeNode(enemy)
                self.removeNode(emitter)
                
                if self.soundEnabled == true {
                    
                    if enemy!.name == "enemy_bomb" {
                        
                        var bombSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("bomb", ofType: "wav")!)
                        self.soundPlayer = AVAudioPlayer(contentsOfURL: bombSound, error: nil)
                        self.soundPlayer.play()
                        
                    }
                    
                }
                
                self.gameOver()
                
            })
            
        }
        
        
    }
    
    func startGame() {
        
        playing = true
        
        var pause = SKSpriteNode(imageNamed: "pause")
        pause.name = "pause"
        pause.zPosition = -1
        pause.position = CGPoint(x: self.frame.minX + pause.frame.width, y: self.frame.maxY - pause.frame.height)
        
        addNode(pause)
        
        var character = SKSpriteNode(imageNamed:"character_1")
        
        character.name = "character"
        
        character.physicsBody = SKPhysicsBody(texture: character.texture!, size: character.texture!.size())
        character.physicsBody?.mass = 10
        character.physicsBody?.categoryBitMask = playerCategory
        character.physicsBody?.collisionBitMask = coinCategory | enemyCategory
        character.physicsBody?.contactTestBitMask = coinCategory | enemyCategory
        
        character.zRotation = 0
        character.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        
        self.addChild(character)
        
        if cloudTimer == nil {
            setCloudTimer()
        }
        
        difficulty = 1
        timeLeft = 40
        
        updateCountdownLabel()
        
        difficultyLabel.text = "LEVEL:" + String(difficulty)
        difficultyLabel.name = "level"
        difficultyLabel.fontSize = 20;
        difficultyLabel.position = CGPointMake(10, 5)
        difficultyLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        difficultyLabel.zPosition = 2
        
        addNode(difficultyLabel)
        
        setCountdownTimer()
        
        generateCoins()
        generateBombs()
        
                
        if (motionManager.deviceMotionAvailable) {
            
            self.motionManager.deviceMotionUpdateInterval = 5.0 / 60.0
            
            motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrameXArbitraryZVertical, toQueue: NSOperationQueue()) { (motion, error) in
                
                if error == nil {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        var orientation = UIDevice.currentDevice().orientation
                        
                        if orientation.isLandscape {
                            
                            self.scene?.physicsWorld.gravity = CGVectorMake(CGFloat(motion.gravity.x * 2.5), CGFloat(motion.gravity.y * 2.5))
                            
                        } else {
                            
                            self.scene?.physicsWorld.gravity = CGVectorMake(CGFloat(motion.gravity.x * 2.5), CGFloat(motion.gravity.y * 2.5))
                            
                        }
                        
                        return
                        
                    })
                    
                }
                
                
            }
            
        }
        
    }
    
    func levelUp() {
        
        if soundEnabled == true {
            
            var levelUpSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("levelup", ofType: "m4a")!)
            
            soundPlayer = AVAudioPlayer(contentsOfURL: levelUpSound, error: nil)
            soundPlayer.play()
            
        }
        
        difficulty = difficulty + 1
        difficultyLabel.text = "LEVEL:" + String(difficulty)
        
        timeLeft = timeLeft + Int(Double(difficulty) * 0.1)
        updateCountdownLabel()
        
        var levelUpSign = SKLabelNode(fontNamed: "VCR OSD Mono")
        levelUpSign.fontSize = 40
        levelUpSign.text = "LEVEL UP!"
        levelUpSign.zPosition = -1
        levelUpSign.position = CGPointMake(self.frame.midX, self.frame.midY)
        levelUpSign.alpha = 0
        
        self.addChild(levelUpSign)
        
        var fadeIn = SKAction.fadeAlphaTo(1, duration: 0.2)
        var pause = SKAction.waitForDuration(0.5)
        var fadeOut = SKAction.fadeAlphaTo(0, duration: 0.2)
        
        var sequence = SKAction.sequence([fadeIn, pause, fadeOut])
        
        levelUpSign.runAction(sequence)
        
        placedCoins = 0
        generateCoins()
        generateBombs()
        
        if countdownTimer != nil {
            
            countdownTimer.invalidate()
            countdownTimer = nil
            
        }
        
        setCountdownTimer()
        
    }
    
    func gameOver() {
        
        if playing == false {
            // Game not running skip
            return
        }
        
        iAdCallback?(show: true)
        
        var gameOverTitle = SKLabelNode(fontNamed: "VCR OSD Mono")
        gameOverTitle.name = "gameOverTitle"
        var gameOverLevel = SKLabelNode(fontNamed: "VCR OSD Mono")
        gameOverLevel.name = "gameOverLevel"
        var gameOverRetry = SKLabelNode(fontNamed: "VCR OSD Mono")
        gameOverRetry.name = "gameOverRetry"
        var gameOverStore = SKLabelNode(fontNamed: "VCR OSD Mono")
        gameOverStore.name = "gameOverStore"
        
        highScoreGameCenterCallback?(score: difficulty)
        
        if soundEnabled == true {
            
            var gameOverSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("gameover", ofType: "wav")!)
            soundPlayer = AVAudioPlayer(contentsOfURL: gameOverSound, error: nil)
            soundPlayer.play()
            
        }
        
        if cloudTimer != nil {
            
            cloudTimer.invalidate()
            cloudTimer = nil
            
        }
        
        var generator = clouds.generate()
        
        while let cloud = generator.next() {
            
            cloud.removeAllActions()
            
            var x: CGFloat = 0
        
            if cloud.position.x > self.frame.midX {
                 x = cloud.frame.width + self.frame.maxX
            } else {
                x = -abs(cloud.frame.width)
            }
            
            var y: CGFloat = 0
            
            if cloud.position.y > self.frame.midY {
                y = cloud.frame.width + self.frame.maxX
            } else {
                y = -abs(cloud.frame.width)
            }
            
            var move = SKAction.moveTo(CGPointMake(x, y), duration: 4)
            
            cloud.runAction(move)
            
        }
        
        stopGame()
        
        gameOverTitle.fontSize = 40
        gameOverTitle.text = "GAME OVER"
        gameOverTitle.fontColor = UIColor(rgb: 0xFF2D55)
        gameOverTitle.position = CGPointMake(self.frame.midX, self.frame.midY)
        gameOverTitle.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        gameOverTitle.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        
        addNode(gameOverTitle)
        
        gameOverLevel.fontSize = 20
        gameOverLevel.text = "YOU GOT TO LEVEL " + String(difficulty)
        gameOverLevel.position = CGPointMake(self.frame.midX, self.frame.midY - gameOverTitle.frame.height - 5)
        gameOverLevel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        gameOverLevel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        
        addNode(gameOverLevel)

        gameOverRetry.fontSize = 25
        gameOverRetry.text = "RETRY?"
        gameOverRetry.position = CGPointMake(self.frame.midX, self.frame.midY - gameOverTitle.frame.height - gameOverLevel.frame.height - 25)
        gameOverRetry.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        gameOverRetry.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        
        addNode(gameOverRetry)
        
        gameOverStore.fontSize = 25
        gameOverStore.text = "MAIN MENU"
        gameOverStore.position = CGPointMake(self.frame.midX, gameOverRetry.frame.origin.y - gameOverRetry.frame.height - 5)
        gameOverStore.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        gameOverStore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        
        addNode(gameOverStore)
        
        
    }
    
    func hideGameOver(hideAds: Bool) {
        
        if hideAds == true {
            iAdCallback?(show: false)
        }
        
        var gameOverTitle = getNode("gameOverTitle")
        var gameOverLevel = getNode("gameOverLevel")
        var gameOverRetry = getNode("gameOverRetry")
        var gameOverStore = getNode("gameOverStore")
        
        removeNode(gameOverTitle)
        removeNode(gameOverLevel)
        removeNode(gameOverRetry)
        removeNode(gameOverStore)
        
    }
    
    func stopGame() {
        
        playing = false
        
        coins = 0
        placedCoins = 0
        
        if countdownTimer != nil {
         
            countdownTimer.invalidate()
            countdownTimer = nil
            
        }
        
        for child in self.children {
            
            var node = child as SKNode
            
            if node.name? == "coin" {
                
                removeNode(node)
                
            } else if node.name? == "character" {
                
                removeNode(node)
                
            } else if node.name?.rangeOfString("enemy_") != nil {
              
                removeNode(node)
                
            } else if node.name? == "countdown" {
                
                removeNode(node)
                
            } else if node.name? == "level" {
                
                removeNode(node)
                
            } else if node.name? == "pause" {
                
                removeNode(node)
                
            }
            
        }
        
    }
    
    func generateCoins() {
        
        var coinsToPlace: Int = difficulty
        
        if placedCoins == nil {
            
            placedCoins = 0
            
        }
        
        if placedCoins == 0 {
            
            coinsToPlace = difficulty - placedCoins
            
            if coinsToPlace >= 5 {
                coinsToPlace = 5
            }
            
        } else {
            
            coinsToPlace = 1
            
            if (placedCoins + coinsToPlace) > difficulty {
                //Skip adding coin
                return
            }
            
        }
        
        var character = getNode("character") as SKSpriteNode

        var size: CGSize = CGSize(width: (character.size.width * 2), height: (character.size.height * 2))
        var radius = SKShapeNode(rectOfSize: character.size)
        
        for var index: Int = 0; index < coinsToPlace; index++ {
            
            var coin: SKSpriteNode = SKSpriteNode(imageNamed: "coin")
            coin.name = "coin"
            
            var randomX = CGFloat(Int.random((40 ... Int(self.frame.maxX - 40))))
            var randomY = CGFloat(Int.random((40 ... Int(self.frame.maxY - 40))))
                
            coin.position = CGPoint(x: randomX, y: randomY)
            coin.alpha = 0
            
            var after = Double(index) * 0.2
            
            Async.main(after: after, block: { () -> Void in
                
                self.addChild(coin)
                
                var action = SKAction.fadeAlphaTo(1, duration: 0.2)
                
                coin.runAction(action, completion: { () -> Void in
                    
                    coin.physicsBody = SKPhysicsBody(texture: coin.texture!, size: coin.texture!.size())
                    coin.physicsBody!.affectedByGravity = false
                    coin.physicsBody!.collisionBitMask = self.playerCategory
                    coin.physicsBody!.categoryBitMask = self.coinCategory
                    coin.physicsBody!.contactTestBitMask = self.playerCategory
                    
                    if self.playing == false {
                        self.placedCoins = 0
                        self.removeNode(coin)
                    }
                    
                })
                
            })
            
            placedCoins = placedCoins + 1
            
        }
        
        
    }
    
    func generateBombs() {
        
        for child in self.children {
            
            var node = child as? SKNode
            
            if node?.name == "enemy_bomb" {
                removeNode(node)
            }
            
        }
        
        if difficulty < 5 {
            //Skip adding bombs
            return
        }
        
        var bombAmount = Int(Float(difficulty) * 0.5)
        
        let randomNumber = arc4random_uniform(100)
        
        if randomNumber > 50 {
         
            bombAmount = 0
            
        }
        
        for var index = 0; index < bombAmount; index++ {
            
            var after = Double(index) * 0.2
            
            var bomb: SKSpriteNode = SKSpriteNode(imageNamed: "bomb_deactivated")
            bomb.name = "enemy_bomb"
            
            var randomX = CGFloat(Int.random((40 ... Int(self.frame.maxX - 40))))
            var randomY = CGFloat(Int.random((40 ... Int(self.frame.maxY - 40))))
            
            bomb.position = CGPoint(x: CGFloat(randomX), y: CGFloat(randomY))
            
            var activateSequence = [SKAction]()
            
            var fadeHalf = SKAction.fadeAlphaTo(0.5, duration: 1)
            var fadeFull = SKAction.fadeAlphaTo(1, duration: 1)

            activateSequence.append(fadeHalf)
            activateSequence.append(fadeFull)
            activateSequence.append(fadeHalf)
            activateSequence.append(fadeFull)
            
            var action = SKAction.sequence(activateSequence)
            
            bomb.runAction(action, completion: { () -> Void in
                
                bomb.physicsBody = SKPhysicsBody(texture: bomb.texture!, size: bomb.texture!.size())
                bomb.physicsBody!.mass = 30
                bomb.physicsBody!.affectedByGravity = false
                bomb.physicsBody!.categoryBitMask = self.enemyCategory
                bomb.physicsBody!.collisionBitMask = self.playerCategory
                bomb.physicsBody!.contactTestBitMask = self.playerCategory
                bomb.zRotation = 0
                
            })
            
            self.addChild(bomb)
            
        }
        
        
    }
    
    func setCountdownTimer() {
        
        countdownTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("countdowntimer"), userInfo: nil, repeats: true)
        
    }
    
    func setCloudTimer() {
        
        cloudTimer = NSTimer.scheduledTimerWithTimeInterval(15, target: self, selector: Selector("cloudsTimer"), userInfo: nil, repeats: true)
        cloudTimer.fire()
        
    }
    
    func updateCountdownLabel() {
    
        countdownLabel.removeFromParent()
        countdownLabel.alpha = 1
        countdownLabel.name = "countdown"
        countdownLabel.fontSize = 20;
        countdownLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        countdownLabel.zPosition = 2
        countdownLabel.fontColor = UIColor.whiteColor()
        countdownLabel.text = "TIME:" + String(timeLeft)
        countdownLabel.position = CGPointMake(self.frame.width - countdownLabel.frame.width - 10, 5)
        self.addChild(countdownLabel)
    
    }
    
    @objc func countdowntimer() {
        
        timeLeft = timeLeft - 1
        
        updateCountdownLabel()
        
        if timeLeft < 4 {
            countdownLabel.fontColor = UIColor(rgb: 0xFF2D55)
        }
        
        if timeLeft <= 0 {
            
            countdownTimer.invalidate()
            countdownTimer = nil
            motionManager.stopAccelerometerUpdates()
            gameOver()
            
        }
        
    }
    
    @objc func cloudsTimer() {
        
        var generator = clouds.generate()
        
        while let cloud = generator.next() {
            
            cloud.removeAllActions()
            
            var randomX = CGFloat(Int.random((-50 ... Int(self.frame.maxX + 50))))
            
            var move = SKAction.moveTo(CGPointMake(randomX, cloud.position.y), duration: 15)
            
            cloud.runAction(move)
            
        }
        
    }
    
    func updateCoinBalance() {
        
        var coinsLabel = getNode("coinsLabel") as SKLabelNode
        var coinsBalance = getNode("coinsBalance") as SKSpriteNode
        
        NSUserDefaults.standardUserDefaults().setObject(coinBalance, forKey: "coin_balance")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        coinsLabel.text = String(coinBalance)
        coinsLabel.position = CGPointMake(self.frame.maxX - coinsLabel.frame.width, self.frame.maxY - 5)
        
        var coinsBalanceX = self.frame.maxX - (coinsLabel.frame.width * 2)
        
        if coinBalance < 10 {
            coinsBalanceX = self.frame.maxX - (coinsLabel.frame.width * 2.5)
        } else {
            coinsBalanceX = self.frame.maxX - (coinsLabel.frame.width * 2)
        }
        
        coinsBalance.size = CGSizeMake(coinsLabel.frame.height, coinsLabel.frame.height)
        coinsBalance.position = CGPointMake(coinsBalanceX, self.frame.maxY - (coinsBalance.frame.height * 0.5) - 5)
        
    }
    
    func pause() {
        
        if self.physicsWorld.speed == 0.0 {
            
            playing = true
            
            setCountdownTimer()
            var pause = SKSpriteNode(imageNamed: "pause")
            pause.name = "pause"
            pause.zPosition = -1
            pause.position = CGPoint(x: self.frame.minX + pause.frame.width, y: self.frame.maxY - pause.frame.height)
            
            addNode(pause)
            
            var pauseResume = getNode("pausePlay")
            removeNode(pauseResume)
            
            var pauseTitle = getNode("pauseTitle")
            removeNode(pauseTitle)
            
            var pauseQuit = getNode("pauseQuit")
            removeNode(pauseQuit)
            
            self.physicsWorld.speed = 1.0
            
        } else {
            
            playing = false
            
            countdownTimer.invalidate()
            countdownTimer = nil
            
            var pauseTitle = SKLabelNode(fontNamed: "VCR OSD Mono")
            pauseTitle.name = "pauseTitle"
            
            pauseTitle.fontSize = 60
            pauseTitle.text = "PAUSED"
            pauseTitle.color = UIColor(rgb: 0xFF2D55)
            pauseTitle.position = CGPointMake(self.frame.midX, self.frame.midY)
            pauseTitle.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
            pauseTitle.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
            
            addNode(pauseTitle)
            
            var pausePlay = SKLabelNode(fontNamed: "VCR OSD Mono")
            pausePlay.name = "pausePlay"
            pausePlay.color = UIColor(rgb: 0xFF2D55)
            pausePlay.fontSize = 20
            pausePlay.text = "RESUME"
            pausePlay.position = CGPointMake(self.frame.midX, self.frame.midY - pauseTitle.frame.height - 5)
            pausePlay.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
            pausePlay.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
            
            addNode(pausePlay)
            
            var pauseQuit = SKLabelNode(fontNamed: "VCR OSD Mono")
            pauseQuit.name = "pauseQuit"
            pauseQuit.color = UIColor(rgb: 0xFF2D55)
            pauseQuit.fontSize = 20
            pauseQuit.text = "QUIT GAME"
            pauseQuit.position = CGPointMake(self.frame.midX, pausePlay.position.y - pausePlay.frame.height - 10)
            pauseQuit.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
            pauseQuit.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
            
            addNode(pauseQuit)
            
            self.physicsWorld.speed = 0.0
            
        }
        
    }
    
    func hideMain() {
        
        iAdCallback?(show: false)
        
        var mainTitle = getNode("mainTitle")
        var mainPlay = getNode("mainPlay")
        var mainCredits = getNode("mainCredits")
        var mainSound = getNode("mainSound")
        var mainMusic = getNode("mainMusic")
        var mainGameCenter = getNode("mainGameCenter")
        
        removeNode(mainTitle)
        removeNode(mainPlay)
        removeNode(mainCredits)
        removeNode(mainSound)
        removeNode(mainMusic)
        removeNode(mainGameCenter)
        
    }
    
    func showMain() {
        
        iAdCallback?(show: true)
        
        var mainTitle = SKLabelNode(fontNamed: "VCR OSD Mono")
        var mainPlay = SKLabelNode(fontNamed: "VCR OSD Mono")
        
        mainTitle.fontSize = 60
        mainTitle.text = "BERDIE"
        mainTitle.name = "mainTitle"
        mainTitle.position = CGPointMake(self.frame.midX, self.frame.midY)
        mainTitle.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        mainTitle.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        
        addNode(mainTitle)
        
        mainPlay.fontSize = 25
        mainPlay.name = "mainPlay"
        mainPlay.text = "PLAY"
        mainPlay.position = CGPointMake(self.frame.midX, self.frame.midY - (mainTitle.frame.height * 1.25))
        mainPlay.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        mainPlay.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        
        addNode(mainPlay)
        
        var mainCredits = SKLabelNode(fontNamed: "VCR OSD Mono")
        mainCredits.fontSize = 25
        mainCredits.name = "mainCredits"
        mainCredits.text = "CREDITS"
        mainCredits.position = CGPointMake(self.frame.midX, mainPlay.position.y - mainPlay.frame.height - 10)
        mainCredits.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        mainCredits.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        
        addNode(mainCredits)
        
        var mainSound = SKLabelNode(fontNamed: "VCR OSD Mono")
        mainSound.fontSize = 25
        mainSound.name = "mainSound"
        
        if soundEnabled == true {
            mainSound.text = "SOUND ON"
        } else {
            mainSound.text = "SOUND OFF"
        }
        
        mainSound.position = CGPointMake(self.frame.midX, mainCredits.position.y - mainCredits.frame.height - 10)
        mainSound.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        mainSound.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        
        addNode(mainSound)
        
        var mainMusic = SKLabelNode(fontNamed: "VCR OSD Mono")
        mainMusic.fontSize = 25
        mainMusic.name = "mainMusic"
        
        if soundEnabled == true {
            mainMusic.text = "MUSIC ON"
        } else {
            mainMusic.text = "MUSIC OFF"
        }
        
        mainMusic.position = CGPointMake(self.frame.midX, mainSound.position.y - mainSound.frame.height - 10)
        mainMusic.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        mainMusic.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        
        addNode(mainMusic)
        
        if soundEnabled == false {
            hideNode(mainMusic)
        }
        
        if gameCenterStatus?() == true {
            
            var mainGameCenter = SKLabelNode(fontNamed: "VCR OSD Mono")
            mainGameCenter.fontSize = 25
            mainGameCenter.name = "mainGameCenter"
            mainGameCenter.text = "GAME CENTER"
            mainGameCenter.position = CGPointMake(self.frame.midX, mainMusic.position.y - mainMusic.frame.height - 10)
            mainGameCenter.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
            mainGameCenter.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
            
            addNode(mainGameCenter)
            
        }
        
    }
    
    func initialize() {
        
        if initialized == true {
            
            //Don't init again
            
            return
        }
        
        if soundEnabled == true {
            
             var backgroundSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("background", ofType: "mp3")!)
            backgroundPlayer = AVAudioPlayer(contentsOfURL: backgroundSound, error: nil)
            backgroundPlayer.numberOfLoops = -1
            backgroundPlayer.play()
            
        }
        
        var getCoinBalance: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("coin_balance")
        
        if getCoinBalance != nil {
            
            coinBalance = NSUserDefaults.standardUserDefaults().objectForKey("coin_balance") as Int
            
        } else {
            
            coinBalance = 0
            
        }
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        self.physicsWorld.contactDelegate = self
        self.physicsBody?.categoryBitMask = frameCategory
        self.physicsBody?.contactTestBitMask = frameCategory
        self.physicsBody?.collisionBitMask = frameCategory
        
        for var index: Int = 0; index < 5; index++ {
            
            var cloud: SKSpriteNode = SKSpriteNode(imageNamed: "cloud_1")
            cloud.name = "cloud"
            cloud.zPosition = -1
            
            var randomX = CGFloat(Int.random((-50 ... Int(self.frame.maxX + 50))))
            var randomY = CGFloat(Int.random((30 ... Int(self.frame.maxY - 30))))
            
            cloud.position = CGPointMake(randomX, randomY)
            
            clouds.append(cloud)
            self.addChild(cloud)
            
        }
        
        setCloudTimer()
        
        var coinsLabel = SKLabelNode(fontNamed: "VCR OSD Mono")
        coinsLabel.name = "coinsLabel"
        coinsLabel.fontSize = 15
        coinsLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        coinsLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Top
        coinsLabel.alpha = 1
        
        var coinsBalance: SKSpriteNode = SKSpriteNode(imageNamed: "coin_balance")
        coinsBalance.name = "coinsBalance"
        coinsBalance.alpha = 1
        
        self.addChild(coinsLabel)
        self.addChild(coinsBalance)
        
        updateCoinBalance()
        
        showMain()
        
        initialized = true
        
    }
    
    override func didMoveToView(view: SKView) {
        
        self.backgroundColor = UIColor(rgb: 0x1AD6FD)
        
    }

}
