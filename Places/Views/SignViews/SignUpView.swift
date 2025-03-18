//
//  SignUpView.swift
//  Places
//
//  Created by junil on 5/21/24.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct SignUpView: View {
    @State var email: String = ""
    @State var password: String = ""
    @State var username: String = ""
    @State var repassword: String = ""
    @State var userProfilePicData: Data?
    
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    
    // MARK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                (Text("\n지금, Places와")
                    .foregroundStyle(.indigo) +
                 Text("\n새로운 여정을 시작해요")
                    .foregroundStyle(.blue) +
                 Text("\n")
                    .foregroundStyle(.gray)
                 )
                .font(.title)
                .fontWeight(.semibold)
                .lineSpacing(10)
                .padding(.top, 20)
                .padding(.trailing, 15)
                
                VStack {
                    ZStack {
                        if let userProfilePicData, let image = UIImage(data: userProfilePicData) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image("NullProfile")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: 85, height: 85)
                    .clipShape(Circle())
                    .contentShape(Circle())
                    .onTapGesture {
                        showImagePicker.toggle()
                    }
                    .padding(.top, 25)
                    
                    // MARK: Custom TextField
                    TextField("닉네임을 입력하세요", text: $username)
                        .textContentType(.emailAddress)
                        .border(1, .gray.opacity(0.5))
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                    
                    TextField("이메일을 입력하세요", text: $email)
                        .textContentType(.emailAddress)
                        .border(1, .gray.opacity(0.5))
                        .padding(.bottom, 10)
                    
                    SecureField("비밀번호를 입력하세요", text: $password)
                        .textContentType(.emailAddress)
                        .border(1, .gray.opacity(0.5))
                        .padding(.bottom, 10)
                    
                    SecureField("비밀번호 다시 입력하세요", text: $repassword)
                        .textContentType(.emailAddress)
                        .border(1, .gray.opacity(0.5))
                        .padding(.bottom, 20)
                    
                    Button(action: SignUpUser) {
                        // MARK: Login Button
                        Text("Places에 가입")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                            .hAlign(.center)
                            .fillView(.indigo)
                    }
                    .disableWithOpacity(username == "" || email == "" || password == "" || repassword == "" || userProfilePicData == nil || password != repassword)
                    .padding(.top, 10)
                    .alert(errorMessage, isPresented: $showError, actions: {})
                }
                .padding(.leading, -30)
                .padding(.horizontal , 30)
                
                HStack {
                    Text("이미 계정이 있으신가요?")
                        .foregroundStyle(.gray)
                    Button("로그인") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(.blue .opacity(0.8))
                }
                .font(.callout)
                .padding(.leading, -30)
                .frame(maxWidth: .infinity)
            }
            .padding(.leading, 30)
            .padding(.vertical, 15)
            .overlay(content: {
                LoadingView(show: $isLoading)
            })
        }
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { oldValue, newValue in
            // MARK: Extracting UIImage From PhotoItem
            if let newValue {
                Task {
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else {return}
                        // MARK: UI Must Be Updated on Main Thread
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                    } catch {
                        
                    }
                }
            }
        }
    }
    
    func SignUpUser() {
        isLoading = true
        closeKeyboard()
        Task {
            do {
                // Step 1: Creating Firebase Account
                try await Auth.auth().createUser(withEmail: email, password: password)
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                guard let imageData = userProfilePicData else {return}
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                let downloadURL = try await storageRef.downloadURL()
                // Step 2: Creating a User Firebase Object
                let user = User(username: username, userUID: userUID, userEmail: email, userProfileURL: downloadURL)
                // Step 3: Saving User Doc into Firebase
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: {error in
                    if error == nil{
                        // MARK: Print Saves Successfully
                        print("Saved Successfully")
                        userNameStored = username
                        self.userUID = userUID
                        logStatus = true
                    }
                })
            } catch {
                // MARK: Deleting Created Account In Case of Failure
                try await Auth.auth().currentUser?.delete()
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

#Preview {
    SignUpView()
}
