<div align="center">
  <h1><code>Shavit Third Person</code></h1>
  <p>
    <strong>Simple third-person chase camera for shavit's CS:S bhop timer with customizable FOV and more</strong>
  </p>
</div>

---

## Features

- **Third-person chase camera** with fixed behind-player view
- **Customizable FOV**: Adjustable field of view
- **Persistent settings**: Cookies that saves player settings on the server
- **Per-client mp_forcecamera**: Only affects players using the style
- **Shavit integration**: Works seamlessly with shavit-timer styles

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

| Command         | Description                              |
|-----------------|------------------------------------------|
| `/tpfov <val>`  | Set camera Field of View                 |
| `/tpfov`        | Shows current FOV and opens FOV menu     |
| `/tpnvg`        | Toggle Night Vision Goggles              |
| `/tpmenu`       | Opens the Third Person Main Menu         |

## Usage

1. Select **Third Person** style in the `/style` menu
2. Camera switches to third-person chase view automatically
3. Type `/tpmenu` to adjust your settings
4. All settings are saved automatically

## Configuration Example

Add to your `shavit-styles.cfg`:

```json
"<stylenumber>"
{
    "name"              "Third Person"
    "shortname"         "3rd"
    "htmlcolor"         "00FF88"
    "specialstring"     "thirdperson; bash_bypass"
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

- **Settings not saving for players**:  
  Check if ClientPrefs/cookies are working on your server (`sm_cookie_menu`).

- **Can't switch weapons**:  
This is due to the third-person implementation that uses the Spectator Camera to simulate third-person, unless the camera implementation is changed, this can't be fixed.  
The current workaround is to get a weapon by typing it's related command: `/glock`, `/usp`, etc.

---