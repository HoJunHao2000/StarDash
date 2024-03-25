//
//  AttackSystem.swift
//  star-dash
//
//  Created by Ho Jun Hao on 25/3/24.
//

import Foundation

class AttackSystem: System {
    var isActive: Bool
    var dispatcher: EventModifiable?
    var entityManager: EntityManager
    var eventHandlers: [ObjectIdentifier: (Event) -> Void] = [:]

    init(_ entityManager: EntityManager, dispatcher: EventModifiable? = nil) {
        self.isActive = true
        self.entityManager = entityManager
        self.dispatcher = dispatcher
        setUpEventHandlers()
    }

    func setUpEventHandlers() {
        eventHandlers[ObjectIdentifier(MonsterAttackPlayerEvent.self)] = { event in
            if let monsterAttackPlayerEvent = event as? MonsterAttackPlayerEvent {
                self.handleMonsterAttackPlayerEvent(event: monsterAttackPlayerEvent)
            }
        }
        eventHandlers[ObjectIdentifier(PlayerAttackMonsterEvent.self)] = { event in
            if let playerAttackMonsterEvent = event as? PlayerAttackMonsterEvent {
                self.handlePlayerAttackMonsterEvent(event: playerAttackMonsterEvent)
            }
        }
    }

    private func handleMonsterAttackPlayerEvent(event: MonsterAttackPlayerEvent) {
        guard let healthSystem = dispatcher?.system(ofType: HealthSystem.self),
              let positionSystem = dispatcher?.system(ofType: PositionSystem.self),
              let physicsSystem = dispatcher?.system(ofType: PhysicsSystem.self) else {
            return
        }

        guard let monsterPosition = positionSystem.getPosition(of: event.monsterId),
              let playerPosition = positionSystem.getPosition(of: event.entityId) else {
            return
        }

        healthSystem.applyHealthChange(to: event.entityId, healthChange: GameConstants.HealthChange.attackedByMonster)

        let isMonsterToRight = monsterPosition.x > playerPosition.x
        let impulse = isMonsterToRight
                      ? GameConstants.DamageImpulse.attackedByMonster * -1
                      : GameConstants.DamageImpulse.attackedByMonster

        physicsSystem.applyImpulse(to: event.entityId, impulse: impulse)

        if !healthSystem.hasHealth(for: event.entityId) {
            dispatcher?.add(event: PlayerDeathEvent(on: event.entityId))
        }
    }

    private func handlePlayerAttackMonsterEvent(event: PlayerAttackMonsterEvent) {
        guard let healthSystem = dispatcher?.system(ofType: HealthSystem.self),
              let physicSystem = dispatcher?.system(ofType: PhysicsSystem.self) else {
            return
        }

        healthSystem.applyHealthChange(to: event.entityId, healthChange: GameConstants.HealthChange.attackedByPlayer)
        physicSystem.applyImpulse(to: event.entityId, impulse: GameConstants.AttackImpulse.attackedByPlayer)

        if !healthSystem.hasHealth(for: event.entityId) {
            dispatcher?.add(event: MonsterDeathEvent(on: event.entityId))
        }
    }
}
