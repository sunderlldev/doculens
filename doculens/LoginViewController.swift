//
//  LoginViewController.swift
//  doculens
//
//  Created by sunderll on 20/12/25.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var withinAccountButton: UIButton!
    
    @IBOutlet weak var loginWithGoogleButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    @objc func close() {
        dismiss(animated: true)
    }
    
    func showNameAlert() {
        let alert = UIAlertController(
            title: "¿Cómo te llamas?",
            message: "Usaremos tu nombre para personalizar tu experiencia.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Tu nombre"
            textField.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(
            title: "Continuar",
            style: .default
        ) { _ in
            let name = alert.textFields?.first?.text ?? ""
            print("Nombre ingresado:", name)

            self.dismiss(animated: true)
        })

        alert.addAction(UIAlertAction(
            title: "Cancelar",
            style: .cancel
        ))

        present(alert, animated: true)
    }

    @IBAction func withinAccountTapped(_ sender: UIButton) {
        showNameAlert()
    }
}
