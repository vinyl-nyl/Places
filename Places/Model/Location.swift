//
//  Location.swift
//  Places
//
//  Created by junil on 8/5/24.
//

import Foundation

// Model
struct Loc: Hashable {
    var locName: String
    var locDescrption: String
    var locAddress: String
    var locPositionLat: Double
    var locPositionLng: Double
    var locLink: String?
    var locOpeningHours: String?
    var locType: String
}

// PlaceItem 모델
struct PlaceItem: Codable {
    let category: String
    let address: String
    let roadAddress: String
    let mapx: String
    let title: String
    let link: String
    let mapy: String
    let description: String
}

// SearchResponse DTO
struct SearchResponse: Codable {
    let lastBuildDate: String
    let display: Int
    let items: [PlaceItem]
}
