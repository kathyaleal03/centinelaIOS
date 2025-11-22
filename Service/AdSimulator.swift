import Foundation
import Combine

/// Simple ad simulator service that publishes events to show/hide ads.
@MainActor
final class AdSimulator: ObservableObject {
    static let shared = AdSimulator()
    private init() {}

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @Published var showBanner: Bool = false
    @Published var showInterstitial: Bool = false
    @Published var bannerType: AdType = .food
    @Published var interstitialType: AdType = .unicaes

    enum AdType {
        case food
        case unicaes
    }

    private var bannerTimer: Task<Void, Never>?
    private var interstitialTimer: Task<Void, Never>?

    /// Start periodic ads. intervalSeconds controls frequency (default 40s).
    func start(intervalSeconds: TimeInterval = 40) {
        stop()
        // Don't start if user is Pro
        if UserDefaults.standard.bool(forKey: "isProUser") {
            // ensure ads hidden
            showBanner = false
            showInterstitial = false
            return
        }
        // Banner appears briefly every interval
        bannerTimer = Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                await MainActor.run {
                    // alternate banner type each show
                    self.bannerType = (self.bannerType == .food) ? .unicaes : .food
                    self.showBanner = true
                }
                try? await Task.sleep(nanoseconds: UInt64(5 * 1_000_000_000)) // show banner 5s
                await MainActor.run {
                    self.showBanner = false
                }
                try? await Task.sleep(nanoseconds: UInt64((intervalSeconds - 5) * 1_000_000_000))
            }
        }

        // Interstitial appears every interval as a modal for 6s
        interstitialTimer = Task.detached { [weak self] in
            guard let self = self else { return }
            // offset interstitial by half interval so not simultaneous
            try? await Task.sleep(nanoseconds: UInt64((intervalSeconds/2) * 1_000_000_000))
            while !Task.isCancelled {
                // If user becomes Pro while running, stop showing
                if UserDefaults.standard.bool(forKey: "isProUser") {
                    await MainActor.run {
                        self.showInterstitial = false
                    }
                    break
                }
                await MainActor.run {
                    // alternate interstitial type each show
                    self.interstitialType = (self.interstitialType == .food) ? .unicaes : .food
                    self.showInterstitial = true
                }
                try? await Task.sleep(nanoseconds: UInt64(6 * 1_000_000_000))
                await MainActor.run {
                    self.showInterstitial = false
                }
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
    }

    func stop() {
        bannerTimer?.cancel()
        bannerTimer = nil
        interstitialTimer?.cancel()
        interstitialTimer = nil
        showBanner = false
        showInterstitial = false
    }
}
