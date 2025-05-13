// Copyright (C) 2025 Comrade Niobe
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

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
