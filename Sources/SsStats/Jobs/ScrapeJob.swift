// Copyright (C) 2025 Comrade Niobe
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Arrow
import BLAKE3
import Fluent
import Queues
import SwiftSoup
import Vapor

struct ScrapeJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        let app = context.application
        let byondHub: URI = "https://node.goonhub.com/hub"
        let response = try await app.client.get(byondHub) { req in
            req.headers.replaceOrAdd(
                name: .userAgent,
                value: "ss13stats/0.1.0-alpha"
            )
            req.timeout = .seconds(60)
        }

        if response.status == .ok {
            guard let rawJson = response.body else {
                throw Abort(.noContent, reason: "Response returned no body.")
            }

            var hubJson: [JSON]
            if let json = JSON(String(buffer: rawJson)) {
                hubJson = (json["response"]?.collection)!
            } else {
                throw Abort(.noContent, reason: "Response body returned no JSON-encodable content.")
            }

            // let document: Document = try SwiftSoup.parse(html, byondHub.string)

            var scrapedServers: [ServerDTO] = []
            try hubJson.forEach { serverEntry in
                guard let entry = try parse(json: serverEntry) else {
                    return
                }

                scrapedServers.append(entry)
            }

            let scrapedServersToSave: [Server] = scrapedServers.map { $0.toModel() }
            await withThrowingTaskGroup(of: Void.self) { taskGroup in
                for server in scrapedServersToSave {
                    taskGroup.addTask {
                        let snapshot = ServerSnapshot(playerCount: server.players)
                        try await app.db.transaction { transaction in
                            if let savedServer = try await Server.find(server.id, on: transaction) {
                                savedServer.players = server.players
                                try await savedServer.save(on: transaction)
                                try await savedServer.$snapshots.create(snapshot, on: transaction)
                            } else {
                                try await server.save(on: transaction)
                                try await server.$snapshots.create(snapshot, on: transaction)
                            }
                        }
                    }
                }
            }

            guard var hub = app.hub else {
                throw Abort(.internalServerError, reason: "Couldn't access internal hub cache.")
            }
            try await hub.update(using: app)
        } else {
            throw Abort(.notFound, reason: "Reason: \(response.status.reasonPhrase)")
        }
    }

    func parse(json: JSON) throws -> ServerDTO? {
        guard let rawName = json["status"]?.data as? String else {
            return nil
        }
        guard var name = try SwiftSoup.parseBodyFragment(rawName).select("b").first()?.text() else {
            return nil
        }
        guard let players = json["players"]?.data as? Int else {
            return nil
        }

        // Don't bother returning empty servers. We'll know when to cull dead servers this way, too.
        guard players >= 1 else {
            return nil
        }

        name = try SwiftSoup.clean(name, Whitelist.none())!

        let nameHash = hashString(name)

        let adult = json["meta.adult"]?.data as? Bool

        return ServerDTO(id: nameHash, name: name, players: players, adult: adult)
    }

    func hashString(_ string: String) -> BlakeHash {
        let hasher = BLAKE3()
        hasher.update(data: string.data(using: .utf8)!)
        let hash = hasher.finalizeData()
        let hashedString = hash.map { String(format: "%02hhx", $0) }.joined()

        return hashedString
    }
}
