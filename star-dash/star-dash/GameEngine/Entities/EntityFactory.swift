//
//  EntityFactory.swift
//  star-dash
//
//  Created by Ho Jun Hao on 27/3/24.
//

import Foundation

struct EntityFactory {
    static func createAndAddPlayer(to entityManager: EntityManagerInterface,
                                   playerIndex: Int,
                                   position: CGPoint) {
        let playerBuilder = EntityBuilder(entity: Player(id: UUID()), entityManager: entityManager)

        let playerImageSets: [Int: (ImageSet, TextureSet)] = [
            0: (SpriteConstants.playerRedNose, SpriteConstants.playerRedNoseTexture),
            1: (SpriteConstants.playerAdventurer, SpriteConstants.playerAdventurerTexture),
            2: (SpriteConstants.playerJack, SpriteConstants.playerJackTexture),
            3: (SpriteConstants.playerNinja, SpriteConstants.playerNinjaTexture)
        ]

        guard let (imageSet, textureSet) = playerImageSets[playerIndex] else {
            return
        }

        playerBuilder
            .withPlayer(playerIndex: playerIndex)
            .withPosition(at: position)
            .withHealth(health: GameConstants.InitialHealth.player)
            .withSprite(image: imageSet,
                        imageMode: "faceRight",
                        textureSet: textureSet,
                        textureAtlas: nil,
                        size: PhysicsConstants.Dimensions.player)
            .withScore(score: 0)
            .withDeathTimer()
            .withPhysics(rectangleOf: PhysicsConstants.Dimensions.player)
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.player)
                .configureContactTestMask(PhysicsConstants.ContactMask.player)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.player)
                .configureAffectedByGravity(true)
                .configureRestitution(0.0)
                .configureMaxRunSpeed(PhysicsConstants.maxPlayerRunSpeed)
            .addToGame()
    }

    static func createAndAddMonster(to entityManager: EntityManagerInterface,
                                    position: CGPoint,
                                    health: Int,
                                    size: CGSize) {
        let monsterBuilder = EntityBuilder(entity: Monster(id: UUID()), entityManager: entityManager)

        monsterBuilder
            .withPosition(at: position)
            .withHealth(health: health)
            .withSprite(image: SpriteConstants.monster,
                        imageMode: "faceRight",
                        textureSet: SpriteConstants.monsterTexture,
                        textureAtlas: nil,
                        size: size)
            .withDeathTimer()
            .withPhysics(rectangleOf: size)
                .configureVelocity(CGVector(dx: PhysicsConstants.Monster.moveSpeed, dy: 0))
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.monster)
                .configureContactTestMask(PhysicsConstants.ContactMask.monster)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.monster)
                .configureAffectedByGravity(true)
                .configureRestitution(0.0)
                .configureMaxRunSpeed(PhysicsConstants.maxMonsterRunSpeed)
            .addToGame()
    }

    static func createAndAddCollectible(to entityManager: EntityManagerInterface,
                                        position: CGPoint,
                                        points: Int,
                                        radius: CGFloat) {
        let collectibleBuilder = EntityBuilder(entity: Collectible(id: UUID()), entityManager: entityManager)

        collectibleBuilder
            .withPosition(at: position)
            .withSprite(image: SpriteConstants.star,
                        imageMode: "faceRight",
                        textureSet: nil,
                        textureAtlas: nil,
                        radius: radius)
            .withPoint(points: points)
            .withPhysics(circleOf: radius)
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.collectible)
                .configureContactTestMask(PhysicsConstants.ContactMask.collectible)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.collectible)
                .configureAffectedByGravity(false)
                .configureIsDynamic(false)
            .addToGame()
    }

    static func createAndAddObstacle(to entityManager: EntityManagerInterface,
                                     position: CGPoint,
                                     size: CGSize) {
        let obstacleBuilder = EntityBuilder(entity: Obstacle(id: UUID()), entityManager: entityManager)

        obstacleBuilder
            .withPosition(at: position)
            .withSprite(image: SpriteConstants.obstacle,
                        imageMode: "faceRight",
                        textureSet: nil,
                        textureAtlas: nil,
                        size: size)
            .withPhysics(rectangleOf: size)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.obstacle)
                .configureIsDynamic(false)
            .addToGame()
    }

    static func createAndAddMonsterWall(to entityManager: EntityManagerInterface, position: CGPoint, size: CGSize) {
        let wallBuilder = EntityBuilder(entity: Wall(id: UUID()), entityManager: entityManager)

        wallBuilder
            .withPosition(at: position)
            .withPhysics(rectangleOf: size)
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.monsterWall)
                .configureContactTestMask(PhysicsConstants.ContactMask.monsterWall)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.monsterWall)
                .configureIsDynamic(false)
                .configureRestitution(0.0)
            .addToGame()
    }

    static func createAndAddFloor(to entityManager: EntityManagerInterface, position: CGPoint, size: CGSize) {
        let floorBuilder = EntityBuilder(entity: Floor(id: UUID()), entityManager: entityManager)

        floorBuilder
            .withPosition(at: position)
            .withPhysics(rectangleOf: size)
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.floor)
                .configureContactTestMask(PhysicsConstants.ContactMask.floor)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.floor)
                .configureIsDynamic(false)
                .configureRestitution(0.0)
            .addToGame()
    }

    static func createAndAddGrappleHook(to entityManager: EntityManagerInterface,
                                        playerId: EntityId,
                                        isLeft: Bool,
                                        startpoint: CGPoint) {
        let ropeId = UUID()
        let ropeBuilder = EntityBuilder(entity: Rope(id: ropeId), entityManager: entityManager)

        ropeBuilder
            .withPosition(at: startpoint)
            .withSprite(image: SpriteConstants.rope,
                        imageMode: "faceRight",
                        textureSet: nil,
                        textureAtlas: nil,
                        size: .zero)
            .withPhysics(rectangleOf: .zero)
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.hook)
                .configureContactTestMask(PhysicsConstants.ContactMask.hook)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.hook)
                .configureIsDynamic(false)
                .configureRestitution(0.0)
                .configureAffectedByGravity(false)
            .addToGame()

        let grappleHookBuilder = EntityBuilder(entity: GrappleHook(id: UUID()), entityManager: entityManager)

        grappleHookBuilder
            .withHookOwner(playerId: playerId)
            .withOwnsRope(ropeId: ropeId)
            .withGrappleHook(at: startpoint, isLeft: isLeft)
            .withPosition(at: startpoint)
            .withSprite(image: SpriteConstants.hook,
                        imageMode: "faceRight",
                        textureSet: nil,
                        textureAtlas: nil,
                        size: PhysicsConstants.Dimensions.hook)
            .withPhysics(rectangleOf: PhysicsConstants.Dimensions.hook)
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.hook)
                .configureContactTestMask(PhysicsConstants.ContactMask.hook)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.hook)
                .configureIsDynamic(true)
                .configureRestitution(0.0)
                .configureAffectedByGravity(false)
            .addToGame()
    }

    static func createAndAddFinishLine(to entityManager: EntityManagerInterface, position: CGPoint) {
        let finishLine = EntityBuilder(entity: FinishLine(id: UUID()), entityManager: entityManager)

        finishLine
            .withPosition(at: position)
            .withSprite(image: SpriteConstants.flag,
                        imageMode: "faceRight",
                        textureSet: nil,
                        textureAtlas: nil,
                        size: PhysicsConstants.Dimensions.flag)
            .addToGame()
    }

    static func createAndAddBoundary(to entityManager: EntityManagerInterface, position: CGPoint, size: CGSize) {
        let boundaryBuilder = EntityBuilder(entity: Wall(id: UUID()), entityManager: entityManager)

        boundaryBuilder
            .withPosition(at: position)
            .withPhysics(rectangleOf: size)
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.boundary)
                .configureContactTestMask(PhysicsConstants.ContactMask.boundary)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.boundary)
                .configureIsDynamic(false)
                .configureRestitution(0.0)
            .addToGame()
    }
}

