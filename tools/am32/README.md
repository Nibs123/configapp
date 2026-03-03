# AM32 tool offline packaging

Supported options:

- Place executable tool at `tools/am32/am32-tool` and make it executable.
- Or place static web files in `tools/am32/webapp/` with an `index.html`.

Launcher tries executable first, then web app (`http://127.0.0.1:8812`).
