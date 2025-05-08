import Fluent
import SwiftSoup
import Vapor

struct ScrapeController: RouteCollection {
    let byondHub: URI = "https://www.byond.com/games/Exadv1/SpaceStation13"

    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")

        api.get(use: self.scrape)
    }

    // TODO: Finish Hub model and implement HubDTO, then implement scraping.
    @Sendable
    func scrape(req: Request) async throws -> HTTPStatus {
        let response = try await req.client.get(byondHub)
        guard let html = response.body else {
            throw Abort(.notFound)
        }

        return .ok
    }
}
