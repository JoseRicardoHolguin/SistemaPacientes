import SwiftUI

private struct IsLoggedInBindingKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

extension EnvironmentValues {
    var isLoggedInBinding: Binding<Bool>? {
        get { self[IsLoggedInBindingKey.self] }
        set { self[IsLoggedInBindingKey.self] = newValue }
    }
}
