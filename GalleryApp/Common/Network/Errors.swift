//
//  Errors.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import Foundation

enum Errors: Error, LocalizedError {
    public typealias Description = String

    case dataParsingError
    case createImageFailed
    case invalidData
    case invalidURL(Description)
    case apiKeyNotFound
    case responseError(Description)
    case unauthorized(Description)

    var errorDescription: String? {
        switch self {
        case .dataParsingError:
            return "Data parsing failed"
        case .createImageFailed:
            return "Create image failed"
        case .invalidData:
            return "Invalid data"
        case .invalidURL(let description):
            return "Invalid URL: \(description)"
        case .apiKeyNotFound:
            return "API key not found"
        case .responseError(let description):
            return "Response error: \(description)"
        case .unauthorized(let description):
            return "Response error: \(description)"
        }
    }
}

struct APIError: Decodable, Error, LocalizedError {
    let status: Int
    let code: String
    let message: String?

    var errorDescription: String? {
        return "Error \(status): \(code) \(message ?? "")"
    }

    var isAuthorizationError: Bool {
        self.status == 401
    }
}
