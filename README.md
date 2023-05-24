# Twitch VOD Transcriber and Searcher

This repository contains two scripts that facilitate transcription and keyword searching in Twitch VODs.

The transcribe.sh script downloads Twitch VODs, extracts the audio, and uses Vosk-Transcriber, an offline speech-to-text toolkit, to generate subtitles in both English and German.

The search.py script then performs a fuzzy search on these subtitle files, looking for specific words (applying stemming/fuzzing) defined within the script.

## Quick Start
1. Clone this repo.
2. `pip install -r requirements.txt`
3. Populate `urls.txt` file (refer `urls.example.txt`).
4. Download [vosk-transcriber models](https://alphacephei.com/vosk/models), if necessary edit the transcribe.sh
5. Run `./transcribe.sh` or `./transcribe.sh --download-only`
6. Edit terms in search.py 
7. Run `python search.py` to search in subtitles.

## Key Components
- `requirements.txt`: Python dependencies.
- `transcribe.sh`: Bash script to download VODs, extract audio, and transcribe to subtitles.
- `search.py`: Python script to search specific words in subtitles.
- `urls.example.txt`: Example input format for `transcribe.sh`.
