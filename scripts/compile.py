"""Baue die einzige PDF-Ausgabe arbeit.pdf aus dem aktuellen Quellstand."""
from pathlib import Path
import os
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
output = root / "arbeit.pdf"
if shutil.which("typst"):
    # Reproduzierbare Metadaten bei unverändertem Text-/Listingstand.
    inputs = [p for p in (root / "arbeit").rglob("*")
              if p.suffix in (".typ", ".bib", ".py")]
    env = dict(os.environ)
    env.setdefault("SOURCE_DATE_EPOCH", str(int(max(p.stat().st_mtime for p in inputs))))
    subprocess.run(["typst", "compile", "--root", str(root / "arbeit"),
                    str(root / "arbeit/main.typ"), str(output)], check=True, env=env)
else:
    import typst
    try:
        typst.compile(str(root / "arbeit/main.typ"), output=str(output), root=str(root / "arbeit"))
    except typst.TypstError as error:
        raise SystemExit(error.diagnostic) from error
print(output)
