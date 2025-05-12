import Fluent

struct CreateServers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("servers")
            .id()
            .field("name", .string, .required)
            .field("players", .int, .required)
            .field("adult", .bool, .required, .sql(.default(false)))
            .field("updated_at", .datetime, .required)
            .field("deleted_at", .datetime)
            .unique(on: "name")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("servers").delete()
    }
}
