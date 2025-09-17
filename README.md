<div align="center">
  <h1><code>Shavit Third Person</code></h1>
  <p>
    <strong>Simple third-person chase camera for shavit's CS:S bhop timer with customizable FOV</strong>
  </p>
</div>

---

## Features

- **Third-person chase camera** with fixed behind-player view
- **Customizable FOV**: Adjust field of view from 80-120
- **Persistent settings**: FOV saved automatically per player
- **Per-client mp_forcecamera**: Only affects players using the style
- **Shavit integration**: Works perfectly with shavit-timer system

## Installation

> **⚠️ IMPORTANT NOTICE:**  
> Add `bash_bypass` to your Tank Controls style specialstring to avoid Bash warnings/bans:
> ```
> "specialstring" "thirdperson; bash_bypass"
> ```

1. **Compile**: `spcomp -include shavit-style-thirdperson.sp`
2. **Install**: Place the compiled `.smx` in `addons/sourcemod/plugins/`
3. **Configure**: Add your style with `"specialstring" "thirdperson"` in your Shavit config
4. **Restart your server**

## Commands & Controls

| Command         | Usage         | Description                              |
|-----------------|---------------|------------------------------------------|
| `/tpfov <val>`  | `/tpfov 105`  | Set camera FOV (80-120)                  |
| `/fov <val>`    | `/fov 90`     | Alias for `/tpfov`                       |
| `/tpfov`        | -             | Show current FOV and usage               |

## Usage

1. Select **Third Person** style in the `!style` menu
2. Camera switches to third-person chase view automatically
3. Use `/fov <value>` to adjust your preferred field of view
4. Your FOV setting is saved automatically

## Configuration Example

Add to your `shavit-styles.cfg`:

```json
"ThirdPerson"
{
    "name"              "Third Person"
    "shortname"         "TP"
    "htmlcolor"         "00FF88"
    "specialstring"     "thirdperson"
    // ... other style settings
}
```

## ConVars

| ConVar                        | Default       | Description                    |
|-------------------------------|---------------|--------------------------------|
| `ss_thirdperson_specialstring` | `thirdperson` | Special string for style detection |

## Requirements

- SourceMod 1.9+
- Shavit Timer
- Counter-Strike: Source
- SDKHooks extension
- ClientPrefs extension

## Troubleshooting

- **Camera not activating**:  
  Ensure your style has `"specialstring" "thirdperson"` in the Shavit config and matches the ConVar value.

- **FOV not saving**:  
  Check if ClientPrefs/cookies are working on your server (`sm_cookie_menu`).

- **Can't switch weapons**: This is due to the third-person implementation that uses the Spectator Camera to simulate third-person, unless the camera implementation is changed, this can't be fixed.

---