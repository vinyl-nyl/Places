//
//  LoginViewModel.swift
//  Places
//
//  Created by junil on 5/9/24.
//

import SwiftUI
import Firebase
import CryptoKit
import AuthenticationServices
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var userUID: String
    var userEmail: String
    var userProfileURL: URL
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case userUID
        case userEmail
        case userProfileURL
    }
}

class LoginViewModel: ObservableObject {
    // MARK: View Properties
    @Published var mobileNo: String = ""
    @Published var otpCode: String = ""
    
    @Published var CLIENT_CODE: String = ""
    @Published var showOTPField: Bool = false
    
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: App Log Status
    @AppStorage("log_status") var logStatus: Bool = false
    
    // MARK: Apple Sign in Properties
    @Published var nonce = ""
    
    // MARK: Handling Error
    func handleError(error: Error) async {
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
    
    // MARK: Apple Sign in API
    func appleAuthenticate(credential: ASAuthorizationAppleIDCredential) {
        
        // getting Token...
        guard let token = credential.identityToken else {
            
            print("error with firebase")
            return
        }
        
        // Token String...
        guard let tokenString = String(data: token, encoding: .utf8) else {
            
            print("error with firebase")
            return
        }
        
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
        
        Auth.auth().signIn(with: firebaseCredential) { (result, err) in
            
            if let error = err {
                print(error.localizedDescription)
                return
            }
            
            // User Successfully Logged Into Firebase
            print("Logged In Success")
            withAnimation(.easeInOut){self.logStatus = true}
        }
    }
    
    // MARK: Logging Google User into Firebase
//    func logGoogleUser(user: GIDGoogleUser) {
//        Task {
//            do {
//                guard let idToken = user.authentication.idToken else{return}
//                let accessToken = user.authentication.accessToken
//                
//                let credential = OAuthProvider.credential(withProviderID: idToken, accessToken: accessToken)
//                
//                try await Auth.auth().signIn(with: credential)
//                
//                print("Success Google")
//                await MainActor.run(body: {
//                    withAnimation(.easeInOut) {logStatus = true}
//                })
//            } catch {
//                await handleError(error: error)
//            }
//        }
//    }
}

// MARK: Extensions
extension UIApplication {
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Root Controller
    func rootController() -> UIViewController {
        guard let window = connectedScenes.first as? UIWindowScene else { return .init() }
        guard let viewcontroller = window.windows.last?.rootViewController else { return .init() }
        
        return viewcontroller
    }
}

// MARK: Apple Sign in Helpers
func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

// MARK: helpers for Apple Login With Firebase
func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus\(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}
