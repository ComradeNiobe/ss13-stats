import Fluent
import Vapor

struct TodoController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let todos = routes.grouped("todos")

        todos.get(use: self.scrape)
        todos.post(use: self.create)
        todos.group(":todoID") { todo in
            todo.delete(use: self.delete)
        }
    }

    /// GET request to the backend scraper. Updates the database with the newly scraped server data.
    /// - Returns: HTTP OK on successful scrape.
    @Sendable
    func scrape(req: Request) async throws -> [ServerDTO] {
        //try await Todo.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func create(req: Request) async throws -> ServerDTO {
        let todo = try req.content.decode(TodoDTO.self).toModel()

        try await todo.save(on: req.db)
        return todo.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let todo = try await Todo.find(req.parameters.get("todoID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await todo.delete(on: req.db)
        return .noContent
    }
}
