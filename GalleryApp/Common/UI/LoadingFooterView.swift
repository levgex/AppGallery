//
//  LoadingFooterView.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class LoadingFooterView: UICollectionReusableView {

    // MARK: - Properties

    let activityIndicator: UIActivityIndicatorView = {
        let item = UIActivityIndicatorView(style: .medium)
        item.translatesAutoresizingMaskIntoConstraints = false
        item.hidesWhenStopped = true

        return item
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupViews()
    }

    // MARK: - Private methods

    private func setupViews() {
        self.addSubview(self.activityIndicator)

        NSLayoutConstraint.activate([
            self.activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
