//
//  GradientView.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class GradientView: UIView {

    private enum Constants {
        static let defaultColors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        static let defaultLocations: [NSNumber] = [0.6, 1.0]
    }

    // MARK: - Private properties

    private let gradientLayer = CAGradientLayer()
    private let colors: [CGColor]
    private let locations: [NSNumber]

    // MARK: - Initialization

    init(frame: CGRect = .zero, colors: [CGColor] = Constants.defaultColors, locations: [NSNumber] = Constants.defaultLocations) {
        self.colors = colors
        self.locations = locations

        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = self.bounds
    }

    // MARK: - Private methods

    private func setupViews() {
        self.gradientLayer.colors = self.colors
        self.gradientLayer.locations = self.locations
        self.gradientLayer.frame = self.bounds
        self.clipsToBounds = true

        self.layer.insertSublayer(self.gradientLayer, at: 0)
    }
}
