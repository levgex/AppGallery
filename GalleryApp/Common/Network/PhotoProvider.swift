//
//  GalleryPhotoProvider.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

protocol PhotoProvider {
    func fetchPhotos(page: Int, completion: @escaping (Result<[Photo], Error>) -> Void)
}

protocol ImageProvider {
    @discardableResult
    func fetchImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) -> URLSessionDataTask?
    func getCachedImage(forURL url: URL) -> UIImage?
    func reset()
}

// MARK: - GalleryPhotoProvider

class GalleryPhotoProvider {

    // MARK: - Properties

    private let urlFactory: PhotoUrlFactory
    private let imageCache = NSCache<NSString, UIImage>()
    private let countItemsPerPage = 20
    private var lastResponse: PexelsResponse?

    // MARK: - Initialization

    init(urlFactory: PhotoUrlFactory) {
        self.urlFactory = urlFactory
    }
}

// MARK: - PhotoProvider

extension GalleryPhotoProvider: PhotoProvider {

    func fetchPhotos(page: Int = 1, completion: @escaping (Result<[Photo], Error>) -> Void) {
        let urlResult = self.urlFactory.makeUrlWithPage(page, perPage: self.countItemsPerPage)

        switch urlResult {
        case .success(let url):
            self.fetchPhotos(url: url, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }

    func fetchNextPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        guard
            let urlString = self.lastResponse?.nextPage,
            let url = URL(string: urlString)
        else {
            self.fetchPhotos(completion: completion)
            return
        }

        self.fetchPhotos(url: url, completion: completion)
    }
}

// MARK: - ImageProvider

extension GalleryPhotoProvider: ImageProvider {

    // MARK: - Methods

    @discardableResult
    func fetchImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) -> URLSessionDataTask? {
        if let cachedImage = self.getCachedImage(forURL: url) {
            completion(.success(cachedImage))
            return nil
        } else {
            return self.fetchNetworkImage(from: url, completion: completion)
        }
    }

    func getCachedImage(forURL url: URL) -> UIImage? {
        return self.imageCache.object(forKey: url.absoluteString as NSString)
    }

    func reset() {
        self.lastResponse = nil
        self.imageCache.removeAllObjects()
    }

    // MARK: - Private methods

    private func fetchNetworkImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) -> URLSessionDataTask? {
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard
                let data,
                let image = UIImage(data: data)
            else {
                completion(.failure(Errors.invalidData))
                return
            }
            self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
            completion(.success(image))
        }

        task.resume()
        return task
    }
}

// MARK: - Private

extension GalleryPhotoProvider {

    private func fetchPhotos(url: URL, completion: @escaping (Result<[Photo], Error>) -> Void) {
        NetworkService.shared.fetch(from: url) { result in
            switch result {
            case .success(let data):
                self.parseResponse(fromData: data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func parseResponse(fromData data: Data, completion: @escaping (Result<[Photo], Error>) -> Void) {
        let responseResult = PexelsResponse.parse(from: data)
        switch responseResult {
        case .success(let response):
            self.lastResponse = response
            completion(.success(response.photos))
        case .failure(_):
            self.parseErrorResponse(fromData: data, completion: completion)
        }
    }

    private func parseErrorResponse(fromData data: Data, completion: @escaping (Result<[Photo], Error>) -> Void) {
        let errorResponse = PexelsErrorResponse.parse(from: data)

        switch errorResponse {
        case .success(let errorResponse):
            completion(.failure(Errors.responseError(errorResponse.code)))
        case .failure(let error):
            completion(.failure(error))
        }
    }

}
