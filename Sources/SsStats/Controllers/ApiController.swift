// Copyright (C) 2025 Comrade Niobe
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Arrow
import Fluent
import Vapor

/// The core API that enables RESTful communication between the backend and frontend via JSON.
struct ApiController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")

        api.get("servers", use: getAll)
        api.get("servers", "simple", use: getAllSimple)
        api.get("server", ":id", use: showOne)
    }

    @Sendable
    func getAll(req: Request) async throws -> [ServerDTO] {
        if let hubCache = req.application.hub?.servers {
            return hubCache
        } else {
            let servers = try await Server.query(on: req.db).with(\.$snapshots).all().map { $0.toDTO() }
            return servers
        }
    }

    @Sendable
    func getAllSimple(req: Request) async throws -> [ServerDTO] {
        let servers = try await Server.query(on: req.db).all().map { $0.toDTO() }
        return servers
    }

    @Sendable
    func showOne(req: Request) async throws -> ServerDTO {
        if let hubCache = req.application.hub?.servers {
            guard let server = hubCache.first(where: { $0.id == req.parameters.get("id") }) else {
                throw Abort(.notFound)
            }
            return server
        } else {
            guard let id = req.parameters.get("id", as: BlakeHash.self) else {
                throw Abort(.notFound)
            }
            guard let server = try await Server.query(on: req.db).filter(\.$id == id).with(\.$snapshots).first() else {
                throw Abort(.notFound)
            }
            return server.toDTO()
        }
    }
}
