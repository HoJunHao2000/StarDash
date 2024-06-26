//
//  PositionSystem.swift
//  star-dash
//
//  Created by Ho Jun Hao on 13/3/24.
//

import Foundation

class PositionSystem: System {
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

    func move(entityId: EntityId, to newPosition: CGPoint) {
        guard let positionComponent = getPositionComponent(of: entityId) else {
            return
        }

        positionComponent.position = newPosition
    }

    func rotate(entityId: EntityId, to newRotation: CGFloat) {
        guard let positionComponent = getPositionComponent(of: entityId) else {
            return
        }

        positionComponent.rotation = newRotation
    }

    func rotate(entityId: EntityId, inDirection direction: CGVector) {
        guard let positionComponent = getPositionComponent(of: entityId) else {
            return
        }

        let angle = atan2(direction.dy, direction.dx)
        let newRotation = angle - Double.pi / 2
        positionComponent.rotation = newRotation
    }

    func isEntityFacingLeft(entityId: EntityId) -> Bool {
        guard let positionComponent = getPositionComponent(of: entityId) else {
            return false
        }

        return positionComponent.isFacingLeft
    }

    func setEntityFacingLeft(_ isFacingLeft: Bool, entityId: EntityId) {
        guard let positionComponent = getPositionComponent(of: entityId) else {
            return
        }

        positionComponent.isFacingLeft = isFacingLeft
    }

    func getPosition(of entityId: EntityId) -> CGPoint? {
        guard let positionComponent = getPositionComponent(of: entityId) else {
            return nil
        }

        return positionComponent.position
    }

    func getEntityAhead<T: Entity>(of position: CGPoint, ofType entityType: T.Type) -> EntityId? {
        for positionComponent in entityManager.components(ofType: PositionComponent.self) {
            guard let entity = entityManager.entity(with: positionComponent.entityId) as? T,
                  positionComponent.position.x > position.x else {
                continue
            }

            return entity.id
        }

        return nil
    }

    func setup() {
        dispatcher?.registerListener(self)
        dispatcher?.registerListener(self)

        eventHandlers[ObjectIdentifier(TeleportEvent.self)] = { event in
            if let teleportEvent = event as? TeleportEvent {
                self.handleTeleportEvent(event: teleportEvent)
            }
        }
        eventHandlers[ObjectIdentifier(UpdatePositionEvent.self)] = { event in
            if let updatePositionEvent = event as? UpdatePositionEvent {
                self.handleUpdatePosition(event: updatePositionEvent)
            }
        }
    }

    private func handleTeleportEvent(event: TeleportEvent) {
        move(entityId: event.entityId, to: event.destination)
    }

    private func handleUpdatePosition(event: UpdatePositionEvent) {
        move(entityId: event.entityId, to: event.position)
    }

    private func getPositionComponent(of entityId: EntityId) -> PositionComponent? {
        entityManager.component(ofType: PositionComponent.self, of: entityId)
    }
}
