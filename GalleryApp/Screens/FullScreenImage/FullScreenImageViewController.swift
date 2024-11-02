//
//  FullScreenImageViewController.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class FullScreenImageViewController: UIViewController, ImageViewContainer {

    private enum Constants {
        static let zoomScaleDefault = 1.0
        static let zoomScaleDoubleTap = 2.0
        static let zoomScaleDismissThreshold = 0.8
        static let zoomScaleMinimum = 0.2
        static let zoomScaleMaximum = 3.0

        static let moveGestureDismissThreshold = 100.0

        static let backgroundColor = UIColor.black
    }

    // MARK: - Properties

    var cornerRadius = 0.0
    let imageView = UIImageView()

    var rootView: UIView {
        self.view
    }

    // MARK: - Private properties

    private let scrollView = UIScrollView()
    private var originalCenter: CGPoint = .zero
    private var originalSize: CGSize = .zero

    private var preview: UIImage?
    private var photo: Photo?
    private let imageProvider: ImageProvider

    private var imageRatio: CGFloat? {
        guard let image = self.imageView.image else { return nil }
        return image.size.height / image.size.width
    }

    // MARK: - Initializations

    init(photo: Photo, preview: UIImage?, imageProvider: ImageProvider) {
        self.photo = photo
        self.preview = preview
        self.imageProvider = imageProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .black
        self.setupScrollView()
        self.setupImageView()
        self.setupGestures()

        self.downloadImage()
    }
}

// MARK: - UIScrollViewDelegate

extension FullScreenImageViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)

        self.imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                                        y: scrollView.contentSize.height * 0.5 + offsetY)

        let alpha = max(0, scrollView.zoomScale)
        self.view.backgroundColor = Constants.backgroundColor.withAlphaComponent(alpha)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if scale < Constants.zoomScaleDismissThreshold {
            self.dismiss(animated: true, completion: nil)
        } else if scale < Constants.zoomScaleDefault {
            scrollView.setZoomScale(Constants.zoomScaleDefault, animated: true)
        }
    }
}

// MARK: - Private

private extension FullScreenImageViewController {

    func downloadImage() {
        guard let url = self.getUrl(forPhoto: self.photo) else { return }

        self.imageProvider.fetchImage(from: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self.imageView.image = image
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                }
            }
        }
    }

    func getUrl(forPhoto photo: Photo?) -> URL? {
        guard let photo else { return nil }
        return URL(string: photo.src.original)
    }

    func setupScrollView() {
        self.scrollView.frame = view.bounds
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = Constants.zoomScaleMinimum
        self.scrollView.maximumZoomScale = Constants.zoomScaleMaximum
        self.scrollView.zoomScale = Constants.zoomScaleDefault
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.alwaysBounceHorizontal = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false

        self.view.addSubview(self.scrollView)
    }

    func setupImageView() {
        if let url = self.getUrl(forPhoto: self.photo),
           let cachedImage = self.imageProvider.getCachedImage(forURL: url) {
            self.imageView.image = cachedImage
        } else {
            self.imageView.image = self.preview
        }

        self.imageView.contentMode = .scaleAspectFit

        var imageViewFrame = scrollView.bounds
        if let imageRatio {
            imageViewFrame = CGRect(origin: scrollView.bounds.origin, size: CGSize(width: self.scrollView.bounds.width, height: self.scrollView.bounds.width * imageRatio))
        }
        self.imageView.frame = imageViewFrame
        self.imageView.center = scrollView.center
        self.imageView.isUserInteractionEnabled = true
        self.imageView.clipsToBounds = true
        self.scrollView.addSubview(imageView)

        self.originalCenter = imageView.center
        self.originalSize = imageView.bounds.size
    }

    func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        self.scrollView.addGestureRecognizer(doubleTapGesture)
    }

    @objc
    func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: imageView)

        if self.scrollView.zoomScale == Constants.zoomScaleDefault {
            let zoomRect = self.zoomRectForScale(scale: Constants.zoomScaleDoubleTap, center: tapPoint)
            self.scrollView.zoom(to: zoomRect, animated: true)
        } else {
            self.scrollView.setZoomScale(Constants.zoomScaleDefault, animated: true)
        }
    }

    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        let width = scrollView.bounds.size.width / scale
        let height = scrollView.bounds.size.height / scale
        let originX = max(center.x - width / 2.0, 0)
        let originY = max(center.y - height / 2.0, 0)

        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    @objc
    func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard self.scrollView.zoomScale == Constants.zoomScaleDefault
        else { return }
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            self.imageView.center = CGPoint(x: self.originalCenter.x + translation.x, y: self.originalCenter.y + translation.y)
            let scale = min(1 - abs(translation.y) / view.bounds.height, 1 - abs(translation.x) / view.bounds.width)
            self.imageView.bounds.size = CGSize(width: self.originalSize.width * scale, height: self.originalSize.height * scale)
            self.imageView.layer.cornerRadius = self.cornerRadius * ((1 - scale) * 5)
            self.view.backgroundColor = UIColor.black.withAlphaComponent(scale)

        case .ended, .cancelled:
            if max(abs(translation.y), abs(translation.x)) > Constants.moveGestureDismissThreshold {
                self.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.imageView.center = self.originalCenter
                    self.imageView.bounds.size = self.originalSize
                    self.view.backgroundColor = .black
                    self.imageView.layer.cornerRadius = 0.0
                }
            }

        default:
            break
        }
    }
}
