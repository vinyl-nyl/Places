//
//  PostCardView.swift
//  Places
//
//  Created by junil on 6/3/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import NMapsMap

struct PostCardView: View {
    var post: Post
    /// - Callbacks
    var onUpdate: (Post) -> ()
    var onDelete: () -> ()
    /// - View Properties
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var docListner: ListenerRegistration?
    @State private var showLocationView: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical, 8)
                
                /// Post Image If Any
                if let postImageURL = post.imageURL {
                    GeometryReader {
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                
                PostInteraction()
                
                // 위치 정보 보기 버튼 추가
                if post.location != nil {
                    Button(action: {
                        showLocationView.toggle()
                    }) {
                        Text("위치 정보 보기")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showLocationView) {
                        if let location = post.location {
                            LocationView(location: location)
                        }
                    }
                }
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            /// Displaying Delete Button (if  it's Author of that post)
            if post.userUID == userUID {
                Menu {
                    Button("삭제", role: .destructive, action: deletePost)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundStyle(.gray)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
            }
        })
        .onAppear {
            /// - Adding Only Once
            if docListner == nil {
                guard let postID = post.id else{return}
                docListner = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot, error in
                    if let snapshot {
                        if snapshot.exists {
                            /// - Document Updated
                            /// Fetching Updated Document
                            if let updatedPost = try? snapshot.data(as: Post.self) {
                                onUpdate(updatedPost)
                            }
                        } else {
                            /// - Document Deleted
                            onDelete()
                        }
                    }
                })
            }
        }
        .onDisappear {
            // MARK: Applying SnapShot Listner Only When the Post is Available on the Screen
            // Else Removing the Listner (It saves unwanted live updates from the posts which was swiped away from the screen)
            if let docListner {
                docListner.remove()
                self.docListner = nil
            }
        }
    }
    
    // MARK: Like Interaction
    @ViewBuilder
    func PostInteraction() -> some View {
        HStack(spacing: 6) {
            Button(action: likePost) {
                Image(systemName: post.likedIDs.contains(userUID) ? "star.fill" : "star")
            }
            
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .foregroundStyle(.indigo)
        .padding(.vertical, 8)
    }
    
    /// - Liking Post
    func likePost() {
        Task {
            guard let postID = post.id else{return}
            if post.likedIDs.contains(userUID) {
                /// Removing User ID From the Array
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                /// Adding User ID to Liked Array and removing our ID from Disliked Array(if Added in prior)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID])
                ])
            }
        }
    }
    
    /// - Deleting Post
    
    func deletePost() {
        Task {
            do {
                /// Step 1: Delete Image from Firebase Storage if present
                if let imageReferenceID = post.imageReferenceID, !imageReferenceID.isEmpty {
                    try await Storage.storage().reference().child("Post_Images").child(imageReferenceID).delete()
                }
            } catch {
                print("Failed to delete image: \(error.localizedDescription)")
            }

            do {
                /// Step 2: Delete Firestore Document
                guard let postID = post.id else { return }
                try await Firestore.firestore().collection("Posts").document(postID).delete()
            } catch {
                print("Failed to delete post: \(error.localizedDescription)")
            }
        }
    }
}

// LocationView를 추가합니다.
struct LocationView: View {
    var location: GeoPoint
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            NaverMapView(location: NMGLatLng(lat: location.latitude, lng: location.longitude))
                .edgesIgnoringSafeArea(.all)
                .navigationBarItems(trailing: Button("닫기") {
                    dismiss()
                })
        }
    }
}

struct NaverMapView: UIViewRepresentable {
    var location: NMGLatLng
    
    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView(frame: .zero)
        mapView.positionMode = .direction
        mapView.moveCamera(NMFCameraUpdate(scrollTo: location))
        
        let marker = NMFMarker(position: location)
        marker.mapView = mapView
        
        return mapView
    }
    
    func updateUIView(_ uiView: NMFMapView, context: Context) {}
}
