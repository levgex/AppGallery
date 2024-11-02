//
//  SkeletonView.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class SkeletonView: UIView {

    private enum Constants {
        static let shimmerAnimationKey = "shimmer"
        static let animationKeyPath = "shimmer"
    }

    // MARK: - Private properties

    private let gradientLayer = CAGradientLayer()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    // MARK: - Override methods

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = bounds
    }

    // MARK: - Private methods

    private func startShimmerAnimation() {
        let animation = CABasicAnimation(keyPath: Constants.animationKeyPath)
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        self.gradientLayer.add(animation, forKey: Constants.shimmerAnimationKey)
    }

    private func stopShimmerAnimation() {
        self.gradientLayer.removeAnimation(forKey: Constants.shimmerAnimationKey)
    }

    private func setupGradient() {
        self.gradientLayer.startPoint = CGPoint(x: -1.0, y: 0.5)
        self.gradientLayer.endPoint = CGPoint(x: 2.0, y: 0.5)

        self.gradientLayer.colors = [
            UIColor.lightGray.withAlphaComponent(0.6).cgColor,
            UIColor.lightGray.withAlphaComponent(0.3).cgColor,
            UIColor.lightGray.withAlphaComponent(0.6).cgColor
        ]

        self.gradientLayer.locations = [0.0, 0.5, 1.0]
        self.layer.addSublayer(self.gradientLayer)

        self.startShimmerAnimation()
    }
}
