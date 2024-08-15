import Foundation
import GRDB

/// AppDatabase lets the application access the database.
///
/// It applies the pratices recommended at
/// <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
struct AppDatabase {
    /// Creates an `AppDatabase`, and make sure the database schema is ready.
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }

    /// Provides access to the database.
    ///
    /// Application can use a `DatabasePool`, while SwiftUI previews and tests
    /// can use a fast in-memory `DatabaseQueue`.
    ///
    /// See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseconnections>
    private let dbWriter: any DatabaseWriter

    /// The DatabaseMigrator that defines the database schema.
    ///
    /// See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations>
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // Speed up development by nuking the database when migrations change
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations>
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("createLine") { db in
            // Create a table
            // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseschema>
            try db.create(table: "Track") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("pos", .integer)
                t.column("fileURL", .text)
                t.column("filename", .text).unique()
                t.column("armed", .boolean).defaults(to: false)
            }

            try db.create(table: "foo3") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("ribbonId", .integer).notNull()
            }
        }


        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }

        return migrator
    }
}

// MARK: - Database Access: Writes


func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

extension AppDatabase {

    // func updateRibbonPosition(_ ribbon: inout Ribbon, _ oldPos: Int, _ newPos: Int) async throws {
    //     try await dbWriter.write { [ribbon] db in

    //         // This is only for moving back rn

    //         print("MEOW HERE")
    //         print(oldPos)
    //         print(newPos)
    //         print(ribbon)
    //         print(ribbon.id!)
    //         print("MEOW HERE 2")


    //         // try db.execute(sql: """
    //         //                BEGIN TRANSACTION;
    //         //                """)
    //         do {

    //             if (newPos < oldPos) {

    //         try db.execute(sql: """
    //                        UPDATE Ribbon
    //                        SET pos =
    //                        CASE
    //                        WHEN pos = ? THEN ?
    //                        ELSE
    //                        pos + 1
    //                        END
    //                        WHERE (pos >= ? AND pos <= ?)
    //                        """, arguments: [oldPos, newPos, newPos, oldPos])
    //         } else {

    //             print("DIFFFFF")

    //         try db.execute(sql: """
    //                        UPDATE Ribbon
    //                        SET pos =
    //                        CASE
    //                        WHEN pos = ? THEN ?
    //                        ELSE
    //                        pos - 1
    //                        END
    //                        WHERE (pos >= ? AND pos <= ?)
    //                        """, arguments: [oldPos, newPos, oldPos, newPos])

    //         }

    //         // try db.execute(sql: """
    //         //                UPDATE Ribbon
    //         //                SET pos = ?
    //         //                WHERE (id = ?)
    //         //                """, arguments: [newPos, ribbon.id!])

    //     var ret =  try Ribbon.fetchAll(db, sql: "SELECT * FROM Ribbon ORDER BY pos ASC") // [Player]
    //     // print(ret)
    //         print("all")
    //      print(ret)
    //         } catch {
    //             print("Error info: \(error)")
    //         }

    //         // try ribbon.saved(db)

    //         // try db.execute(sql: """
    //         //                COMMIT;
    //         //                """)

    //     }

    // }

    // func saveRibbon(_ ribbon: inout Ribbon) async throws {
    //     // if ribbon.name.isEmpty {
    //     //     throw ValidationError.missingName
    //     // }
    //     ribbon = try await dbWriter.write { [ribbon] db in
    //         try ribbon.saved(db)
    //     }
    // }

    // func saveSelectedRibbon(_ selectedRibbon: inout SelectedRibbon) async throws {
    //     // if ribbon.name.isEmpty {
    //     //     throw ValidationError.missingName
    //     // }
    //     try await dbWriter.write { [selectedRibbon] db in
    //         try selectedRibbon.update(db)
    //     }
    // }

    func loadTrack(_ fileURL: URL) async throws {
        print("creating track with URL \(fileURL.path)")

        // let pathComponents = fileURL.pathComponents.suffix(1)
        let pathComponents = fileURL.deletingPathExtension().pathComponents.suffix(1)
        let filename = (pathComponents.joined(separator: "/"))

        do {

            try await dbWriter.write { db in

            try db.execute(sql: """
                           DELETE from track
                           """ )

                try db.execute(sql: """
            INSERT INTO track(fileURL, filename) VALUES (?, ?)

            ON CONFLICT (filename) DO
            UPDATE SET fileURL=excluded.fileURL
        """, arguments:[fileURL.path, filename])
            }
        }  catch {
            print("caught error:\(error)")
        }
    }

    // func saveScrollState(_ scrollState: inout ScrollState) async throws {
    //     // if ribbon.name.isEmpty {
    //     //     throw ValidationError.missingName
    //     // }
    //     try await dbWriter.write { [scrollState] db in
    //         try scrollState.update(db)
    //     }
    // }
    // func importJson(_ filename: String, _ db: Database) throws {
    //     let importJson : JsonImport = load(filename)

    //     if try Line.all().isEmpty(db) {
    //         for l in importJson.lines {
    //             print("importing Lines")
    //             _ = try l.inserted(db)
    //         }

    //         for l in importJson.segs {
    //             print("importing SEGS")
    //             _ = try l.inserted(db)
    //         }
    //     }
    // }

    // /// Create random Lines if the database is empty.
    // func initDatabase() throws {
    //     try dbWriter.write { db in

    //         if try Line.all().isEmpty(db) {

    //             try importJson("john_export.json", db)
    //             try importJson("mark_export.json", db)
    //             _ = try Ribbon(id: 1, pos: 1, title: "John", book: "bible.john", scrollId: "1", scrollOffset: 0).inserted(db)
    //             _ = try Ribbon(id: 2, pos: 2, title: "Gospel of Mark", book: "bible.mark", scrollId: "1", scrollOffset: 300).inserted(db)
    //             _ = try Ribbon(id: 3, pos: 3, title: "John 2", book: "bible.john", scrollId: "1", scrollOffset: 0).inserted(db)
    //             _ = try SelectedRibbon(id: 1, ribbonId: 1).inserted(db)
    //         }
    //     }
    // }

}

// MARK: - Database Access: Reads

// This demo app does not provide any specific reading method, and insteadKK
// gives an unrestricted read-only access to the rest of the application.
// In your app, you are free to choose another path, and define focused
// reading methods.
extension AppDatabase {
    /// Provides a read-only access to the database
    var reader: DatabaseReader {
        dbWriter
    }
}
