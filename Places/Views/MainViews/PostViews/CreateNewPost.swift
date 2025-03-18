//
//  CreateNewPost.swift
//  Places
//
//  Created by junil on 5/22/24.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift
import NMapsMap // Import Naver Maps SDK

struct CreateNewPost: View {
    /// - Callbacks
    var onPost: (Post) -> ()
    /// - Post Properties
    @State private var postText: String = ""
    @State private var postImageData: Data?
    @State private var selectedLocation: NMGLatLng? // 선택된 위치 상태 추가
    /// - Stored User Data From UserDefaults(AppStorage)
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    /// - View Properties
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showKeyboard: Bool
    @State private var showMapPicker: Bool = false // 지도 뷰를 표시할 상태 추가

    var body: some View {
        VStack {
            HStack {
                Menu {
                    Button("취소", role: .destructive) {
                        dismiss()
                    }
                } label: {
                    Text("취소")
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
                .hAlign(.leading)
                
                Button(action: createPost){
                    Text("게시")
                        .font(.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(.indigo, in: Capsule())
                }
                .disableWithOpacity(postText == "")
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    TextField("플레이스를 추천해주세요!", text: $postText, axis: .vertical)
                        .focused($showKeyboard)
                    if let postImageData, let image = UIImage(data: postImageData) {
                        GeometryReader {
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            /// - Delete Button
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)){
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)
                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                    
                    // 선택된 위치 표시
                    if let location = selectedLocation {
                        Text("선택된 위치: \(location.lat), \(location.lng)")
                            .foregroundColor(.blue)
                            .padding(.top, 10)
                    }
                }
                .padding(15)
            }
            
            Divider()
            
            HStack {
                Button {
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                }
                .hAlign(.leading)
                
                Button {
                    showMapPicker.toggle()
                } label: {
                    Image(systemName: "map")
                        .font(.title3)
                }
                .hAlign(.leading)
                
                Button("확인") {
                    showKeyboard = false
                }
            }
            .foregroundStyle(.indigo)
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
        }
        .vAlign(.top)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { oldValue, newValue in
            if let newValue {
                Task {
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: rawImageData),
                       let compressedImageData = image.jpegData(compressionQuality: 0.5) {
                        /// UI Must be done on Main Thread
                        await MainActor.run {
                            postImageData = compressedImageData
                            photoItem = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showMapPicker) {
            NaverMapPicker(selectedLocation: $selectedLocation)
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
        /// - Loading View
        .overlay {
            LoadingView(show: $isLoading)
        }
    }
    
    // MARK: Post Content To Firebase
    func createPost() {
        isLoading = true
        showKeyboard = false

        Task {
            do {
                var imageURL: URL? = nil
                var imageReferenceID: String? = nil
                
                if let postImageData {
                    let storageRef = Storage.storage().reference()
                    imageReferenceID = UUID().uuidString
                    let imageRef = storageRef.child("Post_Images").child(imageReferenceID!)
                    _ = try await imageRef.putDataAsync(postImageData)
                    imageURL = try await imageRef.downloadURL()
                }

                guard let profileURL = try await fetchUserProfileURL(userUID: userUID) else {
                    throw NSError(domain: "CreateNewPost", code: 0, userInfo: [NSLocalizedDescriptionKey: "User profile URL is missing. Please set your profile URL in the settings."])
                }

                let post = Post(
                    text: postText,
                    imageURL: imageURL,
                    imageReferenceID: imageReferenceID,
                    userName: userName,
                    userUID: userUID,
                    userProfileURL: profileURL,
                    location: selectedLocation != nil ? GeoPoint(latitude: selectedLocation!.lat, longitude: selectedLocation!.lng) : nil // 위치 데이터 추가
                )
                
                let doc = Firestore.firestore().collection("Posts").document()
                let _ = try Firestore.firestore().collection("Posts").addDocument(from: post)
                var updatedPost = post
                updatedPost.id = doc.documentID
                onPost(updatedPost)
                isLoading = false
                dismiss()
            } catch {
                await setError(error)
            }
        }
    }

    // MARK: Fetch User Profile URL
    func fetchUserProfileURL(userUID: String) async throws -> URL? {
        let db = Firestore.firestore()
        let document = try await db.collection("Users").document(userUID).getDocument()
        if let data = document.data() {
            print("User document data: \(data)")
            if let urlString = data["userProfileURL"] as? String {
                return URL(string: urlString)
            } else {
                print("userProfileURL is missing in the document for UID: \(userUID)")
            }
        } else {
            print("User document does not exist for UID: \(userUID)")
        }
        return nil
    }

    // MARK: Displaying Errors as Alert
    func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }
}

// 새로운 NaverMapPicker 뷰 추가
struct NaverMapPicker: View {
    @Binding var selectedLocation: NMGLatLng?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            NaverMapPickerView(selectedLocation: $selectedLocation)
                .edgesIgnoringSafeArea(.all)
                .navigationBarItems(trailing: Button("닫기") {
                    dismiss()
                })
        }
    }
}

struct NaverMapPickerView: UIViewRepresentable {
    @Binding var selectedLocation: NMGLatLng?

    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView(frame: .zero)
        mapView.addCameraDelegate(delegate: context.coordinator)
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:))))
        return mapView
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, NMFMapViewCameraDelegate {
        var parent: NaverMapPickerView
        var marker: NMFMarker?

        init(_ parent: NaverMapPickerView) {
            self.parent = parent
        }

        func mapView(_ mapView: NMFMapView, cameraWillChangeByReason reason: Int, animated: Bool) {}

        func mapView(_ mapView: NMFMapView, cameraIsChangingByReason reason: Int) {}

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            if let mapView = gesture.view as? NMFMapView {
                let latlng = mapView.projection.latlng(from: point)
                parent.selectedLocation = latlng

                if let marker = marker {
                    marker.position = latlng
                } else {
                    let newMarker = NMFMarker(position: latlng)
                    newMarker.mapView = mapView
                    marker = newMarker
                }
            }
        }
    }
}

struct CreateNewPost_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewPost { _ in
            
        }
    }
}
