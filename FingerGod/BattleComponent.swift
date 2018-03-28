//
//  Battle.swift
//  FingerGod
//
//  Created by Aaron F on 2018-03-27.
//  Copyright © 2018 Ramen Interactive. All rights reserved.
//

import Foundation
public class BattleComponent : Component {
    static let moveTime = Float(0.25)
    private var lastMoveTime = Float(0)
    
    public required init(gameObject:GameObject) {
        super.init(gameObject: gameObject)
    }
    
    var groupA : UnitGroup?
    var groupB : UnitGroup?
    var active = false
    
    public func start() {
        active = true
    }
    
    open override func update(delta: Float) {
        if (active) {
            lastMoveTime += delta;
            if (lastMoveTime > BattleComponent.moveTime) {
                lastMoveTime -= BattleComponent.moveTime
                
                for u in (groupA?.peopleArray)! {
                    let unit = u as! SingleUnit
                    unit.attack(targetGroup: groupB!)
                }
                
                for u in (groupB?.peopleArray)! {
                    let unit = u as! SingleUnit
                    unit.attack(targetGroup: groupA!)
                }
                
                _ = groupA?.removeUnitNum()
                _ = groupB?.removeUnitNum()
                
                if groupA?.peopleArray.count == 0 && groupB?.peopleArray.count == 0 {
                    // tie
                    active = false
                    var params = [String : Any]()
                    params["result"] = "tie"
                    params["groupA"] = groupA!
                    params["groupB"] = groupB!
                    _ = EventDispatcher.publish("BattleEnd", params)
                }
                else if groupA?.peopleArray.count == 0 {
                    // group B win
                    active = false
                    var params = [String : Any]()
                    params["result"] = "bwin"
                    params["groupA"] = groupA!
                    params["groupB"] = groupB!
                    _ = EventDispatcher.publish("BattleEnd", params)
                }
                else if groupB?.peopleArray.count == 0 {
                    // group A win
                    active = false
                    var params = [String : Any]()
                    params["result"] = "awin"
                    params["groupA"] = groupA!
                    params["groupB"] = groupB!
                    _ = EventDispatcher.publish("BattleEnd", params)
                }
            }
        }
    }
}