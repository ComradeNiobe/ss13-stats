// Copyright (C) 2025 Comrade Niobe
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Fluent
import Vapor

/// The SS13 hub. Updated on every scrape.
struct Hub: Content {
    var totalPlayers: Int = 0
    var servers: [ServerDTO]?

    /// Updates the Hub cache with fresh data after a scrape.
    mutating func update(using app: Application) async throws {
        let servers = try await Server.query(on: app.db).with(\.$snapshots).all().map { $0.toDTO() }

        var totalPlayers = 0
        for server in servers {
            guard let players = server.players else {
                continue
            }
            totalPlayers += players
        }

        let hubSync = app.locks.lock(for: HubSyncKey.self)
        hubSync.withLockVoid {
            self.totalPlayers = totalPlayers
            self.servers = servers
        }
    }
}

struct HubKey: StorageKey {
    typealias Value = Hub
}

struct HubSyncKey: LockKey {}

extension Application {
    var hub: Hub? {
        get {
            storage[HubKey.self]
        }
        set {
            storage[HubKey.self] = newValue
        }
    }
}
