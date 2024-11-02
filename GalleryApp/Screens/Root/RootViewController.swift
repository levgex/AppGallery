//
//  RootViewController.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class RootViewController: UIViewController {

    // MARK: - Private properties

    private let errorLabel: UILabel = {
        let item = UILabel()
        item.text = "Pexels API Key Not Found. \nTo access the gallery, please enter a valid API key."
        item.numberOfLines = 0
        item.textAlignment = .center
        item.textColor = .gray
        item.isHidden = true

        return item
    }()

    private let actionButton: UIButton = {
        let item = UIButton()
        var configuration = UIButton.Configuration.gray()
        configuration.title = "Enter API key"
        item.configuration = configuration
        item.isHidden = true

        return item
    }()

    private var observer: NSObjectProtocol?
    private var childController: UIViewController?

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.restoreApiKey { apiKey in
            DispatchQueue.main.async {
                guard let apiKey else {
                    self.showError()
                    return
                }
                NetworkService.shared.configureWith(apiKey: apiKey)
                self.showGalleryViewController()
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeCurrentObserver()
    }
}

// MARK: - Private methods

extension RootViewController {

    @objc
    func actionButtonTapped() {
        self.requestApiKey()
    }

    func requestApiKey() {
        self.showRequestApiKeyAlert { apiKey in
            if let apiKey = apiKey {
                NetworkService.shared.configureWith(apiKey: apiKey)
                self.saveApiKey(apiKey)
                self.showGalleryViewController()
            } else {
                self.showError()
            }
        }
        self.hideError()
    }

    func showError() {
        self.errorLabel.isHidden = false
        self.actionButton.isHidden = false
    }

    func hideError() {
        self.errorLabel.isHidden = true
        self.actionButton.isHidden = true
    }

    func saveApiKey(_ apiKey: String) {
        KeyChainStorageManager.saveStringValue(apiKey, forKey: KeyChainStorageManager.apiKeyKeychainKey)
    }

    func restoreApiKey(completion: @escaping (String?) -> Void) {
        KeyChainStorageManager.getStringValue(forKey: KeyChainStorageManager.apiKeyKeychainKey, completion: completion)
    }

    func setupSubviews() {
        self.view.backgroundColor = .systemBackground
        self.errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.actionButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(errorLabel)
        self.view.addSubview(actionButton)

        self.actionButton.addTarget(self, action: #selector(self.actionButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            self.errorLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.errorLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.actionButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.actionButton.topAnchor.constraint(equalTo: self.errorLabel.bottomAnchor, constant: 24),
        ])
    }

    func showGalleryViewController() {
        let urlFactory = GalleryUrlFactory(endpoint: .curatedPhotos)
        let photoProvider = GalleryPhotoProvider(urlFactory: urlFactory)
        let model = GalleryModelDefault(photoProvider: photoProvider)
        let galleryViewController = GalleryViewController(model: model)
        galleryViewController.dismissHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.dismissChildController()
                self?.showError()
            }
        }
        let galleryNavigationViewController = UINavigationController(rootViewController: galleryViewController)
        self.showChildController(galleryNavigationViewController)
    }

    func showChildController(_ childController: UIViewController) {
        self.childController = childController
        self.addChild(childController)
        self.view.addSubview(childController.view)
        childController.didMove(toParent: self)
    }

    func dismissChildController() {
        guard let childController = self.childController else { return }

        UIView.animate(withDuration: 0.3, animations: {
            childController.view.alpha = 0
        }) { _ in
            childController.willMove(toParent: nil)
            childController.view.removeFromSuperview()
            childController.removeFromParent()
            self.childController = nil
        }
    }

    func showRequestApiKeyAlert(completion: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "Enter API Key", message: "Please enter your Pexels API key to access the app's features.", preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "API Key"
            textField.isSecureTextEntry = true
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let apiKey = alertController.textFields?.first?.text, !apiKey.isEmpty {
                completion(apiKey)
            } else {
                completion(nil)
            }
            self.removeCurrentObserver()
        }
        saveAction.isEnabled = false

        if let textField = alertController.textFields?.first {
            self.observer = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { _ in
                saveAction.isEnabled = !(textField.text?.isEmpty ?? true)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.removeCurrentObserver()
            completion(nil)
        }

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true)
    }

    func removeCurrentObserver() {
        guard let observer else { return }
        NotificationCenter.default.removeObserver(observer)
        self.observer = nil
    }
}
