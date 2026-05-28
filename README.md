# PastePaw

PastePaw is a cute macOS clipboard history app with a FuFu theme. It records recent copied text and images locally, lets you search, pin, delete, and copy history items back to the system clipboard, and includes a menu bar quick-copy workflow.

## Features

- macOS menu bar app that runs in the background.
- Clipboard history for text and original-quality images.
- Pinned items that do not expire.
- Configurable retention for normal history.
- Searchable text history.
- Configurable menu bar quick-history count.
- Chinese and English language support.
- Static marketing website in `website/`.

## Run the macOS App

```bash
./script/build_and_run.sh
```

## Preview the Website

```bash
python3 -m http.server 4173 --directory website
```

Then open `http://127.0.0.1:4173`.

Production website:

https://pastepaw.vercel.app
