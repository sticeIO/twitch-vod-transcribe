# Twitch VOD Transcriber and Searcher

Two scripts to transcribe Twitch VODs and search specific terms in the generated subtitles.

## Quick Start
1. Clone this repo.
2. `pip install -r requirements.txt`
3. Populate `urls.txt` file (refer `urls.example.txt`).
4. Run `./transcribe.sh` or `./transcribe.sh --download-only`
5. Edit terms in search.py 
6. Run `python search.py` to search in subtitles.

## Key Components
- `requirements.txt`: Python dependencies.
- `transcribe.sh`: Bash script to download VODs, extract audio, and transcribe to subtitles.
- `search.py`: Python script to search specific words in subtitles.
- `urls.example.txt`: Example input format for `transcribe.sh`.
