//
//  SearchPlaceService.swift
//  Places
//
//  Created by junil on 8/5/24.
//

import Foundation

extension Bundle {
    var naverAPIClientID: String {
        return object(forInfoDictionaryKey: "NaverAPIClientID") as? String ?? ""
    }

    var naverAPIClientSecret: String {
        return object(forInfoDictionaryKey: "NaverAPIClientSecret") as? String ?? ""
    }
}

class SearchPlaceService {
    // NetworkError 정의
    enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case invalidData
    }
    
    // 네이버 API에서 장소에 대한 데이터를 받아오는 메서드
    func search(query: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openapi.naver.com/v1/search/local.json?query=\(encodedQuery)&display=10&start=1&sort=random") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Bundle.main.naverAPIClientID, forHTTPHeaderField: "X-Naver-Client-Id")
        request.setValue(Bundle.main.naverAPIClientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NetworkError.invalidData))
            }
        }
        task.resume()
    }
    
    // 네이버에서 받아온 JSON 데이터를 파싱하는 메서드
    func getData(searchText: String, completion: @escaping (Result<SearchResponse, Error>) -> Void) {
        search(query: searchText) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let response = try decoder.decode(SearchResponse.self, from: data)
                    completion(.success(response)) // 파싱된 전체 응답 데이터를 반환
                } catch {
                    completion(.failure(error))
                    print("Error parsing JSON:", error)
                }
            case .failure(let error):
                completion(.failure(error))
                print("Error:", error)
            }
        }
    }
}
