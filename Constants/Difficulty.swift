// Add this enum at the top level
enum DifficultyLevel: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Josh"
    
    var iterations: Int {
        switch self {
        case .easy: return 1000
        case .medium: return 2000
        case .hard: return 3000
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Josh"
        }
    }
}
