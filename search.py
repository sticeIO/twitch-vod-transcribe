import csv
import os
import pysrt
import datetime
from fuzzywuzzy import fuzz
from nltk.stem import SnowballStemmer

# Usage:
# This script is used for searching specific words in a directory of SRT files and writing the results to a CSV file.
#
# Parameters:
# search_words: A list of words to search for.
# threshold: The threshold for the fuzzy matching. It defines how similar the word in the SRT file has to be to the search word to count as a match.
# srt_directory: The directory where the SRT files are located.
#
# Expected File Format:
# The script expects the SRT files to be in the standard SRT format.
#
# Dependencies:
# pip install -r requirements.txt

# Defining the stemmers.
stemmer_de = SnowballStemmer("german")
stemmer_en = SnowballStemmer("english")

# List of search words.
search_words = ["serach_term", "search_term_two"]
stemmed_search_words_de = [stemmer_de.stem(word) for word in search_words]
stemmed_search_words_en = [stemmer_en.stem(word) for word in search_words]

# Fuzzy matching threshold.
threshold = 90

# Directory of SRT files.
srt_directory = './srts'

def format_time_for_link(time):
    return f"{time.hour}h{time.minute}m{time.second}s"

# Function to write a row in the CSV file.
def write_csv_row(writer, filename, context, start_time, end_time, trust):
    formatted_start_time = format_time_for_link(start_time)

    # Remove the "-de.srt" or "-en.srt" from the filename
    cleaned_filename = filename.replace("-de.srt", "").replace("-en.srt", "")

    link = f"https://www.twitch.tv/videos/{cleaned_filename}?t={formatted_start_time}"

    writer.writerow({
        'filename': filename,
        'context': context,
        'start_time': start_time,
        'end_time': end_time,
        'link': link,
        'trust': trust
    })

# Function to search for matches in a text.
def search_matches(text, stemmed_search_words):
    words = text.lower().split()
    max_score = 0
    for word in stemmed_search_words:
        for text_word in words:
            score = fuzz.ratio(word, text_word)
            if score > max_score:
                max_score = score
    return max_score if max_score > threshold else 0

def traverse_subs(subs, stemmed_search_words, writer, filename):
    i = 0
    while i < len(subs):
        # Combine the current subtitle and the next subtitle.
        if i + 1 < len(subs):
            context = subs[i].text + " " + subs[i + 1].text
        else:
            context = subs[i].text

        score = search_matches(context, stemmed_search_words)
        if score > 0:
            start_time = subs[i].start.to_time()
            end_time = (subs[i + 1].end.to_time() if i + 1 < len(subs) else subs[i].end.to_time())

            write_csv_row(writer, filename, context, start_time, end_time, score)
            # Skip the next subtitle as it has already been included in the context.
            i += 2
        else:
            i += 1

with open('output.csv', 'w', newline='') as csvfile:
    fieldnames = ['filename', 'context', 'start_time', 'end_time', 'link', 'trust']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

    writer.writeheader()

    for filename in os.listdir(srt_directory):
        if filename.endswith('.srt'):
            if '-de.srt' in filename:
                stemmed_search_words = stemmed_search_words_de
            elif '-en.srt' in filename:
                stemmed_search_words = stemmed_search_words_en
            else:
                continue

            start_time = datetime.datetime.now()
            print(f"Start processing {filename} at {start_time}")

            subs = pysrt.open(os.path.join(srt_directory, filename))

            traverse_subs(subs, stemmed_search_words, writer, filename)

            end_time = datetime.datetime.now()
            print(f"Finished processing {filename} at {end_time}")
            print(f"Processing time: {end_time - start_time}\n")
