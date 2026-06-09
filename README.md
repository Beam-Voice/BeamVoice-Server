# BeamVoice Server

A BeamMP plugin that adds positional voice chat to BeamMP servers.

## Access

Running the plugin requires a valid **authentication key (`key`)** set in `configs/BeamVoice.toml`.
Get your key at https://beamvoice.net

## Installation (private beta only)

1. Drop the folder into your server's `Resources/Server/` directory, and un-archive it ! It should look like that:
```
Resources/Server/
└── BeamVoice/
    ├── lib
    ├── lua
    ├── defaultConfig.toml
    └── main.lua
```
2. Start the server to generate the config file.
3. Edit the `configs/BeamVoice.toml` file, fill in the `key`.
4. Re-Start the BeamMP server.

## Console commands

- `voice reauth` - Reauth the server
- `voice status` - Check if the voice chat is enabenabled or not.

## In-game commands

- `/vc` or `/voice` - join or leave the voice chat.