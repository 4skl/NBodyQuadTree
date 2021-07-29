//
//  GameScene.swift
//  QuadTreePlay Shared
//
//  Created by Medi Olivier on 26/07/2021.
//

import SpriteKit

class GameScene: SKScene {
    fileprivate var spinnyNode : SKShapeNode?
    fileprivate var points = Array<MassCircle>()
    fileprivate var quadTreeShape = SKShapeNode()
    fileprivate var ppQuad: QuadTreeG?
    fileprivate var labelInfo = SKLabelNode()
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        return scene
    }
    
    func setUpScene() {
        
        //add quad tree to scene
        addChild(quadTreeShape)
        labelInfo.position = CGPoint(x: size.width/3, y: size.height/3)
        addChild(labelInfo)
        for _ in 0...200 {
            addPoint(at: CGPoint(x: CGFloat.random(in: -size.width/2...size.width/2), y: CGFloat.random(in: -size.height/2...size.height/2)), elemSize: CGFloat.random(in: 1...5))
        }
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 4.0
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
            
            #if os(watchOS)
                // For watch we just periodically create one of these and let it spin
                // For other platforms we let user touch/mouse events create these
                spinnyNode.position = CGPoint(x: 0.0, y: 0.0)
                spinnyNode.strokeColor = SKColor.red
                self.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 2.0),
                                                                   SKAction.run({
                                                                       let n = spinnyNode.copy() as! SKShapeNode
                                                                       self.addChild(n)
                                                                   })])))
            #endif
        }
    }
    
    #if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif
    var simSpeed: CGFloat = 0.01
    func setSimSpeed(_ simSpeed: CGFloat) {
        self.simSpeed = simSpeed
        labelInfo.text = "Speed : \(simSpeed)"
        addChild(labelInfo)
        labelInfo.run(SKAction.sequence([SKAction.wait(forDuration: 3),
                                         SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
    }
    
    var elemSize: CGFloat = 1
    func setElemSize(_ elemSize: CGFloat) {
        self.elemSize = elemSize
        labelInfo.text = "Size : \(elemSize)"
        addChild(labelInfo)
        labelInfo.run(SKAction.sequence([SKAction.wait(forDuration: 3),
                                         SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
    }
    
    
    func makeSpinny(at pos: CGPoint, color: SKColor) {
        if let spinny = self.spinnyNode?.copy() as! SKShapeNode? {
            spinny.position = pos
            spinny.strokeColor = color
            self.addChild(spinny)
        }
    }
    
    /*func actualizeQuadTree() {
        //show quad tree
        let pts = points.map({(p: SKShapeNode) -> CGPoint in p.position})
        quadTreeShape.removeFromParent()
        quadTreeShape = QuadTree(CGRect.init(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height), pts).getSKShape()
        addChild(quadTreeShape)
    }*/
    var add_quadTree = false
    var add_count = false
    var add_countIt = false
    func actualizeQuadTree() {
        let screen = CGRect.init(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height)
        quadTreeShape.removeFromParent()
        ppQuad = QuadTreeG(screen, points)
        if add_quadTree {
            quadTreeShape = ppQuad!.getSKShape(countLabel: add_count, labelIt: add_countIt)
            addChild(quadTreeShape)
        }
    }
    
    func addPoint(at pos: CGPoint, elemSize: CGFloat? = nil) {
        var w = elemSize
        if w == nil {
            w = self.elemSize
        }
        let pt = MassCircle(pos, w!)
        /*pt.position = pos
        pt.fillColor = SKColor.init(red: CGFloat.random(in: 0.0..<1.0), green: CGFloat.random(in: 0.0..<1.0), blue: CGFloat.random(in: 0.0..<1.0), alpha: 1.0)*/
        points.append(pt)
        addChild(pt)
        updated = false
    }
    
    var updated = false
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        /*if !updated {
            actualizeQuadTree()
            updated = true
        }*/
        actualizeQuadTree()
        if ppQuad != nil {
            ppQuad!.computeForce(simSpeed)
        }
        
        //correct pos
        
        for p in points {
            while(p.position.x > size.width/2) { p.position.x -= size.width }
            while(p.position.y > size.height/2) { p.position.y -= size.height }
            while(p.position.x < -size.width/2) { p.position.x += size.width }
            while(p.position.y < -size.height/2) { p.position.y += size.height }
        }
        
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.green)
            self.addPoint(at: t.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.blue)
            self.addPoint(at: event.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {
    override func mouseDown(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.green)
        self.addPoint(at: event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.blue)
        //self.addPoint(at: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.red)
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 0x35 {//esc good method ? code from : https://gist.github.com/swillits/df648e87016772c7f7e5dbed2b345066
            self.points.forEach({(v: SKShapeNode) -> Void in v.removeFromParent()})
            self.points.removeAll()
        }
        
        if event.keyCode == 0x30 {
            if add_quadTree {
                if add_count {
                    add_count = false
                    add_quadTree = false
                }else{
                    add_count = true
                }
            }else{
                add_quadTree = true
            }
            
        }
        
        if event.keyCode == 0x25 {
            add_countIt = !add_countIt
        }
        
        if event.keyCode == 0x7E {
            setSimSpeed(simSpeed*1.5)
        }
        
        if event.keyCode == 0x7D {
            setSimSpeed(simSpeed/1.5)
        }
        
        if event.keyCode == 0x7C {
            setElemSize(elemSize*1.5)
        }
        
        if event.keyCode == 0x7B {
            setElemSize(elemSize/1.5)
        }
    }

}
#endif


/*
//todo move to another file
class QuadTree{
    fileprivate var points = Array<CGPoint>()
    fileprivate var leafs = Array<QuadTree>()
    fileprivate var quad = CGRect()
    
    init(_ quad: CGRect, _ points: Array<CGPoint>) {
        self.points = points
        self.quad = quad
        if(distPts(points)>CGFloat(points.count)*(quad.height+quad.width)) { //can be useful for clustering
            self.leafs = makeChilds()
        }
    }
    
    func combination<T>(_ elems: Array<T>) -> Array<Array<T>>{
        var comb = Array<Array<T>>()
        if elems.count > 1 {
            for i in 0...(elems.count-2) {
                for j in (i+1)...(elems.count-1) {
                    comb.append([elems[i], elems[j]])
                }
            }
        }
        return comb
    }
    
    func distPts(_ points: Array<CGPoint>) -> CGFloat{
        var dist = CGFloat()
        for pts in combination(points) {
            dist += sqrt(pow(pts[0].x-pts[1].x, 2) + pow(pts[0].x-pts[1].x, 2))
        }
        return dist
    }
    
    func pointInRect(_ rect: CGRect, _ point: CGPoint) -> Bool{
        return (rect.minX < point.x && point.x < rect.maxX) && (rect.minY < point.y && point.y < rect.maxY)
    }
    
    fileprivate func cutRect(_ rect: CGRect) -> [CGRect]{
        let q1 = CGRect(x: rect.minX, y: rect.minY, width: rect.width/2, height: rect.height/2)
        let q2 = CGRect(x: rect.midX, y: rect.minY, width: rect.width/2, height: rect.height/2)
        let q3 = CGRect(x: rect.minX, y: rect.midY, width: rect.width/2, height: rect.height/2)
        let q4 = CGRect(x: rect.midX, y: rect.midY, width: rect.width/2, height: rect.height/2)
        return [q1,q2,q3,q4]
    }
    
    fileprivate func makeChilds() -> Array<QuadTree>{
        //cut quad in 4 equals part, then init childs with related points
        let rects = cutRect(quad)
        var ptsPart = Array.init(repeating: Array<CGPoint>(), count: rects.count) // good method (risk of same array ref)
        for p in points {
            for i in 0..<rects.count {
                if pointInRect(rects[i], p) {
                    ptsPart[i].append(p)
                }
            }
        }
        var childs = Array<QuadTree>()
        for i in 0..<rects.count {
            childs.append(QuadTree(rects[i], ptsPart[i]))
        }
        return childs
    }
    
    public func isLeaf() -> Bool{
        return leafs.count == 0
    }
    
    public func getSKShape() -> SKShapeNode {
        let this = SKShapeNode(rect: quad)
        this.lineWidth = 3
        this.strokeColor = SKColor.red//SKColor.init(red: CGFloat.random(in: 0.0..<1.0), green: CGFloat.random(in: 0.0..<1.0), blue: CGFloat.random(in: 0.0..<1.0), alpha: 1.0)
        for leaf in leafs {
            this.addChild(leaf.getSKShape())
        }
        return this
    }
    
}

class CircleTree{
    fileprivate var points = Array<CGPoint>()
    fileprivate var leafs = Array<CircleTree>()
    fileprivate var center = CGPoint()
    fileprivate var radius = CGFloat()
    
    /*let hashCGPoint = {(p: CGPoint) -> CGFloat in return (p.x+p.y*CGFloat.greatestFiniteMagnitude/2.0)} // loose precision to have enough space
    let unhashCGPoint = {(p: CGFloat) -> CGPoint in return CGPoint(x: p%(CGFloat.greatestFiniteMagnitude/2.0), y: p/(CGFloat.greatestFiniteMagnitude/2.0))} // loose precision to have enough space*/
    
    init(_ center: CGPoint, _ radius: CGFloat, _ points: Array<CGPoint>) {
        self.points = points
        self.center = center
        self.radius = radius
        if(points.count > 3) {//distPts(points)>CGFloat(points.count)*(quad.height+quad.width)) { //can be useful for clustering
            self.leafs = makeChilds()
        }
    }
    
    func combination<T>(_ elems: Array<T>) -> Array<Array<T>>{
        var comb = Array<Array<T>>()
        if elems.count > 1 {
            for i in 0...(elems.count-2) {
                for j in (i+1)...(elems.count-1) {
                    comb.append([elems[i], elems[j]])
                }
            }
        }
        return comb
    }
    
    func distPts(_ points: Array<CGPoint>) -> CGFloat{
        var dist = CGFloat()
        for pts in combination(points) {
            dist += sqrt(pow(pts[0].x-pts[1].x, 2) + pow(pts[0].x-pts[1].x, 2))
        }
        return dist
    }
    
    func dist(_ p1: CGPoint,_ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p1.x-p2.x, 2) + pow(p1.y-p2.y, 2))
    }
    
    func pointInCircle(_ center: CGPoint, _ radius: CGFloat, _ point: CGPoint) -> Bool{
        return dist(center, point) < radius
    }
    
    fileprivate func cutCircle(_ center: CGPoint, _ radius: CGFloat) -> [CGFloat: CGFloat]{ // how to be sure that all points are in circles and circles are efficient
        let q1 = CGRect(x: rect.minX, y: rect.minY, width: rect.width/2, height: rect.height/2)
        let q2 = CGRect(x: rect.midX, y: rect.minY, width: rect.width/2, height: rect.height/2)
        let q3 = CGRect(x: rect.minX, y: rect.midY, width: rect.width/2, height: rect.height/2)
        let q4 = CGRect(x: rect.midX, y: rect.midY, width: rect.width/2, height: rect.height/2)
        return [q1,q2,q3,q4]//todo
    }
    
    fileprivate func makeChilds() -> Array<CircleTree>{
        //cut quad in 4 equals part, then init childs with related points
        let circles = cutCircle(center, radius)
        var ptsPart = Array.init(repeating: Array<CGPoint>(), count: circles.count) // good method (risk of same array ref)
        for p in points {
            for i in 0..<circles.count {
                if pointInCircle(circles[i].key, circles[i].value, p) {
                    ptsPart[i].append(p)
                }
            }
        }
        var childs = Array<CircleTree>()
        for i in 0..<circles.count {
            childs.append(CircleTree(rects[i], ptsPart[i]))
        }
        return childs
    }
    
    public func isLeaf() -> Bool{
        return leafs.count == 0
    }
    
    public func getSKShape() -> SKShapeNode {
        let this = SKShapeNode(circleOfRadius: radius)
        this.lineWidth = 3
        this.strokeColor = SKColor.red//SKColor.init(red: CGFloat.random(in: 0.0..<1.0), green: CGFloat.random(in: 0.0..<1.0), blue: CGFloat.random(in: 0.0..<1.0), alpha: 1.0)
        for leaf in leafs {
            this.addChild(leaf.getSKShape())
        }
        return this
    }
    
}
*/
