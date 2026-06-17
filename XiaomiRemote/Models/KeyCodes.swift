import Foundation

enum RemoteKey: Int, CaseIterable {
    case power = 26
    case home = 3
    case back = 4
    case dpadUp = 19
    case dpadDown = 20
    case dpadLeft = 21
    case dpadRight = 22
    case dpadCenter = 23
    case volumeUp = 24
    case volumeMute = 164
    case volumeDown = 25
    case playPause = 85
    case mediaNext = 87
    case mediaPrev = 88
    case mediaStop = 86
    case rewind = 89
    case fastForward = 90
    case menu = 82
    case search = 84
    case settings = 176

    var label: String {
        switch self {
        case .power: return "Power"
        case .home: return "Home"
        case .back: return "Back"
        case .dpadUp: return "Up"
        case .dpadDown: return "Down"
        case .dpadLeft: return "Left"
        case .dpadRight: return "Right"
        case .dpadCenter: return "OK"
        case .volumeUp: return "Vol +"
        case .volumeMute: return "Mute"
        case .volumeDown: return "Vol -"
        case .playPause: return "Play/Pause"
        case .mediaNext: return "Next"
        case .mediaPrev: return "Prev"
        case .mediaStop: return "Stop"
        case .rewind: return "Rewind"
        case .fastForward: return "FF"
        case .menu: return "Menu"
        case .search: return "Search"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .power: return "power"
        case .home: return "house.fill"
        case .back: return "arrow.left"
        case .dpadUp: return "chevron.up"
        case .dpadDown: return "chevron.down"
        case .dpadLeft: return "chevron.left"
        case .dpadRight: return "chevron.right"
        case .dpadCenter: return "circle.fill"
        case .volumeUp: return "speaker.plus.fill"
        case .volumeMute: return "speaker.slash.fill"
        case .volumeDown: return "speaker.minus.fill"
        case .playPause: return "playpause.fill"
        case .mediaNext: return "forward.end.fill"
        case .mediaPrev: return "backward.end.fill"
        case .mediaStop: return "stop.fill"
        case .rewind: return "backward.fill"
        case .fastForward: return "forward.fill"
        case .menu: return "list.bullet"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape.fill"
        }
    }
}
