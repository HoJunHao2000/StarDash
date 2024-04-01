import CoreGraphics

class PowerUpFactory {

    static func createPowerUp(triggeredBy playerId: EntityId, type: String, to entityManager: EntityManager) {
        let powerUps: [String: (EntityId, EntityManager) -> Void] = [
            "SpeedBoostPowerUp": createSpeedBoostPowerUp,
            "HomingMisslePowerUp": createHomingMisslePowerUp
        ]

        guard let createMethod = powerUps[type] else {
            return
        }

        createMethod(playerId, entityManager)
    }

    private static func createSpeedBoostPowerUp(triggeredBy playerId: EntityId,
                                                to entityManager: EntityManager) {
        EntityFactory.createAndAddSpeedBoostPowerUp(to: entityManager,
                                                    entityId: playerId,
                                                    duration: 15,
                                                    multiplier: 2.5)
    }

    private static func createHomingMisslePowerUp(triggeredBy playerId: EntityId,
                                                  to entityManager: EntityManager) {
        guard let positionComponent = entityManager.component(ofType: PositionComponent.self, of: playerId) else {
            return
        }

        let misslePosition = CGPoint(x: positionComponent.position.x + 100, y: positionComponent.position.y)

        EntityFactory.createAndAddHomingMissilePowerUp(to: entityManager,
                                                       position: misslePosition,
                                                       impulse: CGVector(dx: 4_000, dy: 0))
    }
}
