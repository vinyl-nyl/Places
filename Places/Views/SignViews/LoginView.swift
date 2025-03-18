//
//  LoginView.swift
//  Places
//
//  Created by junil on 4/16/24.
//

import SwiftUI

// MARK: Intergrating Apple Sign in
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

struct LoginView: View {
    // MARK: User Details
    @State var email: String = ""
    @State var password: String = ""
    
    // MARK: View Properties
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    
    @StateObject var loginModel: LoginViewModel = .init()
    
    // MARK: UserDefaults
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                (Text("\n이제")
                    .foregroundStyle(.indigo) +
                 Text("\n떠나볼까요?")
                    .foregroundStyle(.blue) +
                 Text("\n\n")
                    .foregroundStyle(.gray)
                )
                .font(.title)
                .fontWeight(.semibold)
                .lineSpacing(10)
                .padding(.top, 20)
                .padding(.trailing, 15)
                
                VStack {
                    // MARK: Custom TextField
                    TextField("이메일을 입력하세요", text: $email)
                        .textContentType(.emailAddress)
                        .border(1, .gray.opacity(0.5))
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                    
                    SecureField("비밀번호를 입력하세요", text: $password)
                        .textContentType(.emailAddress)
                        .border(1, .gray.opacity(0.5))
                    
                    Button("비밀번호 재설정", action: resetPassword)
                        .font(.callout)
                        .fontWeight(.medium)
                        .tint(.blue .opacity(0.8))
                        .hAlign(.trailing)
                        .padding(.bottom, 20)
                    
                    Button(action: loginUser) {
                        // MARK: Login Button
                        Text("Places에 로그인")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                            .hAlign(.center)
                            .fillView(.indigo)
                    }
                    .padding(.top, 10)
                }
                .padding(.leading, -30)
                .padding(.horizontal, 30)
                
                HStack {
                    Text("아직 계정이 없으신가요?")
                        .foregroundStyle(.gray)
                    Button("회원가입") {
                        createAccount.toggle()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(.blue .opacity(0.8))
                }
                .font(.callout)
                .hAlign(.trailing)
                .padding(.horizontal, 30)
                
                Text("소셜 계정으로 로그인")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                    .padding(.bottom, 10)
                    .padding(.leading, -30)
                
                HStack(spacing: 8) {
                    // MARK: Custom Apple Sign in Button
                    CustomButton()
                        .overlay {
                            SignInWithAppleButton { (request) in
                                loginModel.nonce = randomNonceString()
                                request.requestedScopes = [.email, .fullName]
                                request.nonce = sha256(loginModel.nonce)
                            } onCompletion: { (result) in
                                switch result {
                                case .success(let user):
                                    print("success")
                                    // do Login With Firebase...
                                    guard let credential = user.credential as? ASAuthorizationAppleIDCredential else {
                                        print("error with firebase")
                                        return
                                    }
                                    loginModel.appleAuthenticate(credential: credential)
                                case.failure(let error):
                                    print(error.localizedDescription)
                                }
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 55)
                            .blendMode(.overlay)
                        }
                        .clipped()
                    
                    // MARK: Custom Google Sign in Button
                    CustomButton(isGoogle: true)
                        .overlay {
                            // MARK: We Have Native Google Sign in Button
                        }
                        .clipped()
                }
                .padding(.leading, -30)
                .frame(maxWidth: .infinity)
            }
            .padding(.leading, 30)
            .padding(.vertical, 15)
            .overlay(content: {
                LoadingView(show: $isLoading)
            })
        }
        .alert(loginModel.errorMessage, isPresented: $loginModel.showError) {
        }
        .fullScreenCover(isPresented: $createAccount) {
            SignUpView()
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    func loginUser() {
        isLoading = true
        closeKeyboard()
        Task {
            do {
                // Withe the help of Swift Concurrency Auth can be done with Single Line
                try await Auth.auth().signIn(withEmail: email, password: password)
                print("User Found, login Successed")
                try await fetchUser()
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: If User if Found then Fetching User Data From Firestore
    func fetchUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else{return}
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        // MARK: UI Updating Must be Run On Main Thread
        await MainActor.run(body: {
            // Setting UserDefaults data and Changing App's Auth Status
            userUID = userID
            userNameStored = user.username
            logStatus = true
        })
    }
    
    func resetPassword() {
        Task {
            do {
                // Withe the help of Swift Concurrency Auth can be done with Single Line
                try await Auth.auth().sendPasswordReset(withEmail: email)
                print("Link Sent")
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: Displaying Errors VIA Alert
    func setError(_ error: Error)async {
        // MARK: UI Must be Updated on Main Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

// MARK: View Extensions For UI Building
extension View {
    // Closing All Active Keyboards
    func closeKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: Disabling with Opacity
    func disableWithOpacity(_ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
    
    func hAlign(_ alignment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    func vAlign(_ alignment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
    
    // MARK: Custom Border View With Padding
    func border(_ width: CGFloat, _ color: Color) -> some View {
        self
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(color, lineWidth: width)
            }
    }
    
    // MARK: Custom Fill View With Padding
    func fillView(_ color: Color) -> some View {
        self
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color)
            }
    }
}

// MARK: Make Apple and Google CustomButton
@ViewBuilder
func CustomButton(isGoogle: Bool = false) -> some View {
    HStack {
        Group {
            if isGoogle {
                Image("Google")
                    .resizable()
                    .renderingMode(.template)
            } else {
                Image(systemName: "applelogo")
                    .resizable()
                    .renderingMode(.template)
            }
        }
        .aspectRatio(contentMode: .fit)
        .frame(width: 25, height: 25)
        .frame(height: 45)
        
        Text("\(isGoogle ? "Google" : "Apple") 로그인")
            .font(.callout)
            .foregroundColor(.white)
            .lineLimit(1)
    }
    .foregroundColor(.white)
    .padding(.horizontal, 15)
    .background {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.black)
    }
}

// MARK: Make Sign Up View

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
