// Copyright (C) 2025 Comrade Niobe
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Fluent

struct CreateServerSnapshots: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("server_snapshots")
            .id()
            .field("server_id", .uuid, .required, .references("servers", "id"))
            .field("player_count", .int, .required)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("server_snapshots").delete()
    }
}
