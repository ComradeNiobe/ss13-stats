// Copyright (C) 2025 Comrade Niobe
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Fluent
import Vapor

struct ServerDTO: Content {
    var id: BlakeHash?
    var name: String?
    var players: Int?
    var snapshots: [ServerSnapshotDTO]?
    var adult: Bool?
    var updatedAt: Date?
    var deletedAt: Date?

    func toModel() -> Server {
        let model = Server()

        model.id = id
        model.name = name!
        model.players = players!
        model.adult = adult ?? false

        return model
    }
}

struct HubJSON: Content {
    var id: UInt
    var status: String
    var players: Int
    var adult: Bool?
}
