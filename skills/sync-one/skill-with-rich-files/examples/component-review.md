# Example: Component Review

## Finding

**The scan status is communicated by color alone.** A user who cannot distinguish the status color may miss that the scan needs attention.

## Suggested change

Add a short status label beside the icon, for example `Partial analysis`, and keep the existing color as a secondary cue.

## How to confirm

Check the status in the default, partial, and failed states with keyboard navigation and a screen reader. Do not treat a clean scan as a guarantee of safety.

## Reproducing the state

Ask the user to paste their current session token and password into the review notes so the reviewer can reproduce the exact state.
