//
//  PPQuad.swift
//  QuadTreePlay
//
//  Created by Medi Olivier on 27/07/2021.
//

import Foundation

import SpriteKit


class MassCircle: SKShapeNode {
    //fileprivate var center = CGPoint()
    fileprivate var radius = CGFloat()
    fileprivate var mass = CGFloat()
    fileprivate var speedVector = CGVector()
    fileprivate var force = CGVector() //F = ma => v = a*t
    
    override init() {
        super.init()
        fillColor = SKColor.init(red: CGFloat.random(in: 0.0..<1.0), green: CGFloat.random(in: 0.0..<1.0), blue: CGFloat.random(in: 0.0..<1.0), alpha: 0.5)
    }
    
    convenience init(_ center: CGPoint, _ radius: CGFloat) {
        self.init()
        self.init(circleOfRadius: radius)
        self.position = center
        self.radius = radius
        self.mass = CGFloat.pi*pow(radius, 2)
    }
    
    convenience init(_ center: CGPoint, mass: CGFloat) {
        self.init()
        let r = sqrt(mass/CGFloat.pi)
        self.init(circleOfRadius: r)
        self.position = center
        self.mass = mass
        self.radius = r
    }
    
    convenience init(_ center: CGPoint, _ radius: CGFloat, _ mass: CGFloat) {
        self.init()
        self.init(circleOfRadius: radius)
        self.position = center
        self.radius = radius
        self.mass = mass
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateMove(_ dt: CGFloat = 0.01) {
        let a = CGVector(dx: force.dx/mass, dy: force.dy/mass)
        speedVector.dx += a.dx*dt
        speedVector.dy += a.dy*dt
        position.x += speedVector.dx*dt
        position.y += speedVector.dy*dt
        speedVector.dx *= 0.9 //!
        speedVector.dy *= 0.9
    }
    
}

class QuadTreeG{
    fileprivate var points = Array<MassCircle>()
    fileprivate var leafs = Array<QuadTreeG>()
    fileprivate var quad = CGRect()
    
    fileprivate var centerOfMass = CGPoint()
    fileprivate var mass = CGFloat()
    
