# Hotbar Requests

A Factorio 2.0 mod that keeps a logistic request group in sync with your quickbar: every item pinned to your hotbar
is requested from the logistic network, one stack each by default. Pin an item and it's on its way; unpin it and
the request goes.

Per-player settings: on/off, the request group's name (your other requests are left alone), how many stacks of
each, how many quickbar pages count, and whether robots take away anything above the request.
Safe to add or remove at any time.

## Install

Copy this folder into your mods folder (`%APPDATA%\Factorio\mods`) as `hotbar-requests`, or clone it there:

```
git clone https://github.com/watdafawx/hotbar-requests
```

`test\run.py` runs the headless tests (set `FACTORIO_EXE` if the game isn't in a usual Steam library).

## License

MIT, see [LICENSE](LICENSE).
