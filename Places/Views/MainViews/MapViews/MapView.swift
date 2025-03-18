//
//  MapView.swift
//  Places
//
//  Created by junil on 6/17/24.
//

import SwiftUI
import NMapsMap
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = SearchPlaceViewModel() // ViewModel 추가
    @State private var searchText: String = "" // 검색어 상태 추가

    var body: some View {
        ZStack {
            UIMapView(location: $locationManager.location, shouldMoveCamera: $locationManager.shouldMoveCamera, searchResults: $viewModel.placeList)
                .ignoresSafeArea()

            VStack {
                HStack {
                    TextField("장소, 버스, 지하철, 주소 검색", text: $searchText, onCommit: {
                        viewModel.searchPlace(searchText: searchText) // 검색어를 사용해 검색 수행
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal)

                    Button(action: {
                        viewModel.searchPlace(searchText: searchText) // 검색 버튼 클릭 시 검색 수행
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            locationManager.checkLocationAuthorization()
        }
    }
}

struct UIMapView: UIViewRepresentable {
    @Binding var location: CLLocationCoordinate2D?
    @Binding var shouldMoveCamera: Bool
    @Binding var searchResults: [PlaceItem]

    // 초기화 메서드 추가
    init(location: Binding<CLLocationCoordinate2D?>, shouldMoveCamera: Binding<Bool>, searchResults: Binding<[PlaceItem]>) {
        self._location = location
        self._shouldMoveCamera = shouldMoveCamera
        self._searchResults = searchResults
    }

    func makeUIView(context: Context) -> NMFNaverMapView {
        let view = NMFNaverMapView()
        view.showZoomControls = false
        view.mapView.positionMode = .direction
        view.mapView.zoomLevel = 17

        // 현재 위치 버튼 추가
        let locationButton = NMFLocationButton()
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        locationButton.addTarget(context.coordinator, action: #selector(Coordinator.moveToCurrentLocation), for: .touchUpInside)
        view.addSubview(locationButton)

        NSLayoutConstraint.activate([
            locationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            locationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15) // 하단 탭 위로 배치
        ])

        context.coordinator.mapView = view.mapView

        return view
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        if let location = location {
            let locationOverlay = uiView.mapView.locationOverlay
            locationOverlay.hidden = false
            locationOverlay.location = NMGLatLng(lat: location.latitude, lng: location.longitude)

            if shouldMoveCamera {
                let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: location.latitude, lng: location.longitude))
                cameraUpdate.animation = .easeIn // 부드러운 애니메이션
                uiView.mapView.moveCamera(cameraUpdate)

                DispatchQueue.main.async {
                    self.shouldMoveCamera = false // 초기 카메라 이동 후 플래그를 false로 설정
                }
            }
        }

        // 기존 마커 제거
        context.coordinator.clearMarkers()

        // 새로운 마커 추가
        for result in searchResults {
            let marker = NMFMarker()
            marker.position = NMGLatLng(lat: Double(result.mapy) ?? 0.0, lng: Double(result.mapx) ?? 0.0)
            marker.captionText = result.title
            marker.mapView = uiView.mapView
            context.coordinator.markers.append(marker) // 마커 배열에 추가
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: UIMapView
        var mapView: NMFMapView?
        var markers: [NMFMarker] = [] // 마커 배열

        init(_ parent: UIMapView) {
            self.parent = parent
        }

        func clearMarkers() {
            for marker in markers {
                marker.mapView = nil // 마커 제거
            }
            markers.removeAll() // 배열 초기화
        }

        @objc func moveToCurrentLocation() {
            if let location = parent.location, let mapView = mapView {
                let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: location.latitude, lng: location.longitude))
                cameraUpdate.animation = .easeIn
                mapView.moveCamera(cameraUpdate)
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var shouldMoveCamera = true

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthorization()
    }

    func checkLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                print("Location access denied or restricted.")
                // Handle the case where location access is not available
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.startUpdatingLocation()
            @unknown default:
                fatalError("Unknown authorization status")
            }
        } else {
            print("Location services are not enabled.")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access was restricted or denied.")
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        @unknown default:
            fatalError("Unknown authorization status")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            DispatchQueue.main.async {
                self.location = location.coordinate
                if self.shouldMoveCamera {
                    self.shouldMoveCamera = false
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
