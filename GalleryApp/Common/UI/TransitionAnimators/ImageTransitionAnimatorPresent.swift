//
//  ImageTransitionAnimatorPresent.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class ImageTransitionAnimatorPresent: NSObject, UIViewControllerAnimatedTransitioning {

    // MARK: - Private properties

    private let startingFrame: CGRect
    private let cornerRadius: CGFloat
    private let cell: PhotoCell?

    // MARK: - Initialization

    init(cell: PhotoCell?, startingFrame: CGRect, cornerRadius: CGFloat) {
        self.cell = cell
        self.startingFrame = startingFrame
        self.cornerRadius = cornerRadius
    }

    // MARK: - Methods

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let toView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }
        guard
            let fullScreenVC = transitionContext.viewController(forKey: .to) as? ImageViewContainer,
            let image = fullScreenVC.imageView.image
        else {
            containerView.addSubview(toView)
            transitionContext.completeTransition(false)
            return
        }

        let initialFrame = startingFrame
        let finalFrame = fullScreenVC.imageView.frame

        let snapshot = SnapshotFactory.makeSnapshot(frame: initialFrame, image: image, cornerRadius: cornerRadius)
        containerView.addSubview(toView)
        containerView.addSubview(snapshot)

        toView.alpha = 0
        fullScreenVC.imageView.isHidden = true
        cell?.hideContent()

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            snapshot.frame = finalFrame
            toView.alpha = 1
            snapshot.layer.cornerRadius = 0
        }) { _ in
            fullScreenVC.imageView.isHidden = false
            snapshot.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
}
