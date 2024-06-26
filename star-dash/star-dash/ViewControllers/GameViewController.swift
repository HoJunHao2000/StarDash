//
//  ViewController.swift
//  star-dash
//
//  Created by Lau Rui han on 12/3/24.
//

import UIKit
import SDPhysicsEngine
import DequeModule
typealias NetworkSyncQueue = Deque<NetworkSyncEvent>

class GameViewController: UIViewController {
    var scene: SDScene?
    var renderer: Renderer?
    var gameBridge: GameBridge?
    var gameEngine: GameEngine?
    var storageManager: StorageManager?
    var networkManager: NetworkManager?
    var level: LevelPersistable?
    var numberOfPlayers: Int = 0
    var playerIndex: Int?
    // to change to enum
    var viewLayout: Int = 0
    var achievementManager: AchievementManager?
    var networkSyncQueue: NetworkSyncQueue = .init()
    var timeSinceLastSync: Double = 0
    var networkSyncInterval: Double = 0.3
    var gameMode: GameMode?
    var areResultsDisplayed = false
    override func viewDidLoad() {
        super.viewDidLoad()
        if let networkManager = networkManager {
            networkManager.delegate = self
        }
        let gameEngine = createGameEngine()
        self.gameEngine = gameEngine

        let scene = createGameScene(of: gameEngine.mapSize)
        self.scene = scene

        self.gameBridge = GameBridge(entityManager: gameEngine, scene: scene)

        setupGame()
        setupBackground(in: scene)

        guard let renderer = MTKRenderer(scene: scene) else {
            return
        }
        if let playerIndex = playerIndex {
            renderer.playerIndex = playerIndex
        }
        renderer.viewDelegate = self
        renderer.setupViews(at: self.view, for: viewLayout)
        self.renderer = renderer
        setupBackButton()

    }

    @objc
    func backButtonTapped() {
        performSegue(withIdentifier: "BackSegue", sender: self)
    }

    private func createGameEngine() -> GameEngine {
        let levelSize = level?.size ?? RenderingConstants.defaultLevelSize
        return GameEngine(mapSize: levelSize, gameMode: gameMode ?? RaceMode(), resultsDelegate: self)
    }

    private func createGameScene(of size: CGSize) -> GameScene {
        // GameScene size width extended for finish line
        let extendedSize = CGSize(
            width: size.width + RenderingConstants.levelSizeRightExtension,
            height: size.height)
        let scene = GameScene(size: extendedSize, for: numberOfPlayers )
        scene.scaleMode = .aspectFill
        scene.sceneDelegate = self
        return scene
    }
}

// MARK: Setup
extension GameViewController {
    private func setupGame() {
        guard let storageManager = self.storageManager,
              let gameEngine = self.gameEngine,
              let scene = self.scene,
              let level = self.level,
              var gameMode = self.gameMode else {
            return
        }
        gameMode.numberOfPlayers = numberOfPlayers
        let entities = storageManager.getAllEntity(id: level.id)
        gameEngine.setupLevel(level: level, entities: entities, sceneSize: scene.size)

        gameMode.setupGameMode()

        self.achievementManager = AchievementManager(withMap: gameEngine.playerIdEntityMap)

        if let achievementManager = self.achievementManager {
            gameEngine.registerListener(achievementManager)
        }
    }

    private func setupBackground(in scene: SDScene) {
        guard let level = self.level else {
            return
        }

        let background = SDSpriteObject(imageNamed: level.background)
        let backgroundWidth = background.size.width
        let backgroundHeight = background.size.height

        var remainingGameWidth = scene.size.width
        var numOfAddedBackgrounds = 0
        while remainingGameWidth > 0 {
            let background = SDSpriteObject(imageNamed: level.background)
            let offset = CGFloat(numOfAddedBackgrounds) * backgroundWidth
            background.position = CGPoint(x: backgroundWidth / 2 + offset, y: backgroundHeight / 2)
            background.zPosition = -1
            scene.addObject(background)
            remainingGameWidth -= backgroundWidth
            numOfAddedBackgrounds += 1
        }
    }

    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        self.view.addSubview(backButton)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

// MARK: Results
extension GameViewController: ResultsDelegate {
    func displayResults(_ results: GameResults) {
        performSegue(withIdentifier: "ShowResultsModalSegue", sender: results)
        areResultsDisplayed = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowResultsModalSegue" {
            if let destinationVC = segue.destination as? ResultsModalViewController {
                if let data = sender as? GameResults {
                    destinationVC.gameResults = data
                }
            }
        }
    }
}

