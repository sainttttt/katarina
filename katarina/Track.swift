//
//  Track.swift
//  gloss
//
//  Created by Saint on 2/24/23.
//

import GRDB
struct Track: Identifiable, Equatable {
    var id: Int64?
    var pos: Int?
    var fileURL: String
    var filename: String
    var armed: Bool
}

extension Track {
}

// MARK: - Persistence

/// Make Line a Codable Record.
///
/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension Track: Codable, FetchableRecord, MutablePersistableRecord {
    // Define database columns from CodingKeys
    fileprivate enum Columns {
        static let id = Column(CodingKeys.id)
        static let pos = Column(CodingKeys.pos)
    }
    
    /// Updates a player id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Line Database Requests

/// Define some player requests used by the application.
///
/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#requests>
/// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
extension DerivableRequest<Track> {
}
//  Track.swift
//  katherine
//
//  Created by Saint on 8/10/23.
//

import Foundation
