import SwiftUI

private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<ContentView.Tab>? = nil
}

extension EnvironmentValues {
    var selectedTab: Binding<ContentView.Tab>? {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}
