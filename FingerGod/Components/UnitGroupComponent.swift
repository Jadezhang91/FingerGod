//
//  UnitGroupComponent.swift
//  FingerGod
//
//  Created by Aaron F on 2018-03-27.
//  Copyright © 2018 Ramen Interactive. All rights reserved.
//

import Foundation
import GLKit

public class UnitGroupComponent : Component {
    // Axial coordinate position
    public var position = [0, 0]
    private var model : Model?
    private var unitModels = [ModelInstance]()
    
    // Positions for display purposes
    private var startPosition = [0, 0]
    private var endPosition = [0, 0]
    
    private var modelInst : ModelInstance?
    private var squareSize = 0
    var unitGroup = UnitGroup.initUnitGroupWith(peopleNum:10, followerNum: 0, demiGodNum: 0)
    
    private var initShape = GLKMatrix4Scale(GLKMatrix4Identity, 0.5, 0.5, 0.5)
    public var alignment = Alignment.NEUTRAL
    
    public var movePath : [Point2D] = []
    private var stepProgress : Float = 0.0
    public var moveSpeed : Float = 1.0 // Tiles per second
    
    public var target : PathFindingTarget?
    
    // Are we stopped by something?
    public var halted = false
    
    public override func create() {
        print("Creating Unit Group")
        do {
            model = try ModelReader.read(objPath: "CubeModel")
            updateModels()
        } catch {
            print("There was a problem: \(error)")
        }
    }
    
    public override func update(delta: Float) {
        if (stepProgress <= 0.0 && movePath.count > 0 && !halted) {
            // Remove any extraneous movement paths
            while (movePath.count > 0 && movePath[0].x == position[0] && movePath[0].y == position[1]) {
                movePath.removeFirst(1)
            }
            
            if (movePath.count > 0) {
                // If we still have move paths after handling redundancies, start moving
                if target != nil && target!.changedLocation() {
                    self.movePath = target!.getPathToTarget(from: Point2D(position))
                }
                endPosition[0] = movePath[0].x
                endPosition[1] = movePath[0].y
            }
        }
        if (endPosition[0] != startPosition[0] || endPosition[1] != startPosition[1]) {
            stepProgress += moveSpeed * delta
            if (stepProgress >= 0.5 && (position[0] != endPosition[0] || position[1] != endPosition[1])) {
                position[0] = endPosition[0]
                position[1] = endPosition[1]
                EventDispatcher.publish("UnitMoved", ("newPos", Point2D(position)), ("oldPos", Point2D(startPosition)), ("unit", self))
                
            }
            if (stepProgress >= 1.0) {
                // Reached our destination
                startPosition[0] = endPosition[0]
                startPosition[1] = endPosition[1]
                
                stepProgress = 0.0
                
                if (target != nil && target!.fulfilled(by: self)) {
                    // We did what we set out to do, woo!
                    target = nil
                }
            }
            updateRenderPos()
        }
    }
    
    public override func delete() {
        Renderer.removeInstance(inst: modelInst!)
    }

    public func setPosition(_ x : Int, _ y : Int) {
        let oldPos = position
        position[0] = x
        position[1] = y
        startPosition[0] = x
        startPosition[1] = y
        endPosition[0] = x
        endPosition[1] = y
        EventDispatcher.publish("UnitMoved", ("newPos", Point2D(position)), ("oldPos", Point2D(oldPos)), ("unit", self))
        
        updateRenderPos()
    }
    
    public func move(_ x : Int, _ y : Int) {
        movePath.append(Point2D(x, y))
        updateRenderPos()
    }
    
    public func offset(_ x : Float, _ y : Float, _ z : Float) {
        initShape = GLKMatrix4Translate(initShape, x, y, z)
        updateRenderPos()
    }
    
    private func updateRenderPos() {
        let axs = axialToWorld(startPosition[0], startPosition[1])
        let axe = axialToWorld(endPosition[0], endPosition[1])
        let ax = (x: axs.x  * (1 - stepProgress) + axe.x * stepProgress, y: axs.y  * (1 - stepProgress) + axe.y * stepProgress)
        modelInst?.transform = GLKMatrix4Translate(GLKMatrix4Identity, ax.x, 0.75, ax.y)
        modelInst?.transform = GLKMatrix4Multiply((modelInst?.transform)!, initShape)
    }
    
    public func setAlignment(_ alignment: Alignment) {
        self.alignment = alignment;
        switch(alignment) {
        case Alignment.NEUTRAL:
            modelInst?.color = [1.0, 1.0, 1.0, 1.0]
            break
        case Alignment.ALLIED:
            modelInst?.color = [0.0, 0.2, 1.0, 1.0]
            break
        case Alignment.ENEMY:
            modelInst?.color = [1.0, 0.2, 0.0, 1.0]
            break
        }
    }
    
    private func axialToWorld(_ q: Int, _ r: Int) -> (x: Float, y: Float) {
        let x = 3.0 / 2.0 * Float(q) // x value
        let z = Float(3).squareRoot() * (Float(r) + Float(q) / 2) // z value
        
        return (x,z)
    }
    
    private func updateModels() {
        modelInst = ModelInstance(model: model!)
        squareSize = Int(Float(unitGroup.peopleArray.count).squareRoot()) + 1
        
        for i in 0..<unitGroup.peopleArray.count {
            modelInst?.transform = GLKMatrix4Translate(initShape, 0, 0.75, 0);
            modelInst?.transform = GLKMatrix4Multiply((modelInst?.transform)!, initShape)
            modelInst?.color = [1.0, 1.0, 1.0, 1.0]
            Renderer.addInstance(inst: modelInst!)
        }
        
        if (unitGroup.peopleArray.count < unitModels.count) {
            for i in stride(from: unitModels.count, to: (unitGroup.peopleArray.count - 1), by: -1) {
                Renderer.removeInstance(inst: unitModels[i])
                unitModels.popLast()
            }
        }
    }

    public func setTarget(_ target : PathFindingTarget) {
        self.target = target
        self.movePath = target.getPathToTarget(from: Point2D(position))
    }
}
