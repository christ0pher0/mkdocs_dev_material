#!/usr/bin/env python3
"""
generate_concerts.py
Reads Bands_Ive_Seen.ods and generates a MkDocs markdown page
Usage: python3 generate_concerts.py [path_to_ods] [output_path]
"""
import pandas as pd
import sys
import os

# CONFIG
DEFAULT_INPUT  = "/home/cos/Bands_Ive_Seen.ods"
DEFAULT_OUTPUT = "/home/cos/material/mkdocs_dev_material/docs/concerts.md"

input_file  = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_INPUT
output_file = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_OUTPUT

# READ
df = pd.read_excel(input_file, engine='odf')

# CLEAN DATE
def clean_date(row):
    date = pd.to_datetime(row['Date'], errors='coerce')
    if pd.isna(date):
        try:
            year = str(row['Date'])[:4]
            if year.isdigit():
                return year
        except:
            pass
        return 'Unknown'
    if date.year == 1970:
        try:
            year = str(row['Date'])[:4]
            if year.isdigit() and year != '1970':
                return year
        except:
            pass
        return 'Unknown'
    return date.strftime('%Y-%m-%d')

df['Date_clean'] = df.apply(clean_date, axis=1)
df['Year'] = pd.to_datetime(df['Date'], errors='coerce').dt.year.fillna(0).astype(int)
df['BAND']            = df['BAND'].fillna('Unknown')
df['Venue']           = df['Venue'].fillna('')
df['Tour']            = df['Tour'].fillna('')
df['Odd Occurrences'] = df['Odd Occurrences'].fillna('')
df['Setlist']         = df['Setlist'].fillna('')

def get_decade(year):
    if year == 0:
        return 'Unknown'
    return f"{(year // 10) * 10}s"

df['Decade'] = df['Year'].apply(get_decade)
df_sorted = df.sort_values('Year', ascending=True)

decade_order = ['1970s', '1980s', '1990s', '2000s', '2010s', '2020s', 'Unknown']

lines = []
lines.append('# Concerts I Have Seen\n')
lines.append(f'_Total shows: {len(df)}_\n')
lines.append('')

for decade in decade_order:
    subset = df_sorted[df_sorted['Decade'] == decade]
    if subset.empty:
        continue
    lines.append(f'??? info "{decade} ({len(subset)} shows)"')
    lines.append('')
    lines.append('    | Date | Band | Venue | Tour | Lore | Setlist |')
    lines.append('    |------|------|-------|------|-------|---------|')
    for _, row in subset.iterrows():
        date    = str(row['Date_clean'])
        band    = str(row['BAND']).replace('|', '-')
        venue   = str(row['Venue']).replace('|', '-')
        tour    = str(row['Tour']).replace('|', '-')
        notes   = str(row['Odd Occurrences']).replace('|', '-')
        setlist = str(row['Setlist'])
        setlist_cell = f'[setlist]({setlist})' if setlist and setlist != 'nan' else ''
        lines.append(f'    | {date} | {band} | {venue} | {tour} | {notes} | {setlist_cell} |')
    lines.append('')

os.makedirs(os.path.dirname(output_file), exist_ok=True)
with open(output_file, 'w') as f:
    f.write('\n'.join(lines))

print(f"Done! {len(df)} shows written to {output_file}")
