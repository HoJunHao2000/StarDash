//
//  Floor+Collidable.swift
//  star-dash
//
//  Created by Ho Jun Hao on 16/3/24.
//

import CoreGraphics

extension Floor: Collidable {
    func collides(with collidable: Collidable, at contactPoint: CGPoint) -> Event? {
        collidable.collideWithFloor(self, at: contactPoint)
    }

    func collideWithPlayer(_ player: Player, at contactPoint: CGPoint) -> Event? {
        CollisionHandler.between(player: player, floor: self, at: contactPoint)
    }

    func collideWithMonster(_ monster: Monster, at contactPoint: CGPoint) -> Event? {
        CollisionHandler.between(monster: monster, floor: self)
    }

    func collideWithCollectible(_ collectible: Collectible, at contactPoint: CGPoint) -> Event? {
        nil
    }

    func collideWithObstacle(_ obstacle: Obstacle, at contactPoint: CGPoint) -> Event? {
        nil
    }

    func collideWithWall(_ wall: Wall, at contactPoint: CGPoint) -> Event? {
        nil
    }

    func collideWithFloor(_ floor: Floor, at contactPoint: CGPoint) -> Event? {
        nil
    }

    func collideWithGrappleHook(_ grappleHook: GrappleHook, at contactPoint: CGPoint) -> Event? {
        CollisionHandler.between(grappleHook: grappleHook, floor: self)
    }

    func collideWithPowerUpBox(_ powerUpBox: PowerUpBox, at contactPoint: CGPoint) -> Event? {
        nil
    }

    func collideWithHomingMissile(_ homingMissile: HomingMissile, at contactPoint: CGPoint) -> Event? {
        CollisionHandler.between(homingMissile: homingMissile, floor: self)
    }
}
