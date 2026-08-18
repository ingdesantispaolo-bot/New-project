# C-18 audio asset contract

`audio-manifest.json` is the handoff between the asset pack and the native
Godot `AudioManager`. It defines buses, event keys, subject cues, recommended
levels, polyphony/cooldowns and the adaptive day/night/focus layers.

The five shared adaptive loops are exactly 16 seconds long and remain the safe
fallback. Every `soundscape` declared by `WorldProfileCatalog` also owns a
60-second mono ambience loop. `GameAudioManager` selects that world loop when it
exists and falls back to `ambience.day` / `ambience.night` when it does not. The
focus track is an additive layer, not a replacement for day/night music.

The `soundscapes.byId` contract records the matching `terrainFamily` and a
`motif`. Nearby families intentionally share a motif, while every profile keeps
its own file and deterministic seed. `maxFamilyNeighbours` limits how many
worlds may reuse the same musical parentage.

Source ownership:

- `music-*`, `ambience-*`, `soundscape-*`, the four new subject cues,
  `nora-cue` and outcome stingers are deterministic assets built by
  `scripts/build-godot-audio-assets.mjs`.
- Short UI/gameplay sounds are selected copies of the established Phaser
  sounds, renamed to stable kebab-case paths for case-sensitive Web exports.

Regenerate with `npm run audio:godot`; verify without writes with
`npm run audio:godot:audit`. Godot runtime loading is covered by
`res://scripts/game/audio_asset_audit.gd`.
