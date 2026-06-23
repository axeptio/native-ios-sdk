import AxeptioSDK

enum ActionType {
    case openMainFlow
    case openCookieFlow
    case openPermissionsFlow

    var entryPoint: RootEntryPointType {
        switch self {
        case .openMainFlow: .all
        case .openCookieFlow: .cookieAndAttOnly
        case .openPermissionsFlow: .permissionsOnly
        }
    }

    var title: String {
        switch self {
        case .openMainFlow: "Open main flow"
        case .openCookieFlow: "Open Cookie flow"
        case .openPermissionsFlow: "Open Permissions flow"
        }
    }

    var subtitle: String {
        switch self {
        case .openMainFlow: "Cookie → ATT → Permissions"
        case .openCookieFlow: "Cookie only"
        case .openPermissionsFlow: "Permissions only"
        }
    }
}
