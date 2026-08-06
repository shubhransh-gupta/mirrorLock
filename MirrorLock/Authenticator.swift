import LocalAuthentication

final class Authenticator {
    static let shared = Authenticator()

    private var activeContext: LAContext?
    private var isEvaluating = false

    private init() {}

    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func evaluateUnlock(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        guard !isEvaluating else { return }
        isEvaluating = true

        activeContext?.invalidate()
        let context = LAContext()
        activeContext = context

        var error: NSError?
        let canBiometric = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        let policy: LAPolicy
        if canBiometric {
            policy = .deviceOwnerAuthenticationWithBiometrics
        } else if let laError = error as? LAError, laError.code == .biometryLockout {
            policy = .deviceOwnerAuthentication
        } else {
            var fallbackError: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &fallbackError) {
                policy = .deviceOwnerAuthentication
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.isEvaluating = false
                    completion(false, error ?? fallbackError)
                }
                return
            }
        }

        context.evaluatePolicy(policy, localizedReason: reason) { success, evalError in
            DispatchQueue.main.async { [weak self] in
                self?.isEvaluating = false
                if self?.activeContext === context {
                    self?.activeContext = nil
                }
                completion(success, evalError)
            }
        }
    }
}
