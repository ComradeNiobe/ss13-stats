import Fluent

import struct Foundation.UUID

/// A server on the SS13 Hub.
final class Server: Model, @unchecked Sendable {
    static let schema: String = "servers"

    @ID
    var id: UUID?

    /// When this server was scraped from the Hub.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    /// When this server was updated with newly scraped data.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    /// When this server was deleted; relevant in cases of a server shutting down or otherwise not being seen for a long time.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    /// The name of this server.
    @Field(key: "name")
    var name: String

    /// The server's player history as a dictionary where `Key` is the date and `Value` is the player amount.
    @Field(key: "player_history")
    var playerHistory: [Date: UInt]

    init() {}

    init(name: String, playerHistory: [Date: UInt]) {
        self.name = name
        self.playerHistory = playerHistory
    }
}
