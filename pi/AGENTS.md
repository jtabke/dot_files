# Global Pi Agent Instructions

- In root parent sessions, keep the parent as the orchestrator. When the same delegated role needs follow-up work within the current parent session, prefer resuming its existing child session by run ID instead of launching a fresh child. Use `steer` for a live child and `resume` for a paused or completed child. Continue using fresh-context children when independence is intentional, especially for adversarial review and validation.
