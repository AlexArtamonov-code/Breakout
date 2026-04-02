//
//  GameScene.swift
//  Breakout
//
//  Created by Alex Artamonov on 3/30/26.
//
var ball = SKShapeNode()
var paddle = SKSpriteNode()
var brick = SKSpriteNode()
var loseZone = SKSpriteNode()
var playLabel = SKLabelNode()
var livesLabel = SKLabelNode()
var scoreLabel = SKLabelNode()
var playingGame = false
var score = 0
var lives = 3
import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        createBackground()
        resetGame()
        makeLoseZone()
        makeLabels()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if playingGame {
                paddle.position.x = location.x
            } else {
                for node in nodes(at: location) {
                    if node.name == "playLabel" {
                        playingGame = true
                        node.alpha = 0
                        score = 0
                        lives = 3
                        updateLabels()
                        kickBall()
                    }
                }
            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if playingGame {
                paddle.position.x = location.x
            }
        }
    }
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.name == "brick" ||
           contact.bodyB.node?.name == "brick" {
            gameOver(winner: true)
        }
        
        if contact.bodyA.node?.name == "loseZone" ||
           contact.bodyB.node?.name == "loseZone" {
            gameOver(winner: false)
        }
    }
    func resetGame() {
        // this stuff happens before each game starts
        makeBall()
        makePaddle()
        makeBrick()
        updateLabels()
    }
    func kickBall(){
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.applyImpulse(CGVector(dx: 3, dy: 5))
    }
    func updateLabels() {
        scoreLabel.text = "Score: \(score)"
        livesLabel.text = "Lives: \(lives)"
    }
    func createBackground() {
        let stars = SKTexture(imageNamed: "Stars")
        
        for i in 0...1 {
            let starsBackground = SKSpriteNode(texture: stars)
            starsBackground.zPosition = -1
            starsBackground.position = CGPoint(
                x: 0,
                y: starsBackground.size.height * CGFloat(i)
            )
            addChild(starsBackground)
            
            let moveDown = SKAction.moveBy(
                x: 0,
                y: -starsBackground.size.height,
                duration: 20
            )
            
            let moveReset = SKAction.moveBy(
                x: 0,
                y: starsBackground.size.height,
                duration: 0
            )
            
            let moveLoop = SKAction.sequence([moveDown, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            starsBackground.run(moveForever)
        }
    }
    func makeBall() {
        ball.removeFromParent() // remove the ball (if it exists)
        
        ball = SKShapeNode(circleOfRadius: 10)
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        ball.strokeColor = .black
        ball.fillColor = .yellow
        ball.name = "ball"
        
        // physics shape matches ball image
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        
        // ignores all forces and impulses
        ball.physicsBody?.isDynamic = false
        
        // use precise collision detection
        ball.physicsBody?.usesPreciseCollisionDetection = true
        
        // no loss of energy from friction
        ball.physicsBody?.friction = 0
        
        // gravity is not a factor
        ball.physicsBody?.affectedByGravity = false
        
        // bounces fully off of other objects
        ball.physicsBody?.restitution = 1
        
        // does not slow down over time
        ball.physicsBody?.linearDamping = 0
        
        ball.physicsBody?.contactTestBitMask = (ball.physicsBody?.collisionBitMask)!
        
        addChild(ball) // add ball object to the view
    }
    func makePaddle() {
        paddle.removeFromParent() // remove the paddle, if it exists
        
        paddle = SKSpriteNode(
            color: .white,
            size: CGSize(width: frame.width / 4, height: 20)
        )
        
        paddle.position = CGPoint(
            x: frame.midX,
            y: frame.minY + 125
        )
        
        paddle.name = "paddle"
        
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.isDynamic = false
        
        addChild(paddle)
    }
    func makeBrick() {
        brick.removeFromParent()  // remove the brick, if it exists
        brick = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 20))
        brick.position = CGPoint(x: frame.midX, y: frame.maxY - 50)
        brick.name = "brick"
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
        brick.physicsBody?.isDynamic = false
        addChild(brick)
    }
    func makeLoseZone() {
        loseZone = SKSpriteNode(color: .red, size: CGSize(width: frame.width, height: 50))
        loseZone.position = CGPoint(x: frame.midX, y: frame.minY + 25)
        loseZone.name = "loseZone"
        loseZone.physicsBody = SKPhysicsBody(rectangleOf: loseZone.size)
        loseZone.physicsBody?.isDynamic = false
        addChild(loseZone)
    }
    func makeLabels() {
        playLabel.fontSize = 24
        playLabel.text = "Tap to start"
        playLabel.fontName = "Arial"
        playLabel.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        playLabel.name = "playLabel"
        addChild(playLabel)
        
        livesLabel.fontSize = 18
        livesLabel.fontColor = .black
        livesLabel.fontName = "Arial"
        livesLabel.position = CGPoint(x: frame.minX + 50, y: frame.minY + 18)
        addChild(livesLabel)
        
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = .black
        scoreLabel.fontName = "Arial"
        scoreLabel.position = CGPoint(x: frame.maxX - 50, y: frame.minY + 18)
        addChild(scoreLabel)
    }
    func gameOver(winner: Bool) {
        playingGame = false
        playLabel.alpha = 1
        resetGame()
        
        if winner {
            playLabel.text = "You win! Tap to play again"
        } else {
            playLabel.text = "You lose! Tap to play again"
        }
    }
}
