//
//  MainTabBarViewController.swift
//  doculens
//
//  Created by sunderll on 4/12/25.
//

import UIKit

class MainTabBarViewController: UITabBarController {

    private let fabButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFAB()
        alertaDocumentoCreado()
    }

    private func alertaDocumentoCreado() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(documentoCreado),
            name: .documentoCreado,
            object: nil
        )
    }

    @objc private func documentoCreado() {
        let alerta = UIAlertController(
            title: "Documento creado",
            message: "El documento se escaneo correctamente",
            preferredStyle: .alert
        )
        
        alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
        
        // Para evitar multiples alertas
        if presentedViewController == nil {
            present(alerta, animated: true)
        }
    }

    private func setupFAB() {
        fabButton.setImage(UIImage(systemName: "plus"), for: .normal)
        fabButton.backgroundColor = .accent
        fabButton.tintColor = .white
        fabButton.layer.cornerRadius = 28
        fabButton.translatesAutoresizingMaskIntoConstraints = false

        fabButton.addTarget(
            self,
            action: #selector(fabButtonTapped),
            for: .touchUpInside
        )

        view.addSubview(fabButton)

        NSLayoutConstraint.activate([
            fabButton.widthAnchor.constraint(equalToConstant: 56),
            fabButton.heightAnchor.constraint(equalToConstant: 56),
            fabButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24
            ),
            fabButton.bottomAnchor.constraint(
                equalTo: tabBar.topAnchor,
                constant: -16
            ),
        ])
    }

    @objc private func fabButtonTapped() {
        let menu = UIAlertController(
            title: "Nuevo Documento",
            message: nil,
            preferredStyle: .actionSheet
        )

        menu.addAction(
            UIAlertAction(
                title: "Tomar foto",
                style: .default
            ) { _ in
                self.abrirCamara()
            }
        )

        menu.addAction(
            UIAlertAction(
                title: "Importar PDF",
                style: .default
            ) { _ in
                self.abrirFiles()
            }
        )

        menu.addAction(
            UIAlertAction(
                title: "Importar Imagen",
                style: .default
            ) { _ in
                self.abrirGaleria()
            }
        )

        menu.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        present(menu, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
