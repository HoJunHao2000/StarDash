import CoreGraphics
import SDPhysicsEngine

class PhysicsModule: SyncModule {
    let entityManager: EntitySyncInterface

    init(entityManager: EntitySyncInterface) {
        self.entityManager = entityManager
    }

    func sync(entity: Entity, from object: SDObject) {
        guard let physicsComponent = entityManager.component(ofType: PhysicsComponent.self, of: entity.id),
              let body = object.physicsBody else {
            return
        }

        physicsComponent.mass = body.mass
        physicsComponent.velocity = body.velocity
        physicsComponent.pinned = body.pinned
    }

    func sync(object: SDObject, from entity: Entity) {
        guard let physicsComponent = entityManager.component(ofType: PhysicsComponent.self, of: entity.id),
              let body = object.physicsBody else {
            return
        }

        body.mass = physicsComponent.mass
        body.velocity = physicsComponent.velocity
        body.pinned = physicsComponent.pinned
        body.affectedByGravity = physicsComponent.affectedByGravity
    }

    func create(for object: SDObject, from entity: Entity) {
        guard let physicsComponent = entityManager.component(ofType: PhysicsComponent.self, of: entity.id) else {
            return
        }

        switch physicsComponent.shape {
        case .rectangle:
            object.physicsBody = createRectanglePhysicsBody(physicsComponent: physicsComponent)
        case .circle:
            object.physicsBody = createCirclePhysicsBody(physicsComponent: physicsComponent)
        }

        object.physicsBody?.velocity = physicsComponent.velocity
        object.physicsBody?.restitution = physicsComponent.restitution
        object.physicsBody?.isDynamic = physicsComponent.isDynamic
        object.physicsBody?.affectedByGravity = physicsComponent.affectedByGravity
        object.physicsBody?.categoryBitMask = physicsComponent.categoryBitMask
        object.physicsBody?.contactTestMask = physicsComponent.contactTestMask
        object.physicsBody?.collisionBitMask = physicsComponent.collisionBitMask
        object.physicsBody?.mass = physicsComponent.mass
        object.physicsBody?.linearDamping = physicsComponent.linearDamping
    }

    private func createRectanglePhysicsBody(physicsComponent: PhysicsComponent) -> SDPhysicsBody {
        guard let size = physicsComponent.size else {
            return SDPhysicsBody(rectangleOf: CGSize(width: 50, height: 50))
        }
        return SDPhysicsBody(rectangleOf: size)
    }

    private func createCirclePhysicsBody(physicsComponent: PhysicsComponent) -> SDPhysicsBody {
        guard let radius = physicsComponent.radius else {
            return SDPhysicsBody(circleOf: 50)
        }
        return SDPhysicsBody(circleOf: radius)
    }
}
