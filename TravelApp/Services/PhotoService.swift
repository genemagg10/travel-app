import Foundation
import Photos
import UIKit
import SwiftUI

@Observable
class PhotoService {
    var isAuthorized = false
    var recentPhotos: [PHAsset] = []

    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            isAuthorized = status == .authorized || status == .limited
        }
    }

    func fetchPhotos(from startDate: Date, to endDate: Date, limit: Int = 50) async -> [PHAsset] {
        guard isAuthorized else { return [] }

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit

        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var assets: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    func fetchPhotosNear(latitude: Double, longitude: Double, radiusMeters: Double = 500) async -> [PHAsset] {
        guard isAuthorized else { return [] }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100

        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var assets: [PHAsset] = []
        let targetLocation = CLLocation(latitude: latitude, longitude: longitude)

        results.enumerateObjects { asset, _, _ in
            if let location = asset.location {
                let distance = location.distance(from: targetLocation)
                if distance <= radiusMeters {
                    assets.append(asset)
                }
            }
        }
        return assets
    }

    static func loadImage(from asset: PHAsset, targetSize: CGSize = CGSize(width: 300, height: 300)) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    static func loadFullImage(from asset: PHAsset) async -> UIImage? {
        await loadImage(from: asset, targetSize: PHImageManagerMaximumSize)
    }
}

// MARK: - PHAsset Image View

struct PhotoAssetImage: View {
    let asset: PHAsset
    let size: CGSize
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .task {
            image = await PhotoService.loadImage(from: asset, targetSize: size)
        }
    }
}
