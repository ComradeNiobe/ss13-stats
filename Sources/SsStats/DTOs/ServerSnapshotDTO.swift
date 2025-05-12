import Fluent
import Vapor

struct ServerSnapshotDTO: Content {
    var id: UUID?
    var serverId: Server.IDValue
    var playerCount: Int
    var createdAt: Date

    func toModel() -> ServerSnapshot {
        let model = ServerSnapshot()

        model.id = id
        model.serverId.id = serverId
        model.playerCount = playerCount
        return model
    }
}
