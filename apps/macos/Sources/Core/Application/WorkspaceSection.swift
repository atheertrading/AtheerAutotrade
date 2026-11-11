import Foundation

/// The navigation destinations exposed by the AtheerAutotrade application shell.
/// This type contains presentation metadata only; it does not own trading behavior.
enum WorkspaceSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Dashboard"
    case markets = "Markets"
    case strategies = "Strategies"
    case positions = "Positions"
    case orders = "Orders"
    case portfolio = "Portfolio"
    case riskManagement = "Risk Management"
    case analytics = "Analytics"
    case intelligence = "AI Intelligence"
    case activity = "Activity"
    case settings = "Settings"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .dashboard:
            return "square.grid.2x2"
        case .markets:
            return "chart.xyaxis.line"
        case .strategies:
            return "slider.horizontal.3"
        case .positions:
            return "rectangle.stack"
        case .orders:
            return "list.bullet.rectangle"
        case .portfolio:
            return "briefcase"
        case .riskManagement:
            return "shield"
        case .analytics:
            return "chart.bar"
        case .intelligence:
            return "sparkles"
        case .activity:
            return "clock.arrow.circlepath"
        case .settings:
            return "gearshape"
        }
    }

    var availabilityDescription: String {
        switch self {
        case .dashboard:
            return "The application overview and service status."
        case .markets:
            return "Market data and instrument monitoring."
        case .strategies:
            return "Strategy research, configuration, and lifecycle management."
        case .positions:
            return "Broker-reconciled open position monitoring."
        case .orders:
            return "Order lifecycle and execution status monitoring."
        case .portfolio:
            return "Portfolio exposure and allocation monitoring."
        case .riskManagement:
            return "Risk limits, controls, and system protection."
        case .analytics:
            return "Performance and quantitative analytics."
        case .intelligence:
            return "AI-assisted research and decision support."
        case .activity:
            return "System events and audit activity."
        case .settings:
            return "Application and service configuration."
        }
    }
}
