//
//  GalleryViewController.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class GalleryViewController: UIViewController {

    private enum Constants {
        static let loadingFooterReuseIdentifier = "LoadingFooter"
        static let photoCellReuseIdentifier = String(describing: PhotoCell.self)

        static let footerLoadingIndicatorSize = CGSize(width: 200, height: 200)
    }

    // MARK: - Properties

    var dismissHandler: (() -> Void)?

    // MARK: - Private properties

    private var model: GalleryModel
    private var collectionView: UICollectionView
    private let refreshControl = UIRefreshControl()
    private var collectionViewLayout: UICollectionViewLayout

    private var selectedCell: PhotoCell?
    private var selectedCellFrame: CGRect?

    // MARK: - Initialization

    init(model: GalleryModel, collectionViewLayout: UICollectionViewLayout = GalleryGridLayout()) {
        self.model = model
        self.collectionViewLayout = collectionViewLayout
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)

        super.init(nibName: nil, bundle: nil)
        self.model.subscribe(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSubviews()
        self.model.fetchInitialData()
        self.title = "Gallery App"
        self.view.backgroundColor = .systemBackground
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Private methods

    @objc
    private func refreshPhotos() {
        self.model.refresh()
    }

    private func reloadData() {
        let layout = self.collectionViewLayout
        (layout as? GalleryGridLayout)?.photos = self.model.photos
        collectionView.collectionViewLayout = layout
        collectionView.reloadData()
    }

    private func setupSubviews() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: Constants.photoCellReuseIdentifier)
        collectionView.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: Constants.loadingFooterReuseIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        refreshControl.layer.zPosition = -1
        refreshControl.addTarget(self, action: #selector(refreshPhotos), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        let safeAreaLayoutGuide = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension GalleryViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        self.model.photos.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.model.photos[safe:section]?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = Constants.photoCellReuseIdentifier
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PhotoCell else {
            print("Error: Failed to dequeue a collection view cell with reuse identifier: \(reuseIdentifier) at indexPath: \(indexPath)")
            return UICollectionViewCell()
        }

        guard let photo = self.model.photos[safe: indexPath.section]?[safe: indexPath.item] else {
            print("Error: Photo not found at indexPath: \(indexPath)")
            return UICollectionViewCell()
        }

        cell.configure(with: photo)
        cell.showSkeleton()
        cell.dataTask = self.model.getImage(forPhoto: photo) { image, fromCache in
            DispatchQueue.main.async {
                if let updatedCell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
                    updatedCell.updateImage(image, animated: !fromCache)
                }
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionView.elementKindSectionFooter,
           let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Constants.loadingFooterReuseIdentifier, for: indexPath) as? LoadingFooterView {
            footer.activityIndicator.startAnimating()
            return footer
        }

        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension GalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let currentSection = self.model.photos[safe:indexPath.section] else { return }

        let isLastSection = indexPath.section == self.model.photos.count - 1
        let isLastItemInSection = indexPath.item == currentSection.count - 1
        let shouldLoadMore = isLastSection && isLastItemInSection

        if shouldLoadMore {
            self.model.fetchNextData()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let photo = self.model.photos[safe: indexPath.section]?[safe: indexPath.item],
            let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell
        else { return }

        self.selectedCellFrame = cell.convert(cell.bounds, to: nil)
        self.selectedCell = cell

        self.showFullScreenViewController(photo: photo, preview: cell.image, imageProvider: self.model.photoProvider)
    }

    func showFullScreenViewController(photo: Photo, preview: UIImage?, imageProvider: ImageProvider) {
        let fullScreenVC = FullScreenImageViewController(photo: photo, preview: preview, imageProvider: imageProvider)
        fullScreenVC.cornerRadius = PhotoCell.cornerRadius
        fullScreenVC.modalPresentationStyle = .overFullScreen
        fullScreenVC.transitioningDelegate = self

        present(fullScreenVC, animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        Constants.footerLoadingIndicatorSize
    }
}

// MARK: - GalleryModelSubscriber

extension GalleryViewController: GalleryModelSubscriber {
    func requestDidFail(_ model: any GalleryModel, error: Error) {
        print("DEBUG: Error: \(error.localizedDescription)")

        guard let apiError = error as? APIError else { return }
        if apiError.isAuthorizationError {
            self.dismissSelf()
        }
    }

    func dismissSelf() {
        if let dismissHandler {
            dismissHandler()
        } else {
            self.dismiss(animated: true)
        }
    }

    func modelDidUpdate(_ model: any GalleryModel) {
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
            self.reloadData()
        }
    }

    func loadedNewData(_ model: any GalleryModel, startIndex: Int, endIndex: Int) {
        let indexPaths = (startIndex..<endIndex).map { IndexPath(item: $0, section: 0) }
        DispatchQueue.main.async {
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: indexPaths)
            }, completion: nil)
        }
    }

    func loadedNewDataSection(_ model: any GalleryModel, newSectionIndex: Int) {
        DispatchQueue.main.async {
            (self.collectionView.collectionViewLayout as? GalleryGridLayout)?.photos = self.model.photos
            self.collectionView.insertSections(IndexSet(integer: newSectionIndex))
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension GalleryViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard
            let selectedCellFrame,
            presented is FullScreenImageViewController
        else { return nil }

        return ImageTransitionAnimatorPresent(cell: self.selectedCell, startingFrame: selectedCellFrame, cornerRadius: PhotoCell.cornerRadius)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard
            let selectedCellFrame,
            dismissed is FullScreenImageViewController
        else { return nil }

        return ImageTransitionAnimatorDismiss(cell: self.selectedCell, startingFrame: selectedCellFrame, cornerRadius: PhotoCell.cornerRadius)
    }
}
