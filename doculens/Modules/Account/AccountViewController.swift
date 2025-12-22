//
//  AccountViewController.swift
//  doculens
//
//  Created by sunderll on 4/12/25.
//

import FirebaseAuth
import UIKit

class AccountViewController: UIViewController {

    @IBOutlet weak var tfUsuario: UITextField!

    @IBOutlet weak var tfCorreoUsuario: UITextField!

    @IBOutlet weak var logoutButton: UIButton!

    @IBOutlet weak var loginButton: UIButton!

    @IBOutlet weak var cambiarNombreUsuarioButton: UIButton!

    private var authListener: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(invitadoCambio),
            name: .invitadoActualizado,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        authListener = Auth.auth().addStateDidChangeListener { _, user in
            self.actualizarUI()
        }
    }

   override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    @objc func invitadoCambio() {
        actualizarUI()
    }

    func presentarLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(
            withIdentifier: "LoginViewController"
        )
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }

    func actualizarUI() {
        let user = Auth.auth().currentUser
        let isLoggedIn = user != nil

        if isLoggedIn {
            tfUsuario.text = user?.displayName ?? ""
            tfCorreoUsuario.text = user?.email ?? ""
        } else {
            tfUsuario.text =
                UserDefaults.standard.string(forKey: "userName") ?? ""
            tfCorreoUsuario.text = ""
        }

        tfUsuario.isUserInteractionEnabled = isLoggedIn
        tfCorreoUsuario.isUserInteractionEnabled = false
        tfUsuario.alpha = isLoggedIn ? 1.0 : 0.5
        tfCorreoUsuario.alpha = 0.6

        loginButton.isHidden = isLoggedIn
        cambiarNombreUsuarioButton.isHidden = !isLoggedIn
        logoutButton.isHidden = !isLoggedIn
    }

    @IBAction func cambiarNombreUsuarioButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Cambiar nombre",
            message: "Ingresa tu nuevo nombre de usuario",
            preferredStyle: .alert
        )

        alert.addTextField {
            $0.placeholder = "Nuevo nombre"
            $0.autocapitalizationType = .words
            $0.text = self.tfUsuario.text
        }

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alert.addAction(
            UIAlertAction(title: "Guardar", style: .default) { _ in
                let nuevoNombre = alert.textFields?.first?.text ?? ""

                if nuevoNombre.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.alerta(
                        titulo: "Error",
                        mensaje: "El nombre no puede estar vacío"
                    )
                    return
                }

                self.guardarNuevoNombre(nuevoNombre)
            }
        )

        present(alert, animated: true)
    }

    func guardarNuevoNombre(_ nombre: String) {
        guard let usuario = Auth.auth().currentUser else { return }

        let request = usuario.createProfileChangeRequest()
        request.displayName = nombre

        request.commitChanges { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alerta(
                        titulo: "Error",
                        mensaje: error.localizedDescription
                    )
                } else {
                    self.actualizarUI()
                    self.alerta(
                        titulo: "Nombre actualizado",
                        mensaje:
                            "Tu nombre de usuario se actualizó correctamente"
                    )
                }
            }
        }
    }

    func alerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(
            title: titulo,
            message: mensaje,
            preferredStyle: .alert
        )
        alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alerta, animated: true)
    }

    @IBAction func cerrarSesionButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Cerrar sesión",
            message: "¿Estás seguro de que deseas cerrar sesión?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alert.addAction(
            UIAlertAction(title: "Sí, cerrar sesión", style: .destructive) {
                _ in
                self.cerrarSesion()
            }
        )

        present(alert, animated: true)
    }

    func cerrarSesion() {
        do {
            try Auth.auth().signOut()

            tfUsuario.text = ""
            tfCorreoUsuario.text = ""

            alerta(
                titulo: "Sesion cerrada",
                mensaje: "Has cerrado sesion correctamente"
            )
        } catch {
            alerta(
                titulo: "Error",
                mensaje: "No se pudo cerrar sesion correctamente"
            )
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
