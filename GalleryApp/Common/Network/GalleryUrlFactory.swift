//
//  GalleryUrlFactory.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import Foundation

protocol PhotoUrlFactory {
    func makeUrlWithPage(_ page: Int, perPage: Int) -> Result<URL, Error>
}

// MARK: - GalleryUrlFactory

class GalleryUrlFactory {

    enum Endpoint: String {
        static let basePath = "https://api.pexels.com/"

        case curatedPhotos = "curated"
    }

    private enum QueryParameter {
        public static let page = "page"
        public static let perPage = "per_page"
    }

    // MARK: - Private properties

    private let endpoint: Endpoint
    private let version: String
    private lazy var endpointUrl: URL? = {
        URL(string: Endpoint.basePath)?
            .appendingPathComponent(version)
            .appendingPathComponent(endpoint.rawValue)
    }()

    // MARK: - Initialization

    init(endpoint: Endpoint, version: String = "v1") {
        self.endpoint = endpoint
        self.version = version
    }

    // MARK: - Private methods

    private func makeQueryItem(page: Int) -> URLQueryItem {
        URLQueryItem(name: QueryParameter.page, value: page.string)
    }

    private func makeQueryItem(perPage: Int) -> URLQueryItem {
        URLQueryItem(name: QueryParameter.perPage, value: perPage.string)
    }
}

// MARK: - PhotoUrlFactory

extension GalleryUrlFactory: PhotoUrlFactory {

    func makeUrlWithPage(_ page: Int, perPage: Int) -> Result<URL, Error> {
        guard let url = endpointUrl?.appending(queryItems: [
            self.makeQueryItem(page: page),
            self.makeQueryItem(perPage: perPage)
        ]) else {
            return .failure(Errors.invalidURL(self.endpoint.rawValue))
        }

        return .success(url)
    }
}
