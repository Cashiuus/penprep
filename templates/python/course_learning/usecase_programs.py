






def program_1():
    """
    A program to dictionary lookup a word entered by user.
    If user typo's the word, it can fuzzy guess and correct it for the user
    based on feedback from the user.

    # NOTE: difflib is a python built-in library for diffing, and looks like the basis
    for the fuzzywuzzy library, as it can do text comparisons and output a match ratio

    """
    import difflib
    # from difflib import SequenceMatcher
    import json
    import os
    import sys
    from pathlib import Path

    APP_BASE = Path(__file__).resolve(strict=True).parent

    if not os.path.isfile(APP_BASE / "data.json"):
        print("[!] This program requires the data.json file to function. Go get it!")
        sys.exit(1)

    # Load dataset
    dataset = json.load(open(APP_BASE / "data.json", 'r'))


    # Lookup the word
    def translate(word: str, dataset):
        # NOTE: Another way to handle word casing would be to test if word.title() is in data,
        # but our function will handle proper nouns by also getting close matches if not found up here
        convert_lower = True
        # if convert_lower:
            # word = word.lower()
        if word.lower() in dataset: # keys by default
            return dataset[word.lower()]
        elif word in dataset:
            return dataset[word]
        else:
            # returns matches that are 0.6 or greater ratio
            matches = difflib.get_close_matches(word, dataset.keys(), cutoff=0.8)
            # return matches
            while matches:
                response = input(f"[>>>] Word not found, did you mean {matches[0]} [Y/N]: ")
                if response in "YyYesyes":
                    if matches[0] in dataset:
                        return dataset[matches[0]]
                # else
                matches.pop([0])

        return "Word is not a valid word or is not in the dataset, sorry!"
    # -- End of Nested Lookup Function --

    response = input("[>>>] Enter word: ")

    # print(translate(response, dataset))
    results = translate(response, dataset)
    if results and isinstance(results, list):
        print("\nDefinitions:")
        for res in results:
            print(f"  - {res}")
    elif isinstance(results, str):
        print(results)
    return





def program_2():
    """
    Working with Pandas
    """
    import pandas as pd

    df1 = pd.DataFrame(
        # Each list inside this parent list is a row of data
        [
            ["tim", 12, 27],
            ["jason", 17, 34]
        ],
        columns=["name", "score", "age"],
        # This would be a first-column list of row headers
        # index=["First", "Second"],
    )

    # This way uses a dictionary
    df2 = pd.DataFrame(
        [
            {"Name": "Tim"},
            {"Name": "Jason"},
        ],
    )







if __name__ == '__main__':
    # program_1()
    program_2()

