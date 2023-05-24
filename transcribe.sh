#!/bin/bash
# shellcheck disable=SC1083

set -e

# This script processes a set of video files specified in 'urls.txt'.
# Each line of 'urls.txt' should contain a pair of values separated by a semicolon: an id and a URL for the video file.
# The script downloads the video, extracts the audio, converts the audio to .wav format and transcribes the audio into both English and German.
# The transcriptions are saved as .srt files.
# 
# Usage:
# ./this_script.sh [--download-only]
# 
# If the '--download-only' flag is passed, the script will only download and convert the audio files without transcribing them.
# 
# Dependencies:
# This script relies on the following tools: ffmpeg, wget, vosk-transcriber
# Vosk is included in the requirements.txt: 
# pip install -r requirements.txt

cd "$(dirname "$0")"

source venv/bin/activate

DOWNLOAD_ONLY=false
if [ "$1" == "--download-only" ]; then
  DOWNLOAD_ONLY=true
fi

process_file() {
  local id=$1
  local url=$2
  local filename=$id
  local timestamp=$3

  echo "$id - $timestamp - Processing file" | tee -a run-"$timestamp".log

  # Download the file if it doesn't exist yet
  local mp4_filename="$filename.mp4"
  local audio_filename="${filename}.aac"
  local wav_filename="${filename}.wav"
  local srt_filename_de="${filename}-de.srt"
  local srt_filename_en="${filename}-en.srt"

  if [ ! -f "$audio_filename" ]; then
    if [ ! -f "$mp4_filename" ]; then
      echo "$id - $timestamp - Starting download" | tee -a run-"$timestamp".log
      trap 'echo "$id - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$mp4_filename"' EXIT
      wget "$url" -O "$mp4_filename"
      trap - EXIT
      echo "$id - $timestamp - Download completed" | tee -a run-"$timestamp".log
    fi
    # Extracting the audio
    echo "$id - $timestamp - Starting audio extraction" | tee -a run-"$timestamp".log
    trap 'echo "$id - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$audio_filename"' EXIT
    ffmpeg -i "$mp4_filename" -vn -acodec copy "$audio_filename"
    trap - EXIT
    echo "$id - $timestamp - Audio extraction completed" | tee -a run-"$timestamp".log
    # Deleting the original MP4 file
    rm "$mp4_filename"
  else
    echo "$id - $timestamp - Detected existing $audio_filename. Skipping download and extraction." | tee -a run-"$timestamp".log
  fi

  # Converting the audio file from .aac to .wav
  if [ ! -f "$wav_filename" ]; then
    echo "$id - $timestamp - Starting conversion to .wav" | tee -a run-"$timestamp".log
    trap 'echo "$id - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$wav_filename"' EXIT
    ffmpeg -i "$audio_filename" -acodec pcm_s16le -ac 1 -ar 16000 "$wav_filename"
    trap - EXIT
    echo "$id - $timestamp - Conversion to .wav completed" | tee -a run-"$timestamp".log
  else
    echo "$id - $timestamp - Detected existing $wav_filename. Skipping conversion." | tee -a run-"$timestamp".log
  fi

  # Transcribing using vosk-transcriber
  if [ "$DOWNLOAD_ONLY" = false ] ; then
    if [ ! -f "$srt_filename_de" ]; then
      echo "$id - $timestamp - Starting German transcription" | tee -a run-"$timestamp".log
      trap 'echo "$id - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$srt_filename_de"' EXIT
      vosk-transcriber -l de --model "vosk-model-de-0.21" -i "$wav_filename" -t srt -o "$srt_filename_de"
      trap - EXIT
      echo "$id - $timestamp - German transcription completed" | tee -a run-"$timestamp".log
    else
      echo "$id - $timestamp - Detected existing $srt_filename_de. Skipping German transcription." | tee -a run-"$timestamp".log
    fi

    if [ ! -f "$srt_filename_en" ]; then
      echo "$id - $timestamp - Starting English transcription" | tee -a run-"$timestamp".log
      trap 'echo "$id - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$srt_filename_en"' EXIT
      vosk-transcriber -l en --model "vosk-model-en-us-0.22" -i "$wav_filename" -t srt -o "$srt_filename_en"
      trap - EXIT
      echo "$id - $timestamp - English transcription completed" | tee -a run-"$timestamp".log
    else
      echo "$id - $timestamp - Detected existing $srt_filename_en. Skipping English transcription." | tee -a run-"$timestamp".log
    fi
  fi
}

export -f process_file
export DOWNLOAD_ONLY

timestamp=$(date "+%Y.%m.%d-%H:%M:%S")
parallel -j 2 --colsep ';' process_file {1} {2} "$timestamp" ::: "$(cat urls.txt)"
