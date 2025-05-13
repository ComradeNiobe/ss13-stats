import Arrow
import Fluent
import SwiftSoup
import Vapor

// TODO: Shove this functionality into a Service and replace with a View controller.
struct ScrapeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")

        api.get("scrape", use: scrape)
    }

    @Sendable
    func scrape(req: Request) async throws -> HTTPStatus {
        let byondHub: URI = "https://node.goonhub.com/hub"
        let response = try await req.client.get(byondHub) { req in
            req.headers.replaceOrAdd(
                name: .userAgent,
                value: "ss13stats/0.1.0-alpha"
            )
            req.timeout = .seconds(60)
        }

        if response.status == .ok {
            guard let rawJson = response.body else {
                throw Abort(.internalServerError)
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
                        let snapshot = ServerSnapshot(playerCount: server.$players.value!)
                        try await req.db.transaction { transaction in
                            try await server.save(on: transaction)
                            try await server.$snapshots.create(snapshot, on: transaction)
                        }
                    }
                }
            }
        } else {
            throw Abort(.notFound, reason: "Reason: \(response.status.reasonPhrase)")
        }

        return .ok
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

        let adult = json["meta.adult"]?.data as? Bool

        return ServerDTO(name: name, players: players, adult: adult)
    }
}
