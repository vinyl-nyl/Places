# Places iOS App

## 📌 프로젝트 개요
- **프로젝트명**: Places - 지역별 장소 추천 iOS 앱
- **개발자**: 이준일
- **GitHub Repository**: [Places](https://github.com/vinyl-nyl/Places)

## 🎯 프로젝트 소개
Places는 사용자가 위치 기반으로 다양한 장소를 추천받고 게시물을 공유할 수 있는 iOS 애플리케이션입니다. Firebase를 기반으로 사용자 인증 및 데이터 관리가 이루어지며, Naver Map API를 활용하여 지도 기능을 제공합니다.

## 🔍 주요 기능
### 🔑 사용자 인증 및 관리
- Firebase Authentication을 이용한 이메일/비밀번호 로그인 및 회원가입
- 사용자 프로필 보기 및 수정

### 📝 게시물 관리
- 텍스트 및 이미지 포함 게시물 작성
- 위치 데이터 연동 (Naver Map API 활용)
- 게시물 삭제 및 검색 기능
- 좋아요 기능 추가

### 🗺 지도 기능
- 현재 위치 확인
- 위치 기반 게시물 추가

## 🛠 기술 스택
- **개발 언어**: Swift (SwiftUI)
- **IDE**: Xcode (Version 15.3)
- **데이터베이스**: Firebase Firestore
- **스토리지**: Firebase Storage
- **지도 API**: Naver Maps API
- **프로젝트 관리**: GitHub

## 🏗 프로젝트 구조
```
PlacesApp
├── Models
│   ├── User.swift
│   ├── Post.swift
├── Views
│   ├── ContentView.swift
│   ├── LoginView.swift
│   ├── MainView.swift
│   ├── PostView.swift
│   ├── UserView.swift
│   ├── MapView.swift
├── ViewModels
│   ├── LoginViewModel.swift
├── Services
│   ├── FirebaseService.swift
├── Resources
│   ├── Assets.xcassets
```

## 📌 향후 추가할 기능 (TODO)
- [ ] 장소 검색 기능 추가
- [ ] 사용자 프로필 이미지 크롭 기능 추가
- [ ] 게시물 수정 기능 추가
