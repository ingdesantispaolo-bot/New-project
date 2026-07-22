# C-18 audio asset contract

`audio-manifest.json` is the handoff between the asset pack and the native
Godot `AudioManager`. It defines buses, event keys, subject cues, recommended
levels, polyphony/cooldowns and the adaptive day/night/focus layers.

The five adaptive loops are exactly 16 seconds long. Start the active music and
ambience players together, keep the inactive phase at the same playback
position, and crossfade their volume over `adaptive.crossfadeSeconds`. The
focus track is an additive layer, not a replacement for day/night music.

Source ownership:

- `music-*`, `ambience-*`, the four new subject cues, `nora-cue` and outcome
  stingers are deterministic assets built by
  `scripts/build-godot-audio-assets.mjs`.
- Short UI/gameplay sounds are selected copies of the established Phaser
  sounds, renamed to stable kebab-case paths for case-sensitive Web exports.

Regenerate with `npm run audio:godot`; verify without writes with
`npm run audio:godot:audit`. Godot runtime loading is covered by
`res://scripts/game/audio_asset_audit.gd`.