// MARK: Power-ups
extension EntityFactory {
    static func createAndAddPowerUpBox(to entityManager: EntityManagerInterface,
                                       position: CGPoint,
                                       size: CGSize,
                                       type: String) {
        let powerUpBoxBuilder = EntityBuilder(entity: PowerUpBox(id: UUID()), entityManager: entityManager)

        powerUpBoxBuilder
            .withPosition(at: position)
            .withSprite(image: SpriteConstants.powerUpBox,
                        imageMode: "faceRight",
                        textureSet: nil,
                        textureAtlas: nil,
                        size: size)
            .withPhysics(rectangleOf: size)
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.powerUpBox)
                .configureContactTestMask(PhysicsConstants.ContactMask.powerUpBox)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.powerUpBox)
                .configureIsDynamic(false)
            .withPowerUpType(type: type)
            .addToGame()
    }

    static func createAndAddSpeedBoostPowerUp(to entityManager: EntityManagerInterface,
                                              entityId: EntityId,
                                              duration: Float,
                                              multiplier: CGFloat) {
        let powerUpBuilder = EntityBuilder(entity: SpeedBoostPowerUp(id: UUID()), entityManager: entityManager)

        powerUpBuilder
            .withSpeedBoost(entityId: entityId, duration: duration, multiplier: multiplier)
            .addToGame()
    }

    static func createAndAddHomingMissilePowerUp(to entityManager: EntityManagerInterface,
                                                 position: CGPoint,
                                                 triggeredBy entityId: EntityId,
                                                 impulse: CGVector) {
        let powerUpBuilder = EntityBuilder(entity: HomingMissile(id: UUID()), entityManager: entityManager)

        powerUpBuilder
            .withPosition(at: position)
            .withSprite(image: SpriteConstants.homingMissile,
                        imageMode: "faceRight",
                        textureSet: nil,
                        textureAtlas: nil,
                        size: PhysicsConstants.Dimensions.homingMissile)
            .withPhysics(rectangleOf: PhysicsConstants.Dimensions.homingMissile)
                .configureCategoryBitMask(PhysicsConstants.CollisionCategory.homingMissile)
                .configureContactTestMask(PhysicsConstants.ContactMask.homingMissile)
                .configureCollisionBitMask(PhysicsConstants.CollisionMask.homingMissile)
                .configureAffectedByGravity(false)
                .configureLinearDamping(0)
            .withHomingMissile(sourceId: entityId, impulse: impulse)
            .addToGame()
    }
}
