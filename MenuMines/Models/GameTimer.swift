import Foundation

/// Encapsulates timer lifecycle for the game.
/// Provides start/stop/pause/resume operations without UI dependencies.
/// Note: Pause state is managed by the caller (GameState) for observability.
final class GameTimer {
    private var timer: Timer?

    /// Closure called every second when the timer ticks.
    var onTick: (() -> Void)?

    /// Starts the timer, calling onTick every second.
    /// If a timer is already running, it is invalidated first.
    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.onTick?()
        }
    }

    /// Stops the timer completely.
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Pauses the timer (alias for stop, semantically distinct).
    func pause() {
        timer?.invalidate()
        timer = nil
    }

    /// Resumes the timer (alias for start, semantically distinct).
    func resume() {
        start()
    }
}
