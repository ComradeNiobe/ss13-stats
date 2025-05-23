// Copyright (C) 2025 Comrade Niobe
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

import Fluent
import FluentPostgresDriver
import Leaf
import NIOSSL
import QueuesRedisDriver
import Vapor
import VaporSecurityHeaders

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "ssStats",
        tls: .prefer(.init(configuration: .clientDefault))
    )
    ), as: .psql)

    app.migrations.add(CreateServers(), CreateServerSnapshots())

    try app.queues.use(.redis(url: Environment.get("REDIS_HOST") ?? "redis://127.0.0.1:6379"))

    // Inits the hub singleton.
    app.hub = .init()
    try await app.hub?.update(using: app)

    // Runs every 30 minutes.
    app.queues.schedule(ScrapeJob())
        .hourly()
        .at(30)
    app.queues.schedule(ScrapeJob())
        .hourly()
        .at(59)

    try app.queues.startScheduledJobs()

    let securityHeaders = SecurityHeadersFactory.api()
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)

    app.middleware = Middlewares()
    app.middleware.use(cors, at: .beginning)
    app.middleware.use(securityHeaders.build())
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    // register routes
    try routes(app)
}
