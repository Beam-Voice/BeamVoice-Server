# BeamVoice Server

A BeamMP plugin that adds positional voice chat to BeamMP servers.

## Status

**Work in progress.** The project is under active development and is **not ready for public use** yet. The API, configuration, and behavior may change at any time.

## Access

Running the plugin requires a valid **authentication key (`key`)** set in `configs/BeamVoice.toml`. This key is only handed out to **private beta** participants.

If you do not have private beta access, you will not be able to obtain a key and the plugin will refuse to start. There is currently no public sign-up - broader access will open later, once the project stabilizes.

## Installation (private beta only)

1. Drop the folder into your server's `Resources/Server/` directory.
2. Copy `defaultConfig.toml` to `configs/BeamVoice.toml`.
3. Fill in the `key` rovided by the BeamVoice team.
4. Start the BeamMP server.

## In-game commands

- `/vc` or `/voice` - join or leave the voice chat.
