import SDPhysicsEngine

class RenderSynchronizer {

    var entityManager: EntityManager

    var entitiesMap: [EntityId: SDObject]
    var modules: [SyncModule]
    var creationModule: CreationModule?

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
        modules = []
        entitiesMap = [:]

        registerModules()
    }

    func sync() {
        var toRemove = Set(entitiesMap.keys)
        
        for entity in entityManager.entityMap.values {
            toRemove.remove(entity.id)
            if let object = entitiesMap[entity.id] {
                update(object: object, from: entity)
            } else {
                createObject(from: entity)
            }
        }

        for entityId in toRemove {
            removeObject(from: entityId)
        }
    }

    func registerModule(_ module: SyncModule) {
        modules.append(module)
    }

    private func registerModules() {
        let spriteModule = SpriteModule(entityManager: entityManager)
        self.creationModule = spriteModule

        registerModule(spriteModule)
        registerModule(ObjectModule(entityManager: entityManager))
        registerModule(PhysicsModule(entityManager: entityManager))
    }

    private func update(object: SDObject, from entity: Entity) {
        modules.forEach {
            $0.sync(entity: entity, into: object)
        }
    }

    private func createObject(from entity: Entity) {
        guard let newObject = creationModule?.createObject(from: entity) else {
            return
        }

        modules.forEach {
            $0.create(for: newObject, from: entity)
        }
    }

    private func removeObject(from entityId: EntityId) {
        return
    }
}
