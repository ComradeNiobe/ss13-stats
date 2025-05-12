import Fluent

struct CreateServerSnapshots: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("server_snapshots")
            .id()
            .foreignKey("server_id", references: "servers", "id")
            .field("player_count", .int, .required)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("server_snapshots").delete()
    }
}
