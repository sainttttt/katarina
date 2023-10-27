import Combine
import GRDB
import GRDBQuery

var idColumn = Column("id")
struct TrackRequest: Queryable {

    var id: Int64!

    // MARK: - Queryable Implementation
    
    static var defaultValue: [Track] { [] }
    
    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[Track], Error> {
        ValueObservation
            .tracking(fetchValue(_:))
            .publisher(
                in: appDatabase.reader,
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }
    
    func fetchValue(_ db: Database) throws -> [Track] {

        print("GOT HERE MEOW OWOWOWOWOWOWOW")
        print("fetch tracks")
        var tracks = [Track]()

        do {
            tracks = try Track.fetchAll(db)
            print(tracks)
            return tracks
        } catch {
            print(error)
        }
        // if (id == nil) {
        //     // return try Track.order(Column("pos")).fetchAll(db)
        //     return try Track.fetchAll(db)
        // } else {
        //     return try Track.filter(idColumn == id).fetchAll(db)
        // }
        return tracks
    }
}
