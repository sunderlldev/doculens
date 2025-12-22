//
//  OnboardingViewController.swift
//  doculens
//
//  Created by sunderll on 22/12/25.
//

import UIKit

class OnboardingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func presentarLogin() {
        let storyboard = UIStoryboard(name: "mMain", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }
}
