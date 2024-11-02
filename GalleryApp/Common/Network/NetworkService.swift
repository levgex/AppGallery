//
//  NetworkService.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class NetworkService {
    static let shared: NetworkService = NetworkService()

    private var apiKey: String?

    func configureWith(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetch(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let apiKey else {
            completion(.failure(Errors.apiKeyNotFound))
            return
        }

        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(Errors.invalidData))
                return
            }

            if !(200...299).contains(httpResponse.statusCode) {
                do {
                    let apiError = try JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError))
                } catch {
                    completion(.failure(Errors.invalidData))
                }
                return
            }

            completion(.success(data))

        }.resume()
    }
}
