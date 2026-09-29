"""Check the bundled NFHS-6 portfolio from its project root (stdlib only)."""

import csv
import re
import struct
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def csv_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


raw = csv_rows(ROOT / "data/nfhs6_state_indicators.csv")
assert len(raw) == 3636, "Unexpected consolidated CSV row count"
per_unit = Counter(row["unit"] for row in raw)
assert len(per_unit) == 36 and set(per_unit.values()) == {101}
for unit in per_unit:
    ids = {int(row["indicator_id"]) for row in raw if row["unit"] == unit}
    assert ids == set(range(1, 102)), f"Missing or duplicate indicators: {unit}"

summaries = csv_rows(ROOT / "results/all_questions_summary.csv")
assert len(summaries) == 4 and all(int(row["n"]) == 27 for row in summaries)
comparisons = csv_rows(ROOT / "results/all_model_comparisons.csv")
assert len(comparisons) == 16
assert all(int(row["n"]) == 27 for row in comparisons)
descriptives = csv_rows(ROOT / "results/descriptive_statistics.csv")
assert len(descriptives) == 8
diagnostics = csv_rows(ROOT / "results/model_diagnostics.csv")
assert len(diagnostics) == 4
membership = csv_rows(ROOT / "results/cluster_membership.csv")
assert len(membership) == 27

def check_png(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"Invalid PNG: {path}"
    width, height = struct.unpack(">II", data[16:24])
    assert width >= 800 and height >= 600, f"Image too small: {path}"


figures = sorted((ROOT / "figures").glob("*.png"))
screenshots = sorted((ROOT / "screenshots").glob("*.png"))
assert len(figures) == 20 and len(screenshots) == 6
for path in figures + screenshots:
    check_png(path)

tex = (ROOT / "report/report.tex").read_text(encoding="utf-8")
refs = re.findall(r"\\includegraphics\[[^]]+\]\{([^}]+)\}", tex)
assert refs and all((ROOT / "figures" / ref).is_file() for ref in refs)
stack = []
for kind, name in re.findall(r"\\(begin|end)\{([^}]+)\}", tex):
    if kind == "begin":
        stack.append(name)
    else:
        assert stack and stack.pop() == name, f"Unmatched LaTeX environment: {name}"
assert not stack, f"Unclosed LaTeX environments: {stack}"

print(
    f"Checks passed: {len(raw)} CSV rows, {len(summaries)} questions, "
    f"{len(figures)} figures, {len(screenshots)} R result images, "
    f"{len(refs)} LaTeX figure references."
)