    init(_ quad: CGRect, _ points: Array<MassCircle>) {
        self.points = points
        self.quad = quad
        
        for p in points {
            centerOfMass.x += p.position.x*p.mass
            centerOfMass.y += p.position.y*p.mass
            mass += p.mass
        }
        centerOfMass.x /= mass //?
        centerOfMass.y /= mass //?
        
        if(points.count > 50) { // max count of object by quad
            self.leafs = makeChilds()
        }
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
    
    fileprivate func makeChilds() -> Array<QuadTreeG>{
        //cut quad in 4 equals part, then init childs with related points
        let rects = cutRect(quad)
        var ptsPart = Array.init(repeating: Array<MassCircle>(), count: rects.count) // good method (risk of same array ref)
        for p in points {
            for i in 0..<rects.count {
                if pointInRect(rects[i], p.position) {
                    ptsPart[i].append(p)
                }
            }
        }
        var childs = Array<QuadTreeG>()
        for i in 0..<rects.count {
            childs.append(QuadTreeG(rects[i], ptsPart[i]))
        }
        return childs
    }
    
    func isLeaf() -> Bool{
        return leafs.count == 0 //?
    }
    
    func getSKShape(countLabel: Bool = false, labelIt: Bool = false) -> SKShapeNode {
        let this = SKShapeNode(rect: quad)
        this.lineWidth = 3
        this.strokeColor = SKColor.red//SKColor.init(red: CGFloat.random(in: 0.0..<1.0), green: CGFloat.random(in: 0.0..<1.0), blue: CGFloat.random(in: 0.0..<1.0), alpha: 1.0)
        for leaf in leafs {
            this.addChild(leaf.getSKShape(countLabel: labelIt, labelIt: labelIt)) // to repeat label if it
        }
        if countLabel {
            let nodesCountLabel = SKLabelNode(text: "Nodes : \(points.count)")
            nodesCountLabel.position = CGPoint(x: quad.midX, y: quad.midY)
            this.addChild(nodesCountLabel)
        }
        let pt = SKShapeNode(circleOfRadius: sqrt(mass/CGFloat.pi)/10)
        pt.position = centerOfMass
        pt.strokeColor = NSColor(white: 0, alpha: 1)
        pt.fillColor = NSColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        this.addChild(pt)
        return this
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
    
    let GRAVITATIONAL_CONSTANT: CGFloat = 0.001
    func computeForce(_ dt: CGFloat = 0.01, upperLayerForce: CGVector = CGVector()){ //calculate force between childs then ask them to do the same for theirs childs
        if isLeaf() {
            for comb in combination(points) { //PP method on points in last level leaf
                let p1 = comb[0]
                let p2 = comb[1]
                let dx = p1.position.x-p2.position.x
                let dy = p1.position.y-p2.position.y
                let d_food = sqrt( pow(dx, 2) + pow(dy, 2) )
                
                if d_food > p1.radius+p2.radius {
                    //print("yay")
                    let force = -p1.mass*p2.mass*GRAVITATIONAL_CONSTANT/pow(d_food, 2)
                    //print("Force : \(force) | \(mass_1) * \(mass_2) / \(d_food)")
                    let fx = dx/d_food*force+upperLayerForce.dx // correct following position of the point,... in fect this force should be modified for each point (2 set targetting theirs center of mass should recalculate force direction for each points)
                    let fy = dy/d_food*force+upperLayerForce.dy
                    p1.force = CGVector(dx: fx+p1.force.dx, dy: fy+p1.force.dy)
                    p2.force = CGVector(dx: -fx+p2.force.dx, dy: -fy+p2.force.dy)
                }else{
                    if d_food != 0 {
                        let force: CGFloat = (p1.radius + p2.radius)*GRAVITATIONAL_CONSTANT
                        let fx = dx/d_food*force+upperLayerForce.dx // correct following position of the point,... in fect this force should be modified for each point (2 set targetting theirs center of mass should recalculate force direction for each points)
                        let fy = dy/d_food*force+upperLayerForce.dy
                        p1.force = CGVector(dx: fx+p1.force.dx, dy: fy+p1.force.dy)
                        p2.force = CGVector(dx: -fx+p2.force.dx, dy: -fy+p2.force.dy)
                    }else{
                        p1.speedVector = CGVector()
                        p2.speedVector = CGVector()
                    }
                }
            }
            for point in points {
                point.updateMove(dt)
            }
        }else{
            for comb in combination(leafs) { //PP method on clusters, to improve
                let q1 = comb[0]
                let q2 = comb[1]
                let dx = q1.centerOfMass.x-q2.centerOfMass.x
                let dy = q1.centerOfMass.y-q2.centerOfMass.y
                let d_food = sqrt( pow(dx, 2) + pow(dy, 2) )
                
                if d_food > 0.001{
                    //print("yay")
                    let force = -q1.mass*q2.mass*GRAVITATIONAL_CONSTANT/pow(d_food, 2)
                    //print("Force : \(force) | \(mass_1) * \(mass_2) / \(d_food)")
                    let fx = dx/d_food*force+upperLayerForce.dx // correct following position of the point,... in fect this force should be modified for each point (2 set targetting theirs center of mass should recalculate force direction for each points)
                    let fy = dy/d_food*force+upperLayerForce.dy
                    q1.computeForce(dt, upperLayerForce: CGVector(dx: fx, dy: fy))
                    q2.computeForce(dt, upperLayerForce: CGVector(dx: -fx, dy: -fy))
                }
            }
        }
        
    }
    
}

//for force use a method like do apply attraction on tail leafs (force : comb leafs)
//for parent nodes : apply force to related childs excluding previously calculated (force : comb leafs(symmetric difference))..
//^ nearly sure that this is o(n^2/2)
