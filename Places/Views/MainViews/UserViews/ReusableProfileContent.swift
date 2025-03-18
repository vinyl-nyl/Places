//
//  ReusableProfileContent.swift
//  Places
//
//  Created by junil on 5/22/24.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct ReusableProfileContent: View {
    var user: User
    @State private var fetchedPosts: [Post] = []
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                HStack(spacing: 12) {
                    WebImage(url: user.userProfileURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 6) {
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(user.userEmail)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .hAlign(.leading)
                
                Text("게시물")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                    .hAlign(.leading)
                    .padding(.vertical, 15)
                
                ReusablePostView(basedOnUID: true, uid: user.userUID, posts: $fetchedPosts)
            }
            .padding(15)
        }
    }
}
