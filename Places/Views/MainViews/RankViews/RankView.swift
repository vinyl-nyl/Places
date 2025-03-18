import SwiftUI
import Firebase

struct RankView: View {
    @State private var rankedPosts: [Post] = []

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(Array(rankedPosts.enumerated()), id: \.element.id) { index, post in
                        PostCardView(post: post, onUpdate: { updatedPost in
                            if let index = rankedPosts.firstIndex(where: { $0.id == updatedPost.id }) {
                                rankedPosts[index] = updatedPost
                            }
                        }, onDelete: {
                            if let index = rankedPosts.firstIndex(where: { $0.id == post.id }) {
                                rankedPosts.remove(at: index)
                            }
                        })
                        .padding(.horizontal, 15)
                        .padding(.top, 10)
                        .padding(.bottom, 3)

                        // Divider between posts, except for the last one
                        if index != rankedPosts.count - 1 {
                            Divider()
                                .padding(.horizontal, -15)
                        }
                    }
                }
            }
            .navigationTitle("Hot Places")
            .onAppear {
                fetchRankedPosts()
            }
            .refreshable {
                fetchRankedPosts()
            }
        }
    }

    func fetchRankedPosts() {
        let db = Firestore.firestore()
        db.collection("Posts").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                rankedPosts = snapshot?.documents.compactMap { document in
                    try? document.data(as: Post.self)
                } ?? []
                rankedPosts.sort {
                    if $0.likedIDs.count == $1.likedIDs.count {
                        return $0.publishedDate > $1.publishedDate
                    } else {
                        return $0.likedIDs.count > $1.likedIDs.count
                    }
                }
            }
        }
    }
}

struct RankView_Previews: PreviewProvider {
    static var previews: some View {
        RankView()
    }
}
