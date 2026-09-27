import LocalAuthentication
import AppKit

final class Authenticator {
    static let shared = Authenticator()

    private var activeContext: LAContext?
    private var isEvaluating = false

    private init() {}

    /// Checks if device owner authentication (Touch ID, Apple Watch, or device password) is configured and available.
    func isAuthenticationAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// Evaluates device owner authentication (Touch ID, Apple Watch, or device password) to deactivate MirrorLock.
    func evaluateUnlock(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        guard !isEvaluating else { return }
        isEvaluating = true

        activeContext?.invalidate()
        let context = LAContext()
        activeContext = context

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async { [weak self] in
                self?.isEvaluating = false
                completion(false, error)
            }
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evalError in
            DispatchQueue.main.async { [weak self] in
                self?.isEvaluating = false
                if self?.activeContext === context {
                    self?.activeContext = nil
                }
                completion(success, evalError)
            }
        }
    }

    /// Sends a test prompt allowing the user to verify Apple Watch or Touch ID authentication.
    func testAuthentication(completion: @escaping (Bool, String) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(false, error?.localizedDescription ?? "Authentication unavailable.")
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Testing Apple Watch and Touch ID authentication for MirrorLock"
        ) { success, evalError in
            DispatchQueue.main.async {
                if success {
                    completion(true, "Authentication succeeded!")
                } else {
                    let msg = evalError?.localizedDescription ?? "Authentication failed or canceled."
                    completion(false, msg)
                }
            }
        }
    }
}
