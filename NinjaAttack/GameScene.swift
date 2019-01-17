/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import QuartzCore
import SpriteKit
import Foundation

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
  return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}
func shakeCamera(layer:SKSpriteNode, duration:Float) {
  
  let amplitudeX:Float = 10;
  let amplitudeY:Float = 6;
  let numberOfShakes = duration / 0.04;
  var actionsArray:[SKAction] = [];
  for _ in 1...Int(numberOfShakes) {
    let moveX = Float(arc4random_uniform(UInt32(amplitudeX))) - amplitudeX / 2;
    let moveY = Float(arc4random_uniform(UInt32(amplitudeY))) - amplitudeY / 2;
    let shakeAction = SKAction.moveBy(x: CGFloat(moveX), y: CGFloat(moveY), duration: 0.02);
    shakeAction.timingMode = SKActionTimingMode.easeOut;
    actionsArray.append(shakeAction);
    actionsArray.append(shakeAction.reversed());
  }
  
  let actionSeq = SKAction.sequence(actionsArray);
  layer.run(actionSeq);
}



class GameScene: SKScene {
  
  //Creates a new star field
  var partOneSpd = -48
  var partTwoSpd = -32
  var partThreeSpd = -20
  var hitsTaken = 0
  var timeLeft = 5.0
  
  func starfieldEmitterNode(speed: CGFloat, lifetime: CGFloat, scale: CGFloat, birthRate: CGFloat, color: SKColor) -> SKEmitterNode {
    let star = SKLabelNode(fontNamed: "Helvetica")
    star.fontSize = 80.0
    star.text = "✦"
    let textureView = SKView()
    let texture = textureView.texture(from: star)
    texture!.filteringMode = .nearest
    
    let emitterNode = SKEmitterNode()
    
    emitterNode.particleTexture = texture
    emitterNode.particleBirthRate = birthRate
    emitterNode.particleColor = color
    emitterNode.particleLifetime = lifetime
    emitterNode.particleSpeed = speed
    emitterNode.particleScale = scale
    emitterNode.particleColorBlendFactor = 1
    emitterNode.position = CGPoint(x: frame.midX, y: frame.maxY)
    emitterNode.particlePositionRange = CGVector(dx: (frame.maxX + 1000), dy: 0)
    emitterNode.particleSpeedRange = 16.0
    emitterNode.emissionAngle = 120
    emitterNode.particleRotation = 4
    emitterNode.particleRotationRange = 90
    
    //Rotates the stars
    emitterNode.particleAction = SKAction.repeatForever(SKAction.sequence([
      SKAction.rotate(byAngle: CGFloat(-Double.pi/4), duration: 1),
      SKAction.rotate(byAngle: CGFloat(Double.pi/4), duration: 1)]))
    
    //Causes the stars to twinkle
    let twinkles = 20
    let colorSequence = SKKeyframeSequence(capacity: twinkles*2)
    let twinkleTime = 1.0 / CGFloat(twinkles)
    for i in 0..<twinkles {
      colorSequence.addKeyframeValue(SKColor.white,time: CGFloat(i) * 2 * twinkleTime / 2)
      colorSequence.addKeyframeValue(SKColor.yellow, time: (CGFloat(i) * 2 + 1) * twinkleTime / 2)
    }
    emitterNode.particleColorSequence = colorSequence
    
    emitterNode.advanceSimulationTime(TimeInterval(lifetime))
    return emitterNode
  }
  
  func createStarLayers() {
    //A layer of a star field
    let starfieldNode = SKNode()
    starfieldNode.name = "starfieldNode"
    starfieldNode.addChild(starfieldEmitterNode(speed: CGFloat(partOneSpd), lifetime: size.height / 23, scale: 0.2, birthRate: 1, color: SKColor.lightGray))
    addChild(starfieldNode)
    
    //A second layer of stars
    var emitterNode = starfieldEmitterNode(speed: CGFloat(partTwoSpd), lifetime: size.height / 10, scale: 0.14, birthRate: 2, color: SKColor.gray)
    emitterNode.zPosition = -10
    starfieldNode.addChild(emitterNode)
    
    //A third layer
    emitterNode = starfieldEmitterNode(speed: CGFloat(partThreeSpd), lifetime: size.height / 5, scale: 0.1, birthRate: 5, color: SKColor.darkGray)
    starfieldNode.addChild(emitterNode)
    
    //player score
  }
  
  struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let player   : UInt32 = 0b1       // 1
    static let projectile: UInt32 = 0b10      // 2
    static let asteroid: UInt32 = 0b10
  }
  
  // 1
  let player = SKSpriteNode(imageNamed: "rocket")
  
  
  var numAsteroids = 0
  
  override func didMove(to view: SKView) {
    
    // 3
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    // 4
    addChild(player)
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
    
    
    run(SKAction.repeatForever(
      SKAction.sequence([
        SKAction.run(addMonster), SKAction.run(addMonster),
                SKAction.run(addMonster),
        SKAction.wait(forDuration: 1.0)
        ])
    ))
    createStarLayers()
    let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
    backgroundMusic.autoplayLooped = true
    addChild(backgroundMusic)
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }
  
  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }
  
  var scoreLabel = SKLabelNode(fontNamed: "Copperplate")
  var firstPress = 0
  
  func updateScore() {
    
      scoreLabel.text = "Score: " + "\(numAsteroids * 100)"
      scoreLabel.position = CGPoint(x: size.width * 0.5, y: size.height - 25)
      scoreLabel.fontColor = .red
      scoreLabel.fontName = "Copperplate"
      scoreLabel.fontSize = 28.0
      addChild(scoreLabel)
  }
  
  func removeOldLabel() {
    scoreLabel.removeFromParent()
  }
  
  func addMonster() {
    
    // Create sprite
    let asteroid = SKSpriteNode(imageNamed: "asteroid")
    
    asteroid.physicsBody = SKPhysicsBody(rectangleOf: asteroid.size) // 1
    asteroid.physicsBody?.isDynamic = true // 2
    asteroid.physicsBody?.categoryBitMask = PhysicsCategory.player // 3
    asteroid.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4
    asteroid.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
    
    // Determine where to spawn the monster along the Y axis
    let actualY = random(min: asteroid.size.height/2, max: size.height - asteroid.size.height/2)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    asteroid.position = CGPoint(x: size.width + asteroid.size.width/2, y: actualY)
    
    // Add the monster to the scene
    addChild(asteroid)
    numAsteroids += 1
    
    // Determine speed of the monster
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
    
    // Create the actions
    let actionMove = SKAction.move(to: CGPoint(x: -asteroid.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
    
    let actionMoveDone = SKAction.removeFromParent()
    let loseAction = SKAction.run() { [weak self] in
      guard let `self` = self else { return }
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    asteroid.run(SKAction.sequence([actionMove, actionMoveDone]))
  }
  func runCheck(asteroid: SKSpriteNode, player: SKSpriteNode, scoreLabel: SKLabelNode) {
    projectileDidCollideWithPlayer(asteroid: asteroid, player: player, hitsTaken: hitsTaken)
  }
  
  var location = CGPoint(x: 50, y: 50)
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      location = touch.location(in: self)
      timeLeft = 5.0
      player.position.x = location.x
      player.position.y = location.y
      removeOldLabel()
      updateScore()
    }
    player.physicsBody = SKPhysicsBody(circleOfRadius: 1)
    // this defines the mass, roughness and bounciness
    player.physicsBody?.friction = 0.2
    player.physicsBody?.restitution = 0.8
    player.physicsBody?.mass = 0.1
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1 - Choose one of the touches to work with
    
    guard let touch = touches.first else {
      return
    }
    run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
    
    let touchLocation = touch.location(in: self)
    player.physicsBody = SKPhysicsBody(circleOfRadius: 1)
    // this defines the mass, roughness and bounciness
    player.physicsBody?.friction = 0.2
    player.physicsBody?.restitution = 0.8
    player.physicsBody?.mass = 0.1
    
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      location = touch.location(in: self)
      player.position.x = location.x
      player.position.y = location.y
      removeOldLabel()
      updateScore()
    }
    player.physicsBody = SKPhysicsBody(circleOfRadius: 1)
    // this defines the mass, roughness and bounciness
    player.physicsBody?.friction = 0.2
    player.physicsBody?.restitution = 0.8
    player.physicsBody?.mass = 0.1
  }
  func projectileDidCollideWithPlayer(asteroid: SKSpriteNode, player: SKSpriteNode, hitsTaken: Int) {
    print(hitsTaken)
    asteroid.removeFromParent()
    player.removeFromParent()
    if (hitsTaken >= 2) {
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      view?.presentScene(gameOverScene, transition: reveal)
    }
  }
  func killPlayerIfStopped(timeLeft: Double) {
    SKAction.wait(forDuration: timeLeft)
    let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
    let gameOverScene = GameOverScene(size: self.size, won: false)
    view?.presentScene(gameOverScene, transition: reveal)
  }
}

extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    // 1
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
    
    // 2
    if ((firstBody.categoryBitMask & PhysicsCategory.player != 0) &&
      (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
      if let player = firstBody.node as? SKSpriteNode,
        let asteroid = secondBody.node as? SKSpriteNode {
        projectileDidCollideWithPlayer(asteroid: asteroid, player: player, hitsTaken: hitsTaken)
        killPlayerIfStopped(timeLeft: timeLeft)
        hitsTaken += 1
        shakeCamera(layer: player, duration: 2.5)
      }
    }
  }
  
}



