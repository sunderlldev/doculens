//
//  ImageViewerViewController.swift
//  doculens
//
//  Created by sunderll on 22/12/25.
//

import UIKit

class ImageViewerViewController: UIViewController {

    var imageURL: URL!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        configurarNav()
        verImagen()
    }

    private func configurarNav() {
        title = "Imagen"

        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(cerrarVisor)
        )
    }

    private func verImagen() {
        let image = UIImage(contentsOfFile: imageURL.path)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(imageView)
    }

    @objc private func cerrarVisor() {
        dismiss(animated: true)
    }
}
