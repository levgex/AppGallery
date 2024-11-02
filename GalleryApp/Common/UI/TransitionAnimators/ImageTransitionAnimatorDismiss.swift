//
//  ImageTransitionAnimatorDismiss.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class ImageTransitionAnimatorDismiss: NSObject, UIViewControllerAnimatedTransitioning {

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
        guard let dismissController = transitionContext.viewController(forKey: .from) as? ImageViewContainer,
              let image = dismissController.imageView.image
        else {
            transitionContext.completeTransition(false)
            return
        }

        dismissController.imageView.alpha = 0
        containerView.backgroundColor = .clear

        let initialFrame = dismissController.imageView.frame
        let finalFrame = startingFrame

        let snapshot = SnapshotFactory.makeSnapshot(frame: initialFrame, image: image, cornerRadius: cornerRadius)
        containerView.addSubview(snapshot)


        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            snapshot.frame = finalFrame
            dismissController.rootView.alpha = 0
        }) { _ in
            self.cell?.showImage()
            snapshot.alpha = 0
            self.cell?.showContent(animated: true)

            snapshot.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
}
