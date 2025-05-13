import Fluent

import struct Foundation.UUID

/// A snapshot of a server's player count.
final class ServerSnapshot: Model, @unchecked Sendable {
    static let schema: String = "server_snapshots"

    @ID
    var id: UUID?

    /// Foreign key to the server being snapshot. Initialized on server save/update.
    @Parent(key: "server_id")
    var serverId: Server

    @Field(key: "player_count")
    var playerCount: Int

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, playerCount: Int) {
        self.id = id
        self.playerCount = playerCount
    }

    func toDTO() -> ServerSnapshotDTO {
        .init(
            id: id,
            serverId: $serverId.id,
            playerCount: $playerCount.value!,
            createdAt: $createdAt.timestamp!,
        )
    }
}
