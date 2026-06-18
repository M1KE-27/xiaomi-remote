import TokamakShim

/// Controlador simulado: no hay red. Solo registra la última acción para que el
/// preview sea visiblemente interactivo.
final class MockTV: ObservableObject {
    @Published var lastAction: String = "—"
    @Published var connected: Bool = true

    func press(_ name: String) { lastAction = name }
    func launch(_ app: String) { lastAction = "Abrir \(app)" }
}
