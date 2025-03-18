//
//  SearchPlaceViewModel.swift
//  Places
//
//  Created by junil on 8/5/24.
//

import Foundation

class SearchPlaceViewModel: ObservableObject {
    // SearchState 정의
    enum SearchState {
        case search
        case notFound
        // 필요한 경우 다른 상태도 추가할 수 있습니다.
    }

    @Published var searchState: SearchState = .search
    @Published var searchText: String = ""
    @Published var placeList: [PlaceItem] = []

    let searchService = SearchPlaceService()

    /// 입력한 텍스트를 기반으로 네이버 검색 API에서 데이터를 받아오는 메서드
    func searchPlace(searchText: String) {
        searchService.getData(searchText: searchText) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // 검색결과가 없을 경우 .notFound 상태로 변경
                    if response.items.isEmpty {
                        self.placeList = []
                        self.searchState = .notFound
                    } else {
                        self.placeList = response.items
                        self.searchState = .search
                    }
                case .failure(let error):
                    print("Failed to fetch place data:", error.localizedDescription)
                }
            }
        }
    }
}
