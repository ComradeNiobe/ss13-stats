// Copyright (C) 2025 Comrade Niobe
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Fluent

struct CreateServers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("servers")
            .field(.id, .string, .identifier(auto: false))
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
