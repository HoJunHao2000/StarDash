//
//  MonsterSystem.swift
//  star-dash
//
//  Created by Ho Jun Hao on 26/3/24.
//

import Foundation
import CoreGraphics

class MonsterSystem: System {
    var isActive: Bool
    var dispatcher: EventModifiable?
    var entityManager: EntityManager
    var eventHandlers: [ObjectIdentifier: (Event) -> Void] = [:]

    init(_ entityManager: EntityManager, dispatcher: EventModifiable? = nil) {
        self.isActive = true
        self.entityManager = entityManager
        self.dispatcher = dispatcher
        setup()
    }

    func update(by deltaTime: TimeInterval) {
        let monsterEntities = entityManager.entities(ofType: Monster.self)

        for monsterEntity in monsterEntities {
            guard let physicsSystem = dispatcher?.system(ofType: PhysicsSystem.self),
                  let deathSystem = dispatcher?.system(ofType: DeathSystem.self),
                  let isDead = deathSystem.isDead(entityId: monsterEntity.id),
                  !isDead,
                  let monsterVelocity = physicsSystem.velocity(of: monsterEntity.id) else {
                continue
            }

            dispatcher?.add(event: MoveEvent(on: monsterEntity.id, toLeft: monsterVelocity.dx < 0))
        }
    }

    func setup() {
        dispatcher?.registerListener(self)

        eventHandlers[ObjectIdentifier(MonsterMovementReversalEvent.self)] = { event in
            if let monsterMovementReversalEvent = event as? MonsterMovementReversalEvent {
                self.handleMonsterMovementReversalEvent(event: monsterMovementReversalEvent)
            }
        }
        eventHandlers[ObjectIdentifier(PlayerMonsterContactEvent.self)] = { event in
            if let playerMonsterContactEvent = event as? PlayerMonsterContactEvent {
                self.handlePlayerMonsterContactEvent(event: playerMonsterContactEvent)
            }
        }
        eventHandlers[ObjectIdentifier(MonsterObstacleContactEvent.self)] = { event in
            if let monsterObstacleContactEvent = event as? MonsterObstacleContactEvent {
                self.handleMonsterObstacleContactEvent(event: monsterObstacleContactEvent)
            }
        }
        eventHandlers[ObjectIdentifier(MonsterWallContactEvent.self)] = { event in
            if let monsterWallContactEvent = event as? MonsterWallContactEvent {
                self.handleMonsterWallContactEvent(event: monsterWallContactEvent)
            }
        }
    }

    private func handleMonsterMovementReversalEvent(event: MonsterMovementReversalEvent) {
        guard let spriteSystem = dispatcher?.system(ofType: SpriteSystem.self),
              let deathSystem = dispatcher?.system(ofType: DeathSystem.self),
              let isMonsterDead = deathSystem.isDead(entityId: event.monsterId),
              !isMonsterDead else {
            return
        }

        dispatcher?.add(event: MoveEvent(on: event.monsterId, toLeft: event.isLeft))
        spriteSystem.startAnimation(of: event.monsterId, named: event.isLeft ? "runLeft" : "run")
    }

    private func handlePlayerMonsterContactEvent(event: PlayerMonsterContactEvent) {
        if let hookOwnerComponent = entityManager
                                    .components(ofType: GrappleHookOwnerComponent.self)
                                    .first(where: { $0.ownerPlayerId == event.playerId }) {
            dispatcher?.add(event: ReleaseGrappleHookEvent(using: hookOwnerComponent.entityId))
        }

        guard let positionSystem = dispatcher?.system(ofType: PositionSystem.self),
              let deathSystem = dispatcher?.system(ofType: DeathSystem.self),
              let physicsSystem = dispatcher?.system(ofType: PhysicsSystem.self) else {
            return
        }

        guard let playerPosition = positionSystem.getPosition(of: event.playerId),
              let monsterPosition = positionSystem.getPosition(of: event.monsterId) else {
            return
        }

        guard let playerSize = physicsSystem.getSize(of: event.playerId),
              let monsterSize = physicsSystem.getSize(of: event.monsterId) else {
            return
        }

        let isPlayerAbove = playerPosition.y - (playerSize.height / 2 - 10)
                            >= monsterPosition.y + (monsterSize.height / 2 - 10)
        let isPlayerWithinMonsterWidth = playerPosition.x < (monsterPosition.x + (monsterSize.width / 2))
                                         || playerPosition.x > (monsterPosition.x - (monsterSize.width / 2))
        let isPlayerAttack = isPlayerAbove && isPlayerWithinMonsterWidth

        let isLeft = monsterPosition.x < playerPosition.x
        dispatcher?.add(event: MonsterMovementReversalEvent(on: event.monsterId, isLeft: isLeft))

        guard let isPlayerDead = deathSystem.isDead(entityId: event.playerId),
              let isMonsterDead = deathSystem.isDead(entityId: event.monsterId),
              !isPlayerDead && !isMonsterDead else {
            return
        }

        if isPlayerAttack {
            dispatcher?.add(event: PlayerAttackMonsterEvent(from: event.playerId, on: event.monsterId))
        } else {
            dispatcher?.add(event: MonsterAttackPlayerEvent(from: event.monsterId, on: event.playerId))
        }
    }

    private func handleMonsterObstacleContactEvent(event: MonsterObstacleContactEvent) {
        guard let positionSystem = dispatcher?.system(ofType: PositionSystem.self),
              let monsterPosition = positionSystem.getPosition(of: event.monsterId),
              abs(monsterPosition.y - event.contactPoint.y) <= 49.99,
              abs(monsterPosition.x - event.contactPoint.x) > 49.99 else {
            return
        }

        let isLeft = monsterPosition.x < event.contactPoint.x

        dispatcher?.add(event: MonsterMovementReversalEvent(on: event.monsterId, isLeft: isLeft))
    }

    private func handleMonsterWallContactEvent(event: MonsterWallContactEvent) {
        guard let positionSystem = dispatcher?.system(ofType: PositionSystem.self),
              let monsterPosition = positionSystem.getPosition(of: event.monsterId) else {
            return
        }

        let isLeft = monsterPosition.x < event.contactPoint.x

        dispatcher?.add(event: MonsterMovementReversalEvent(on: event.monsterId, isLeft: isLeft))
    }
}
