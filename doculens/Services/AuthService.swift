//
//  AuthService.swift
//  doculens
//
//  Created by sunderll on 22/12/25.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

final class AuthService {
    static let shared = AuthService()
    private init() {}
    
    // Guardar nonce
    private var currentNonce: String?
    
    func appleSignInFlow() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        return request
    }
    
    func handleAppleAuthorization(auth: ASAuthorization, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            return
        }
        
        defer { self.currentNonce = nil }
        
        let credenciales = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        Auth.auth().signIn(with: credenciales) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }
    
    
    // MARK: - Helpers de seguridad (Criptografia)
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("No se pudo generar el nonce: \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let result = randomBytes.map { charset[Int($0) % charset.count] }

        return String(result)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
