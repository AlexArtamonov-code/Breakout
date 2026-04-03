//
//  GameScene.swift
//  Breakout
//
//  Created by Alex Artamonov on 3/30/26.
//
import SpriteKit
import GameplayKit

var ball = SKShapeNode()
var paddle = SKSpriteNode()
var bricks = [SKSpriteNode]()
var removedBricks = 0
var loseZone = SKSpriteNode()
var playLabel = SKLabelNode()
var livesLabel = SKLabelNode()
var scoreLabel = SKLabelNode()
var playingGame = false
var score = 0
var lives = 3

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
        // check brick collisions
        for brick in bricks {
            if contact.bodyA.node == brick || contact.bodyB.node == brick {
                
                score += 1
                updateLabels()
                
                // store next color BEFORE animation
                var nextColor: UIColor?
                
                if brick.color == .blue {
                    nextColor = .orange
                }
                else if brick.color == .orange {
                    nextColor = .green
                }
                
                // 🔴 flash red first
                let flashRed = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.08)
                let wait = SKAction.wait(forDuration: 0.05)
                
                // after flash → change color or remove
                let change = SKAction.run {
                    if let newColor = nextColor {
                        brick.color = newColor
                    } else {
                        // was green → remove
                        brick.removeFromParent()
                        removedBricks += 1
                        
                        if removedBricks == bricks.count {
                            self.gameOver(winner: true)
                        }
                    }
                }
                
                let sequence = SKAction.sequence([flashRed, wait, change])
                brick.run(sequence)
            }
        }
        // increase speed
        ball.physicsBody!.velocity.dx *= CGFloat(1.01)
        ball.physicsBody!.velocity.dy *= CGFloat(1.01)
        
        // lose zone
        if contact.bodyA.node?.name == "loseZone" ||
           contact.bodyB.node?.name == "loseZone" {

            lives -= 1
            updateLabels()

            // ➖ show "-1"
            let minusOne = SKLabelNode(text: "-1")
            minusOne.fontName = "Arial-BoldMT"
            minusOne.fontSize = 40
            minusOne.fontColor = .red
            minusOne.position = CGPoint(x: frame.midX, y: frame.midY)
            minusOne.zPosition = 10
            addChild(minusOne)

            let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let group = SKAction.group([moveUp, fadeOut])
            let remove = SKAction.removeFromParent()

            minusOne.run(SKAction.sequence([group, remove]))

            if lives <= 0 {
                // game over only when all lives are gone
                gameOver(winner: false)
            } else {
                // keep the ball going at the same speed
                // optionally move it back to above the paddle
                let currentVelocity = ball.physicsBody!.velocity
                ball.position = CGPoint(x: paddle.position.x, y: paddle.position.y + 30)
                ball.physicsBody?.velocity = currentVelocity
            }
        }
    }
    
    func resetGame() {
        makeBall()
        makePaddle()
        makeBricks()
        updateLabels()
    }
    
    func kickBall() {
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
            starsBackground.position = CGPoint(x: 0, y: starsBackground.size.height * CGFloat(i))
            addChild(starsBackground)
            
            let moveDown = SKAction.moveBy(x: 0, y: -starsBackground.size.height, duration: 20)
            let moveReset = SKAction.moveBy(x: 0, y: starsBackground.size.height, duration: 0)
            let moveLoop = SKAction.sequence([moveDown, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            starsBackground.run(moveForever)
        }
    }
    
    func makeBall() {
        ball.removeFromParent()
        
        ball = SKShapeNode(circleOfRadius: 10)
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        ball.strokeColor = .black
        ball.fillColor = .yellow
        ball.name = "ball"
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        ball.physicsBody?.isDynamic = false
        ball.physicsBody?.usesPreciseCollisionDetection = true
        ball.physicsBody?.friction = 0
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.restitution = 1
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.contactTestBitMask = (ball.physicsBody?.collisionBitMask)!
        
        addChild(ball)
    }
    
    func makePaddle() {
        paddle.removeFromParent()
        
        paddle = SKSpriteNode(color: .white, size: CGSize(width: frame.width / 4, height: 20))
        paddle.position = CGPoint(x: frame.midX, y: frame.minY + 125)
        paddle.name = "paddle"
        
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.isDynamic = false
        
        addChild(paddle)
    }
    
    func makeBrick(x: Int, y: Int, color: UIColor) {
        let brick = SKSpriteNode(color: color, size: CGSize(width: 50, height: 20))
        brick.position = CGPoint(x: x, y: y)
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
        brick.physicsBody?.isDynamic = false
        addChild(brick)
        bricks.append(brick)
    }
    
    func makeBricks() {
        for brick in bricks {
            brick.removeFromParent()
        }
        
        bricks.removeAll()
        removedBricks = 0
        
        let count = Int(frame.width) / 55
        let xOffset = (Int(frame.width) - (count * 55)) / 2 + Int(frame.minX) + 25
        let colors: [UIColor] = [.blue, .orange, .green]
        
        for r in 0..<3 {
            let y = Int(frame.maxY) - 65 - (r * 25)
            for i in 0..<count {
                let x = i * 55 + xOffset
                makeBrick(x: x, y: y, color: colors[r])
            }
        }
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
    
    override func update(_ currentTime: TimeInterval) {
        if abs(ball.physicsBody!.velocity.dx) < 100 {
            ball.physicsBody?.applyImpulse(CGVector(dx: Int.random(in: -3...3), dy: 0))
        }
        
        if abs(ball.physicsBody!.velocity.dy) < 100 {
            ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: Int.random(in: -3...3)))
        }
    }
}
