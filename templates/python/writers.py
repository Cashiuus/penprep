




# Write to completd targets list
def save_all_targets_to_journal(journal, urls):
    with open(journal, 'wt') as f:
        for url in urls:
            f.write(f"{url}\n")
    print(f"[*] {len(urls)} written to journal file")
    return








