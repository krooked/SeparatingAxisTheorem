//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func getMinMax(vertices:[CGPoint], axis:CGPoint) -> (minProjection: CGFloat, maxProjection: CGFloat) {
    var minProjection: CGFloat = vertices[0].dotProduct(B: axis);
    var maxProjection: CGFloat = vertices[0].dotProduct(B: axis);
    
    // Only check vertices B and C for rectangles
    for j in 1..<vertices.count {
        
        let projection:CGFloat = vertices[j].dotProduct(B: axis)
        if minProjection > projection {
            minProjection = projection
        }
        if (projection > maxProjection) {
            maxProjection = projection
        }
    }
    return (minProjection, maxProjection)
}

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalVector() -> CGPoint {
        return CGPoint(x: 1, y: -x)
    }
    
    func normalRight() -> CGPoint {
        return CGPoint(x: -1 * self.y, y: self.x)
    }
    
    func normal() -> CGPoint {
        return CGPoint(x: self.y, y: -1 * self.x)
    }
    
    func unitVector() -> CGPoint {
        return CGPoint(x: x / length(), y: y / length())
    }
    
    func dotProduct(B: CGPoint) -> CGFloat {
        return x * B.x + y * B.y
    }
    
    func rotate(radians: CGFloat) -> CGPoint {
        let x = self.x * cos(radians) - self.y * sin(radians)
        let y = self.x * sin(radians) + self.y * cos(radians)
        return CGPoint(x: x, y: y)
    }
}

extension CGFloat {
    var radians: CGFloat {
        let π = CGFloat.pi
        return π * self / 180.0
    }
    
    var degrees: CGFloat {
        let π = CGFloat.pi
        return self * 180.0 / π
    }
    
    
    // Assuming that self is rotation in radians
    var unitDirectionVector: CGPoint {
        return CGPoint(x: cos(self), y: sin(self))
    }
}


class Rectangle: SKSpriteNode {
    // Vertices
    // 3------2
    // |      |
    // 0------1
    var vertices = [CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero]
    
    // This needs optimization
    var normals: [CGPoint] {
        return [CGPoint(x: vertices[1].x - vertices[0].x, y: vertices[1].y - vertices[0].y).normal(),
                CGPoint(x: vertices[2].x - vertices[1].x, y: vertices[2].y - vertices[1].y).normal(),
                CGPoint(x: vertices[3].x - vertices[2].x, y: vertices[3].y - vertices[2].y).normal(),
                CGPoint(x: vertices[0].x - vertices[3].x, y: vertices[0].y - vertices[3].y).normal()]
    }
    
    override var zRotation: CGFloat {
        didSet {
            super.zRotation = zRotation
            zRotationDidChange(fromOldValue: oldValue)
        }
    }
    
    override var position: CGPoint {
        didSet {
            super.position = position
            positionDidChange(fromOldValue: oldValue)
        }
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        calculateVertices()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func calculateVertices() {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        
        vertices[0] = CGPoint(x: position.x - halfWidth, y: position.y - halfHeight)
        vertices[1] = CGPoint(x: position.x + halfWidth, y: vertices[0].y)
        vertices[2] = CGPoint(x: vertices[1].x, y: position.y + halfHeight)
        vertices[3] = CGPoint(x: vertices[0].x, y: vertices[2].y)
    }
    
    private func zRotationDidChange(fromOldValue: CGFloat) {
        let diff = zRotation - fromOldValue
        vertices[0] = vertices[0].rotate(radians: diff)
        vertices[1] = vertices[1].rotate(radians: diff)
        vertices[2] = vertices[2].rotate(radians: diff)
        vertices[3] = vertices[3].rotate(radians: diff)
    }
    
    private func positionDidChange(fromOldValue: CGPoint) {
        let diff = position - fromOldValue
        vertices[0] = vertices[0] + diff
        vertices[1] = vertices[1] + diff
        vertices[2] = vertices[2] + diff
        vertices[3] = vertices[3] + diff
    }
}


class GameScene: SKScene {
    private var box1 : Rectangle!
    private var box2 : Rectangle!
    private var selectedNode: SKNode?
    
    override func didMove(to view: SKView) {
        
        box1 =  Rectangle(color: UIColor.green, size: CGSize(width: 100, height: 100))
        box1.zRotation = CGFloat(45).radians
        box1.position = CGPoint(x: 200, y: 200)
        
        box2 = Rectangle(color: UIColor.green, size: CGSize(width: 100, height: 100))
        box2.zRotation = CGFloat(0).radians
        box2.position = CGPoint(x: 300, y: 200)
        
        addChild(box1)
        addChild(box2)
        drawVertices()
    }
    
    // Visualize vertices for debugging.
    private func drawVertices() {
        children.forEach { node in
            if (type(of: node) is Rectangle.Type) == false {
                node.removeFromParent()
            }
        }
        
        children.forEach { node in
            if let rectangle = node as? Rectangle {
                let vertices = rectangle.vertices
                vertices.forEach({ position in
                    let shapeA = SKShapeNode(circleOfRadius: 5)
                    shapeA.position = position
                    addChild(shapeA)
                })
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            let positionInScene = touch.location(in: self)
            
            selectNodeForTouch(touchLocation: positionInScene)
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        drawVertices()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let positionInScene = touch.location(in: self)
            let previousPosition = touch.previousLocation(in: self)
            let translation = CGPoint(x: positionInScene.x - previousPosition.x, y: positionInScene.y - previousPosition.y)
            
            if let selectedNode = selectedNode {
                let position = selectedNode.position
                selectedNode.position = CGPoint(x: position.x + translation.x, y: position.y + translation.y)
                
            }
        }
        
    }
    
    func selectNodeForTouch(touchLocation : CGPoint) {
        // 1
        let touchedNode = self.atPoint(touchLocation)
        self.selectedNode = touchedNode
    }
    
    override func update(_ currentTime: TimeInterval) {
        let box1Normals = box1.normals
        let box2Normals = box2.normals
        
        let box1Vertices = box1.vertices
        let box2Vertices = box2.vertices
        
        let p1 = getMinMax(vertices: box1Vertices, axis: box1Normals[1])
        let p2 = getMinMax(vertices: box2Vertices, axis: box1Normals[1])
        let q1 = getMinMax(vertices: box1Vertices, axis: box1Normals[0])
        let q2 = getMinMax(vertices: box2Vertices, axis: box1Normals[0])

        let r1 = getMinMax(vertices: box1Vertices, axis: box2Normals[1])
        let r2 = getMinMax(vertices: box2Vertices, axis: box2Normals[1])
        let s1 = getMinMax(vertices: box1Vertices, axis: box2Normals[0])
        let s2 = getMinMax(vertices: box2Vertices, axis: box2Normals[0])
        
        let separateP = p1.maxProjection < p2.minProjection || p2.maxProjection < p1.minProjection
        let separateQ = q1.maxProjection < q2.minProjection || q2.maxProjection < q1.minProjection
        let separateR = r1.maxProjection < r2.minProjection || r2.maxProjection < r1.minProjection
        let separateS = s1.maxProjection < s2.minProjection || s2.maxProjection < s1.minProjection
        
        let isSeparated = separateP || separateQ || separateR || separateS
        if isSeparated {
            print("Separated boxes")
        }else {
            print("Collided boxes.")
        }
    }
    
}

// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))
if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill
    
    // Present the scene
    sceneView.presentScene(scene)
}

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView


