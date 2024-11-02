//
//  GalleryModel.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

protocol GalleryModel {
    var photos: [[Photo]] { get }
    var photoProvider: GalleryPhotoProvider { get }

    func subscribe(_ subscriber: GalleryModelSubscriber)

    func fetchInitialData()
    func fetchNextData()
    func refresh()
    func getImage(forPhoto photo: Photo, completion: @escaping (_ image: UIImage?, _ fromCache: Bool) -> Void) -> URLSessionDataTask?
}

// MARK: - GalleryModelSubscriber

protocol GalleryModelSubscriber: AnyObject {
    func modelDidUpdate(_ model: GalleryModel)
    func loadedNewDataSection(_ model: GalleryModel, newSectionIndex: Int)
    func requestDidFail(_ model: GalleryModel, error: Error)
}

// MARK: - GalleryModelDefault

class GalleryModelDefault: GalleryModel {

    // MARK: - Properties

    let photoProvider: GalleryPhotoProvider
    private(set) var photos: [[Photo]] = []
    weak var subscriber: GalleryModelSubscriber?

    // MARK: - Initialization

    init(photoProvider: GalleryPhotoProvider) {
        self.photoProvider = photoProvider
    }

    // MARK: - Methods

    func subscribe(_ subscriber: GalleryModelSubscriber) {
        self.subscriber = subscriber
    }

    func fetchInitialData() {
        photoProvider.fetchPhotos() { result in
            switch result {
            case .success(let photos):
                self.photos = [photos]
                self.notifySubscriberModelDidUpdate()
            case .failure(let error):
                self.notifySubscriberRequestDidFail(error: error)
            }
        }
    }

    func fetchNextData() {
        photoProvider.fetchNextPhotos() { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let downloadedPhotos):
                    self.photos.append(downloadedPhotos)
                    self.notifySubscriberLoadedNewData(newSectionIndex: self.photos.count - 1)
                case .failure(let error):
                    self.notifySubscriberRequestDidFail(error: error)
                }
            }
        }
    }

    func refresh() {
        self.photoProvider.reset()
        self.fetchInitialData()
    }

    func getImage(forPhoto photo: Photo, completion: @escaping (_ image: UIImage?, _ fromCache: Bool) -> Void) -> URLSessionDataTask? {
        guard let imageUrl = URL(string: photo.src.large) else { return nil }

        if let cachedImage = self.getCachedImage(forURL: imageUrl) {
            completion(cachedImage, true)
            return nil
        } else {
            return self.photoProvider.fetchImage(from: imageUrl) { result in
                switch result {
                case .success(let image):
                    completion(image, false)
                case .failure(let error):
                    print("DEBUG: Error: \(error.localizedDescription)")
                    completion(nil, false)
                }
            }
        }
    }
}

// MARK: - Private methods

extension GalleryModelDefault {

    private func getCachedImage(forURL url: URL) -> UIImage? {
        return photoProvider.getCachedImage(forURL: url)
    }

    private func notifySubscriberModelDidUpdate() {
        self.subscriber?.modelDidUpdate(self)
    }

    private func notifySubscriberLoadedNewData(newSectionIndex: Int) {
        self.subscriber?.loadedNewDataSection(self, newSectionIndex: newSectionIndex)
    }

    private func notifySubscriberRequestDidFail(error: Error) {
        self.subscriber?.requestDidFail(self, error: error)
    }
}
