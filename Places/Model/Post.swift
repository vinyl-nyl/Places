//
//  Post.swift
//  Places
//
//  Created by junil on 5/22/24.
//
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: Post Model
struct Post: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var text: String
    var imageURL: URL?
    var imageReferenceID: String?
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var userName: String
    var userUID: String
    var userProfileURL: URL
    var location: GeoPoint? // 위치 데이터를 저장할 속성 추가

    enum CodingKeys: CodingKey {
        case id
        case text
        case imageURL
        case imageReferenceID
        case publishedDate
        case likedIDs
        case userName
        case userUID
        case userProfileURL
        case location
    }
}
