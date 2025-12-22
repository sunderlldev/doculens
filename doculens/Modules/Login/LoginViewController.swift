//
//  LoginViewController.swift
//  doculens
//
//  Created by sunderll on 20/12/25.
//

import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var withinAccountButton: UIButton!

    @IBOutlet weak var loginWithGoogleButton: UIButton!

    @IBOutlet weak var appleButtonContainer: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupAppleButton()
    }

    // MARK: - Apple Sign In Setup
    private func setupAppleButton() {
        appleButtonContainer.subviews.forEach { $0.removeFromSuperview() }

        let btn = ASAuthorizationAppleIDButton(type: .continue, style: .black)
        btn.cornerRadius = 10
        btn.frame = appleButtonContainer.bounds
        btn.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        btn.addTarget(
            self,
            action: #selector(handleAppleClick),
            for: .touchUpInside
        )
        appleButtonContainer.addSubview(btn)
    }

    @objc func handleAppleClick() {
        let request = AuthService.shared.appleSignInFlow()
        let controller = ASAuthorizationController(authorizationRequests: [
            request
        ])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Google Sign In Logica
    @IBAction func loginWithGoogleButtonTapped(_ sender: UIButton) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Sin clientID")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(
            withPresenting: self
        ) { result, error in

            if let error = error {
                print("Google SignIn error:", error.localizedDescription)
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken
            else {
                print("No hay Google user")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken.tokenString,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase auth error:", error.localizedDescription)
                    return
                }

                print("Google login exitoso:", authResult?.user.uid ?? "")

                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Bienvenido",
                        message: "Has iniciado sesión correctamente",
                        preferredStyle: .alert
                    )

                    alert.addAction(
                        UIAlertAction(title: "Continuar", style: .default) {
                            _ in
                            self.dismiss(animated: true)
                        }
                    )

                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Invitado (Sin cuenta)
    @IBAction func withinAccountTapped(_ sender: UIButton) {
        showNameAlert()
    }

    func showNameAlert() {
        let alerta = UIAlertController(
            title: "Como te llamas?",
            message: "Usaremos tu nombre para personalizar tu experiencia.",
            preferredStyle: .alert
        )
        alerta.addTextField { $0.placeholder = "Tu nombre" }
        alerta.addAction(
            UIAlertAction(title: "Continuar", style: .default) { _ in
                let nombre = alerta.textFields?.first?.text ?? ""
                UserDefaults.standard.set(nombre, forKey: "userName")

                NotificationCenter.default.post(
                    name: .invitadoActualizado,
                    object: nil
                )
                
                DispatchQueue.main.async {
                    let alerta = UIAlertController(
                        title: "Bienvenido",
                        message: "Bienvenido, \(nombre)!",
                        preferredStyle: .alert
                    )

                    alerta.addAction(
                        UIAlertAction(title: "Continuar", style: .default) {
                            _ in
                            self.dismiss(animated: true)
                        }
                    )
                    
                    self.present(alerta, animated: true)
                }
            }
        )
        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alerta, animated: true)
    }

    private func navigateToMainApp() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        self.dismiss(animated: true)
    }
}

// MARK: - Apple Auth Delegates
extension LoginViewController: ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    func presentationAnchor(for controller: ASAuthorizationController)
        -> ASPresentationAnchor
    {
        return self.view.window!
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        AuthService.shared.handleAppleAuthorization(auth: authorization) {
            result in
            switch result {
            case .success(let authResult):
                print("Login exitoso: \(authResult.user.uid)")
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Bienvenido",
                        message: "Has iniciado sesión correctamente",
                        preferredStyle: .alert
                    )

                    alert.addAction(
                        UIAlertAction(title: "Continuar", style: .default) {
                            _ in
                            self.dismiss(animated: true)
                        }
                    )

                    self.present(alert, animated: true)
                }
            case .failure(let error):
                print("Error en login: \(error.localizedDescription)")
            }
        }
    }
}
