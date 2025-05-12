import Fluent

import struct Foundation.UUID

/// A server on the SS13 Hub.
final class Server: Model, @unchecked Sendable {
    static let schema: String = "servers"

    @ID
    var id: UUID?

    /// The name of this server.
    @Field(key: "name")
    var name: String

    /// Current player count.
    @Field(key: "players")
    var players: Int

    /// Historical snapshot records.
    @Children(for: \.$serverId)
    var snapshotHistory: [ServerSnapshot]

    /// Adult content rating. False by default.
    @Field(key: "adult")
    var adult: Bool

    /// When this server was updated with newly scraped data.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    /// When this server was deleted; relevant in cases of a server shutting down or otherwise not being seen for a long time.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() {}

    init(id: UUID? = nil, name: String, players: Int, adult: Bool) {
        self.id = id
        self.name = name
        self.players = players
        self.adult = adult
    }

    func toDTO() -> ServerDTO {
        .init(
            id: id,
            name: $name.value,
            players: $players.value,
            adult: $adult.value,
            updatedAt: $updatedAt.timestamp,
            deletedAt: $deletedAt.timestamp,
        )
    }
}