extension GameViewController: SDSceneDelegate {
    func sendNetworkSync(deltaTime: Double) {
        guard let networkManager = networkManager else {
            return
        }
        timeSinceLastSync += deltaTime

        if timeSinceLastSync > networkSyncInterval {
            timeSinceLastSync -= networkSyncInterval
        }
        guard let playerIndex = playerIndex,
              let position = gameEngine?.getPositionOf(playerIndex: playerIndex),
              let score = gameEngine?.getScoreOf(playerIndex: playerIndex) else {
            return
        }
        let playerData = NetworkPlayerData(playerIndex: playerIndex, position: position, score: score)
        networkManager.sendEvent(event: NetworkSyncEvent(playerIndex: playerIndex, playerData: playerData))

    }

    func doNetworkSync() {
        while let event = networkSyncQueue.popFirst() {
            if playerIndex != event.playerIndex {
                syncNetworkPlayer(event: event)
            }
        }
    }

    func update(_ scene: SDScene, deltaTime: Double) {
        gameBridge?.syncToEntities()
        doNetworkSync()
        gameEngine?.update(by: deltaTime)
        sendNetworkSync(deltaTime: deltaTime)
        gameBridge?.syncFromEntities()

    }

    func syncNetworkPlayer(event: NetworkSyncEvent) {
        gameEngine?.syncPlayer(of: event.playerData.playerIndex,
                               score: event.playerData.score,
                               position: event.playerData.position)
    }

    func contactOccurred(objectA: SDObject, objectB: SDObject, contactPoint: CGPoint) {
        guard let entityA = gameBridge?.entityId(of: objectA.id),
              let entityB = gameBridge?.entityId(of: objectB.id) else {
            return
        }

        gameEngine?.handleCollision(entityA, entityB, at: contactPoint)
    }
}

extension GameViewController: ViewDelegate {

    func joystickMoved(toLeft: Bool, playerIndex: Int) {
        guard let networkManager = networkManager  else {
            gameEngine?.handlePlayerMove(toLeft: toLeft, playerIndex: playerIndex, timestamp: Date.now)
            return
        }

        let networkEvent = NetworkPlayerMoveEvent(playerIndex: playerIndex, isLeft: toLeft)
        networkManager.sendEvent(event: networkEvent)

    }

    func joystickReleased(playerIndex: Int) {
        guard let networkManager = networkManager else {
            gameEngine?.handlePlayerStoppedMoving(playerIndex: playerIndex, timestamp: Date.now)
            return
        }

        let networkEvent = NetworkPlayerStopEvent(playerIndex: playerIndex)
        networkManager.sendEvent(event: networkEvent)
    }

    func jumpButtonPressed(playerIndex: Int) {
        guard let networkManager = networkManager else {
            gameEngine?.handlePlayerJump(playerIndex: playerIndex, timestamp: Date.now)
            return
        }
        let networkEvent = NetworkPlayerJumpEvent(playerIndex: playerIndex)
        networkManager.sendEvent(event: networkEvent)

    }

    func hookButtonPressed(playerIndex: Int) {
        guard let networkManager = networkManager else {
            gameEngine?.handlePlayerHook(playerIndex: playerIndex, timestamp: Date.now)
            return
        }
        let networkEvent = NetworkPlayerHookEvent(playerIndex: playerIndex)
        networkManager.sendEvent(event: networkEvent)
    }

    func overlayInfo(forPlayer playerIndex: Int) -> OverlayInfo? {
        guard let gameInfo = gameEngine?.gameInfo(forPlayer: playerIndex) else {
            return nil
        }

        return OverlayInfo(
            score: gameInfo.playerScore,
            health: gameInfo.playerHealth,
            playersInfo: gameInfo.playersInfo,
            mapSize: gameInfo.mapSize,
            time: gameInfo.time
        )
    }
}
extension GameViewController: NetworkManagerDelegate {
    func networkManager(_ networkManager: NetworkManager, didReceiveEvent response: Data) {
        if let event = NetworkEventFactory.decodeNetworkEvent(from: response) as? NetworkPlayerMoveEvent {
            gameEngine?.handlePlayerMove(toLeft: event.isLeft,
                                         playerIndex: event.playerIndex,
                                         timestamp: event.timestamp)
        }
        if let event = NetworkEventFactory.decodeNetworkEvent(from: response) as? NetworkPlayerStopEvent {
            gameEngine?.handlePlayerStoppedMoving(playerIndex: event.playerIndex, timestamp: event.timestamp)
        }
        if let event = NetworkEventFactory.decodeNetworkEvent(from: response) as? NetworkPlayerJumpEvent {
            gameEngine?.handlePlayerJump(playerIndex: event.playerIndex, timestamp: event.timestamp)
        }
        if let event = NetworkEventFactory.decodeNetworkEvent(from: response) as? NetworkPlayerHookEvent {
            gameEngine?.handlePlayerHook(playerIndex: event.playerIndex, timestamp: event.timestamp)
        }
        if let event = NetworkEventFactory.decodeNetworkEvent(from: response) as? NetworkSyncEvent {
            networkSyncQueue.append(event)
        }
    }

    func networkManager(_ networkManager: NetworkManager, didEncounterError error: Error) {
        print(error)
    }

}
