import Foundation
import Observation
import StoreKit

@MainActor @Observable
final class ReefPurchases {
    // Add approved App Store Connect IDs when permanent purchases exist.
    // Keeping this empty leaves today's free prototype entirely offline.
    static let permanentProductIDs: Set<String> = []
    private(set) var isRestoring = false
    var message: String?

    func observe(store: ReefStore) async {
        guard !Self.permanentProductIDs.isEmpty else { return }
        _ = await refresh(store: store)
        for await result in Transaction.updates {
            guard !Task.isCancelled else { return }
            guard case .verified(let transaction) = result,
                  transaction.productType == .nonConsumable,
                  Self.permanentProductIDs.contains(transaction.productID) else { continue }
            // Only acknowledge supported transactions after the verified state
            // has been saved. Never finish an unhandled consumable transaction.
            if await refresh(store: store) { await transaction.finish() }
        }
    }

    func restore(store: ReefStore) async {
        guard !isRestoring, !store.isSaveBlocked else { return }
        guard !Self.permanentProductIDs.isEmpty else {
            message = "Purchases are free previews for now. There are no paid purchases to restore. Your hints and added taps are saved on this device."
            return
        }
        isRestoring = true
        defer { isRestoring = false }
        do {
            // This can show an Apple sign-in prompt, so it runs only when the
            // player explicitly presses Restore purchases.
            try await AppStore.sync()
            if await refresh(store: store) {
                message = store.progress.purchaseEntitlements.isEmpty
                    ? "No restorable purchases were found for this App Store account."
                    : "Your permanent purchases have been restored."
            } else { message = "Your purchases were found, but couldn't be saved. Please try again." }
        } catch { message = "Purchases couldn't be restored right now. Please try again when you're connected to the App Store." }
    }

    private func refresh(store: ReefStore) async -> Bool {
        var entitlements: [ReefPurchaseEntitlement] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productType == .nonConsumable,
                  transaction.revocationDate == nil,
                  Self.permanentProductIDs.contains(transaction.productID) else { continue }
            entitlements.append(.init(transactionID: String(transaction.id), productID: transaction.productID, purchaseDate: transaction.purchaseDate))
        }
        return store.rememberPurchaseEntitlements(entitlements)
    }
}
