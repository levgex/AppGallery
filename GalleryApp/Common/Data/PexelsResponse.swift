//
//  PexelsResponse.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import Foundation

struct PexelsResponse: Codable {
    let nextPage: String
    let photos: [Photo]

    enum CodingKeys: String, CodingKey {
        case nextPage = "next_page"
        case photos
    }
}

struct PexelsErrorResponse: Codable {
    let status: Int
    let code: String
}

// MARK: - Parsing

extension PexelsResponse {
    static func parse(from data: Data) -> Result<PexelsResponse, Error> {
        do {
            let pexelsResponse = try JSONDecoder().decode(PexelsResponse.self, from: data)
            return .success(pexelsResponse)
        } catch {
            return .failure(error)
        }
    }
}

extension PexelsErrorResponse {
    static func parse(from data: Data) -> Result<PexelsErrorResponse, Error> {
        do {
            let pexelsResponse = try JSONDecoder().decode(PexelsErrorResponse.self, from: data)
            return .success(pexelsResponse)
        } catch {
            return .failure(error)
        }
    }
}

