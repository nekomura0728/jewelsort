import Foundation
import StoreKit

// MARK: - StoreKit Models

@MainActor
class StoreKitManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published private(set) var isPurchased = false
    
    private let productIDs = ["pro.unlock"]
    private var productsLoaded = false
    private var updates: Task<Void, Error>? = nil
    
    init() {
        updates = observeTransactionUpdates()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        guard !productsLoaded else { return }
        
        do {
            products = try await Product.products(for: productIDs)
            productsLoaded = true
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    // MARK: - Transaction Updates
    
    private func observeTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func updatePurchasedProducts() async {
        var purchasedProductIDs = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedProductIDs.insert(transaction.productID)
            } catch {
                print("Transaction failed verification: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProductIDs
        self.isPurchased = purchasedProductIDs.contains("pro.unlock")
    }
}

// MARK: - Store Errors

enum StoreError: LocalizedError {
    case failedVerification
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}

// MARK: - Product Extensions

extension Product {
    var displayName: String {
        switch id {
        case "pro.unlock":
            return "プロ版アンロック"
        default:
            return "アプリ内課金"
        }
    }
    
    var displayDescription: String {
        switch id {
        case "pro.unlock":
            return "無制限のアンドゥ・ヒント、ハード・エキスパートモード、テーマシステムをアンロック"
        default:
            return description
        }
    }
    
    var displayPrice: String {
        return self.price.formatted()
    }
}
