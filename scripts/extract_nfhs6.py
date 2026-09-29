"""Extract IIPS NFHS-6 India and State/UT fact-sheet indicators.

Usage: python scripts/extract_nfhs6.py path/to/fact_sheets.pdf
Requires pypdf. Run from the project root.
"""
import csv
import re
import sys
from pathlib import Path
from pypdf import PdfReader

STATES = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar",
    "Chhattisgarh", "Goa", "Gujarat", "Haryana", "Himachal Pradesh",
    "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra",
    "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab", "Rajasthan",
    "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh",
    "Uttarakhand", "West Bengal",
]
UTS = [
    "Andaman and Nicobar Islands", "Chandigarh",
    "Dadra and Nagar Haveli and Daman and Diu", "Jammu and Kashmir",
    "Ladakh", "Lakshadweep", "NCT of Delhi", "Puducherry",
]
UNITS = [("India", 26), *zip(STATES, range(31, 139, 4)),
         *zip(UTS, range(141, 173, 4))]
ROW = re.compile(r"^\s*(\d{1,3})\.\s*(.*)$")
VALUE = r"(?:\(?-?\d+(?:\.\d+)?\)?|\*|NA|na|N/A|…|-)"
FOUR = re.compile(rf"\s+({VALUE})\s+({VALUE})\s+({VALUE})\s+({VALUE})\s*$")
THREE = re.compile(rf"\s+({VALUE})\s+({VALUE})\s+({VALUE})\s*$")
ONE = re.compile(rf"\s+({VALUE})\s*$")


def extract(source: Path):
    reader = PdfReader(source)
    if len(reader.pages) < 171:
        raise ValueError("This does not appear to be the 182-page state compendium.")
    pages = {}
    for _, first in UNITS:
        for number in range(first, first + 3):
            page = reader.pages[number - 1]
            try:
                pages[number] = page.extract_text(extraction_mode="layout") or ""
            except Exception:
                pages[number] = page.extract_text() or ""
    records = []
    for unit, first in UNITS:
        found = {}
        for number in range(first, first + 3):
            lines = pages[number].splitlines()
            for i, line in enumerate(lines):
                match = ROW.match(line)
                if not match:
                    continue
                indicator, rest = int(match[1]), match[2]
                if not 1 <= indicator <= 101:
                    continue
                values = FOUR.search(rest)
                if values:
                    found[indicator] = (number, rest[:values.start()].strip(),
                                        *values.groups())
                    continue
                if i + 1 >= len(lines):
                    continue
                continuation = lines[i + 1]
                values = FOUR.search(continuation)
                if values:
                    found[indicator] = (
                        number, (rest + " " + continuation[:values.start()]).strip(),
                        *values.groups()
                    )
                    continue
                first_value, three_values = ONE.search(rest), THREE.search(continuation)
                if first_value and three_values:
                    # In the two wrapped vaccination rows, PDF text order places
                    # NFHS-5 Total before NFHS-6 Urban/Rural/Total.
                    label = (rest[:first_value.start()] + " " +
                             continuation[:three_values.start()]).strip()
                    found[indicator] = (
                        number, label, *three_values.groups(), first_value[1]
                    )
        if set(found) != set(range(1, 102)):
            raise ValueError(f"{unit}: missing indicators {sorted(set(range(1, 102))-set(found))}")
        for indicator, (number, label, urban, rural, total, old) in sorted(found.items()):
            records.append([unit, number, indicator, re.sub(r"\s+", " ", label),
                            urban, rural, total, old])
    return records


def numeric(cell):
    if cell in {"*", "NA", "na", "N/A", "…", "-"}:
        return None
    return float(cell.strip("()"))


def validate(records):
    assert len(records) == 36 * 101
    for unit, page, indicator, label, urban, rural, total, old in records:
        values = [numeric(cell) for cell in (urban, rural, total, old)]
        if indicator != 18 and any(v is not None and not 0 <= v <= 100 for v in values):
            raise ValueError(f"Invalid percentage at {unit}, {indicator}, PDF p. {page}")
        u, r, t, _ = values
        if all(v is not None for v in (u, r, t)) and not min(u, r)-.11 <= t <= max(u, r)+.11:
            raise ValueError(f"Total outside urban/rural range at {unit}, {indicator}")
    india = {row[2]: row[4:] for row in records if row[0] == "India"}
    assert india[12] == ["61.5", "39.7", "46.4", "41.0"]
    assert india[69] == ["23.9", "30.9", "29.3", "35.5"]


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python scripts/extract_nfhs6.py path/to/fact_sheets.pdf")
    records = extract(Path(sys.argv[1]))
    validate(records)
    output = Path("data/nfhs6_state_indicators.csv")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["unit", "pdf_page", "indicator_id", "indicator_label",
                         "nfhs6_urban", "nfhs6_rural", "nfhs6_total", "nfhs5_total"])
        writer.writerows(records)
    print(f"Wrote and validated {len(records)} indicator rows: {output}")


if __name__ == "__main__":
    main()
