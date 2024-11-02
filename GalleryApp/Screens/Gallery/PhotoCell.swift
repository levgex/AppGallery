//
//  PhotoCell.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    static let cornerRadius = 16.0

    // MARK: - Properties

    var dataTask: URLSessionDataTask?

    var image: UIImage? {
        self.imageView.image
    }

    // MARK: - Private properties

    private let imageView: UIImageView = {
        let item = UIImageView()
        item.layer.cornerRadius = cornerRadius
        item.clipsToBounds = true
        item.contentMode = .scaleAspectFit
        item.alpha = 0
        return item
    }()

    private let authorLabel: UILabel = {
        let item = UILabel()
        item.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        item.textColor = .white
        item.textAlignment = .center
        return item
    }()

    private let skeletonView: SkeletonView = {
        let item = SkeletonView()
        item.layer.cornerRadius = cornerRadius
        item.clipsToBounds = true
        item.isHidden = true
        return item
    }()

    private let gradient: GradientView = {
        let item = GradientView()
        item.layer.cornerRadius = cornerRadius
        return item
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        showSkeleton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        showSkeleton()
    }

    // MARK: - Override methods

    override func prepareForReuse() {
        self.configure(with: nil)
        self.updateImage(nil)
        self.dataTask?.cancel()
        self.dataTask = nil
    }

    // MARK: - Methods

    func configure(with photo: Photo?) {
        authorLabel.text = photo?.photographer ?? ""
    }

    func updateImage(_ image: UIImage?, animated: Bool = true) {
        self.imageView.image = image
        guard image != nil else {
            showSkeleton()
            return
        }
        self.showImageAndHideSkeleton(animated: animated)
    }

    func showSkeleton() {
        self.imageView.alpha = 0
        self.skeletonView.alpha = 1
        self.skeletonView.isHidden = false
    }

    func showImage() {
        self.imageView.alpha = 1
    }

    func hideImage() {
        self.imageView.alpha = 0
    }

    func showContent(animated: Bool = false) {
        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.showImage()
            self.authorLabel.alpha = 1
            self.gradient.alpha = 1
        }
    }

    func hideContent(animated: Bool = false) {
        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.hideImage()
            self.authorLabel.alpha = 0
            self.gradient.alpha = 0
        }
    }

    // MARK: - Private methods

    private func showImageAndHideSkeleton(animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.6 : 0.0, animations: {
            self.skeletonView.alpha = 0.0
            self.imageView.alpha = 1
            self.contentView.backgroundColor = .systemBackground
        }) { _ in
            self.skeletonView.isHidden = true
        }
    }

    private func setupViews() {
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.gradient.translatesAutoresizingMaskIntoConstraints = false
        self.authorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.skeletonView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.gradient)
        self.contentView.addSubview(self.authorLabel)
        self.contentView.addSubview(self.skeletonView)

        self.contentView.backgroundColor = .systemBackground

        self.contentView.layer.cornerRadius = Self.cornerRadius
        self.contentView.layer.masksToBounds = false
        self.contentView.layer.shadowColor = UIColor.black.cgColor
        self.contentView.layer.shadowOpacity = 0.3
        self.contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.contentView.layer.shadowRadius = 3
        self.contentView.layer.shadowPath = UIBezierPath(roundedRect: self.contentView.bounds, cornerRadius: self.contentView.layer.cornerRadius).cgPath

        NSLayoutConstraint.activate([
            self.imageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.imageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),

            self.authorLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.authorLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8),
            self.authorLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10),

            self.skeletonView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.skeletonView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.skeletonView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.skeletonView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),

            self.gradient.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.gradient.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.gradient.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.gradient.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
        ])
    }
}
