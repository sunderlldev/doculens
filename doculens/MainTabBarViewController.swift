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
        showLoginIfFirstTime()
        setupFAB()
    }
    
    func showLoginIfFirstTime() {

        let alreadyShown = UserDefaults.standard.bool(forKey: "loginModalShown")
        if alreadyShown { return }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(
            withIdentifier: "LoginVC"
        )

        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)

        UserDefaults.standard.set(true, forKey: "loginModalShown")
    }


    private func setupFAB() {
        fabButton.setImage(UIImage(systemName: "plus"), for: .normal)
        fabButton.backgroundColor = .accent
        fabButton.tintColor = .white
        fabButton.layer.cornerRadius = 28
        fabButton.translatesAutoresizingMaskIntoConstraints = false
        
        fabButton.addTarget(self, action: #selector(fabButtonTapped), for: .touchUpInside)
        
        view.addSubview(fabButton)
        
        NSLayoutConstraint.activate([
            fabButton.widthAnchor.constraint(equalToConstant: 56),
            fabButton.heightAnchor.constraint(equalToConstant: 56),
            fabButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            fabButton.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: -16)
        ])
    }
    
    @objc private func fabButtonTapped() {
        let menu = UIAlertController(
            title: "Nuevo Documento",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        menu.addAction(UIAlertAction(
            title: "Tomar foto",
            style: .default
        ) { _ in
            self.abrirCamara()
            print("Tomar foto")
        })
        
        menu.addAction(UIAlertAction(
            title: "Importar PDF",
            style: .default
        ) { _ in
            self.abrirFiles()
            print("Importar PDF")
        })
        
        menu.addAction(UIAlertAction(
            title: "Importar Imagen",
            style: .default
        ) { _ in
            self.abrirGaleria()
            print("Importar Imagen")
        })
        
        menu.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        present(menu, animated: true)
    }
}
