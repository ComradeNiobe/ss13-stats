import Fluent
import Vapor

struct ServerDTO: Content {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var name: String
    var playerHistory: [Date: UInt]
}
