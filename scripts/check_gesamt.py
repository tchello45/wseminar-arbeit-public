#!/usr/bin/env python3
"""Offline-Gesamtprüfung in isolierter Kopie; Originaldaten bleiben erhalten.

Aufruf aus dem Projektstamm: tools/.venv/bin/python scripts/check_gesamt.py
Benötigt Cargo mit gecachten Lockfile-Abhängigkeiten, Typst und Poppler.
Die visuelle Endkontrolle und externe Quellenlektüre bleiben gesonderte Schritte.
"""
from pathlib import Path
import argparse
import csv
from datetime import datetime, timezone
import hashlib
import importlib.util
import io
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def compare_rust_csv(previous_path, current_text):
    """Compare scientific values and statuses, allowing decimal formatting changes."""
    with previous_path.open() as stream:
        old = list(csv.DictReader(stream))
    new = list(csv.DictReader(io.StringIO(current_text)))
    assert len(old) == len(new) == 101, previous_path
    for previous, current in zip(old, new):
        assert previous.keys() == current.keys(), previous_path
        for key, value in previous.items():
            if key.endswith('_status') or value == '':
                assert current[key] == value, (previous_path, key)
            else:
                assert math.isclose(float(value), float(current[key]), rel_tol=1e-9, abs_tol=1e-9), (previous_path, key)
    return len(new)


def compare_svg(a, b):
    # Ignore only generated dates and arbitrary internal ID names; keep text,
    # geometry, colors, transforms, paths and referenced-ID relationships.
    def normalized(path):
        tree = ET.fromstring(path.read_bytes())
        ids = {node.attrib['id']: f'id{i}' for i, node in enumerate(tree.iter()) if 'id' in node.attrib}
        def item(node):
            if node.tag.endswith('}date'):
                return None
            attrs = {}
            for key, value in node.attrib.items():
                if key == 'id':
                    value = ids[value]
                else:
                    value = re.sub(r'url\(#([^)]*)\)', lambda m: 'url(#' + ids[m[1]] + ')', value)
                    if key.endswith('}href') and value.startswith('#'):
                        value = '#' + ids[value[1:]]
                attrs[key] = value
            children = [x for child in node if (x := item(child)) is not None]
            return node.tag, sorted(attrs.items()), (node.text or '').strip(), children
        return item(tree)
    assert normalized(a) == normalized(b), f'SVG-Inhalt abweichend: {a}'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT/'nachweise/gesamtpruefung')
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    result = {'created_utc': datetime.now(timezone.utc).isoformat(), 'steps': [],
              'scope': 'Offline-Software, Datenintegrität, Reproduktion und PDF-Bau; keine neue Hardwaremessung'}
    source_files = list((ROOT/'arbeit').rglob('*.typ')) + list((ROOT/'scripts').glob('*.py'))
    source_files += list((ROOT/'tools/src/simulation').glob('*.py')) + list((ROOT/'tools/tests').glob('*.py'))
    source_files += list((ROOT/'auswertung/src').glob('*.rs')) + list((ROOT/'auswertung/tests').glob('*.rs'))
    source_files += [p for p in (ROOT/'arbeit/abbildungen').iterdir() if p.suffix in ('.svg', '.png', '.json')]
    source_files += list((ROOT/'arbeit').rglob('*.py')) + list((ROOT/'arbeit').rglob('*.bib'))
    source_files += [ROOT/'arbeit/export-quellen.json']
    source_files += [ROOT/'literatur.bib', ROOT/'tools/uv.lock', ROOT/'auswertung/Cargo.toml', ROOT/'auswertung/Cargo.lock']
    result['input_sha256'] = {str(p.relative_to(ROOT)): sha(p) for p in sorted(source_files)}
    with tempfile.TemporaryDirectory(prefix='wseminar-check-') as tmp:
        work = Path(tmp)/'project'
        shutil.copytree(ROOT, work, ignore=shutil.ignore_patterns('.git', '.venv', 'target', '__pycache__', '.ruff_cache', 'gesamtpruefung'))
        env = dict(os.environ, PYTHONPATH=str(work/'tools/src'), MPLCONFIGDIR=str(Path(tmp)/'mpl'),
                   CARGO_TARGET_DIR=str(Path(tmp)/'cargo'))
        def run(name, command):
            completed = subprocess.run(command, cwd=work, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            (out/(name+'.log')).write_text(completed.stdout)
            result['steps'].append({'name': name, 'command': [str(x) for x in command], 'returncode': completed.returncode})
            if completed.returncode:
                raise RuntimeError(f'{name} fehlgeschlagen; siehe {out/(name+".log")}')
            print(name + ': bestanden', flush=True)
            return completed.stdout
        run('python-tests', [sys.executable, '-m', 'unittest', 'discover', '-s', 'tools/tests', '-v'])
        run('rust-tests', ['cargo', 'test', '--locked', '--offline', '--manifest-path', 'auswertung/Cargo.toml'])
        run('rust-clippy', ['cargo', 'clippy', '--locked', '--offline', '--manifest-path', 'auswertung/Cargo.toml', '--all-targets', '--', '-D', 'warnings'])
        run('rust-format', ['cargo', 'fmt', '--manifest-path', 'auswertung/Cargo.toml', '--check'])
        run('grundlagen', [sys.executable, 'scripts/check_grundlagen.py'])
        run('css-theorie', [sys.executable, 'scripts/check_css_theorie.py'])
        run('pcb-entwurf', [sys.executable, 'scripts/check_pcb_entwurf.py'])
        for name in ('pcb-ifa-prinzip.svg', 'pcb-lc-anpassung.svg'):
            compare_svg(ROOT/'arbeit/abbildungen'/name, work/'arbeit/abbildungen'/name)
        run('mittwoch-pilot', [sys.executable, 'scripts/review_mittwoch.py'])
        run('chirp-fft', [sys.executable, '-m', 'simulation.css'])
        for name in ('css-referenzchirp', 'css-symbol-fft'):
            a = ROOT/'tools/src/simulation/ergebnisse'
            b = work/'tools/src/simulation/ergebnisse'
            compare_svg(a/(name+'.svg'), b/(name+'.svg'))
            assert np.array_equal(np.asarray(Image.open(a/(name+'.png'))), np.asarray(Image.open(b/(name+'.png')))), name
        run('kapitel6', [sys.executable, 'scripts/check_kapitel6.py'])
        shutil.copyfile(work/'nachweise/KAPITEL06-pruefung.json', out/'kapitel6.json')
        replay = work/'replay'
        run('awgn-replay', [sys.executable, '-m', 'simulation.basis', '--bandwidth-hz', '125000', '--output', str(replay)])
        run('offset-replay', [sys.executable, '-m', 'simulation.offset_campaign', '--bandwidth-hz', '125000', '--output', str(replay)])
        original = ROOT/'tools/src/simulation/ergebnisse'
        for name in ('css-awgn.csv', 'css-awgn-energy.csv', 'css-offset-awgn.csv', 'symbolparameter.csv'):
            # CLI defaults may serialize bandwidth as 125000 versus 125000.0.
            assert (original/name).read_text().splitlines()[0] == (replay/name).read_text().splitlines()[0]
            np.testing.assert_array_equal(np.loadtxt(original/name, delimiter=',', skiprows=1),
                                          np.loadtxt(replay/name, delimiter=',', skiprows=1))
        compared = ['css-referenzchirp', 'css-symbol-fft']
        for name in ('css-awgn', 'css-awgn-energy', 'css-offset-awgn', 'css-dechirping', 'dipol-referenzen'):
            compare_svg(original/(name+'.svg'), replay/(name+'.svg'))
            if (original/(name+'.png')).exists():
                assert np.array_equal(np.asarray(Image.open(original/(name+'.png'))), np.asarray(Image.open(replay/(name+'.png')))), name
            compared.append(name)
        rust = Path(env['CARGO_TARGET_DIR'])/'debug/auswertung'
        vna_out = work/'vna-replay'
        run('nanovna-replay', [sys.executable, 'scripts/auswertung_nanovna.py', '--output', str(vna_out), '--rust-binary', str(rust)])
        vna_original = ROOT/'daten/auswertung/kapitel7'
        for name in ('aufbau', 'standards', 'kabel'):
            compare_svg(vna_original/(name+'.svg'), vna_out/(name+'.svg'))
            compared.append(name)
        for name in ('tabelle.typ', 'betragsbereiche.csv'):
            assert (vna_original/name).read_bytes() == (vna_out/name).read_bytes(), name
        # Formatting may differ between Rust implementations; compare every
        # numeric value and status against the previously published exports.
        rust_export_points = 0
        for path in sorted(vna_out.glob('*-rust.csv')):
            rust_export_points += compare_rust_csv(vna_original/path.name, path.read_text())
        assert rust_export_points == 1818
        a = json.loads((vna_original/'rechenwerte.json').read_text())
        b = json.loads((vna_out/'rechenwerte.json').read_text())
        assert a == b, 'Kapitel-7-Rechenwerte'
        shutil.copyfile(vna_out/'rechenwerte.json', out/'nanovna.json')
        # Replay serial source responses and derived acquisition CSVs.
        spec = importlib.util.spec_from_file_location('nanovna_check', work/'scripts/nanovna.py')
        vna = importlib.util.module_from_spec(spec); spec.loader.exec_module(vna)
        acquisition_count = 0
        raw_paths = list((work/'daten/nanovna').rglob('*.s1p'))
        raw_paths += [work/'nachweise/RS02-geraet-2026-11-05/frozen-buffer/geraeteabgleich.s1p']
        for path in raw_paths:
            if not (path.parent/'serial.json').exists():
                continue
            serial = json.loads((path.parent/'serial.json').read_text())
            commands = serial['acquisition'] if isinstance(serial, dict) else serial
            replies = {row['command']: row['response'] for row in commands}
            if 'frequencies' not in replies or 'data 0' not in replies:
                continue
            def lines(command):
                return [line.strip() for line in replies[command].replace('\r','').splitlines()
                        if line.strip() and line.strip() != command and not line.strip().startswith('ch>')]
            f, g = vna.load_s1p(path)
            np.testing.assert_array_equal(f, np.array(lines('frequencies'),float))
            pairs = np.loadtxt(io.StringIO('\n'.join(lines('data 0'))))
            np.testing.assert_array_equal(g, pairs[:,0]+1j*pairs[:,1])
            meta = json.loads((path.parent/'metadata.json').read_text())
            assert sha(path) == meta['sha256']
            csv_path = path.with_suffix('.csv')
            if csv_path.exists():
                rows = list(csv.DictReader(csv_path.open()))
                expected = [f,g.real,g.imag,*vna.values(g)[:3],vna.values(g)[3].real,vna.values(g)[3].imag,vna.values(g)[4]]
                cols = ['frequency_hz','s11_real','s11_imag','magnitude','s11_db','phase_deg','z_real_ohm','z_imag_ohm','vswr']
                for key, values in zip(cols,expected):
                    actual = np.array([float(row[key]) if row[key] else np.nan for row in rows])
                    np.testing.assert_allclose(actual, values, rtol=1e-10, atol=1e-10, equal_nan=True)
            acquisition_count += 1
        assert acquisition_count == 19, acquisition_count
        # Additional frozen LCD-marker comparison, including all 101 Rust rows.
        frozen = work/'nachweise/RS02-geraet-2026-11-05/frozen-buffer/geraeteabgleich.s1p'
        text = run('marker-rust', [str(rust), '--import', str(frozen)])
        rows = list(csv.DictReader(io.StringIO(text)))
        f, g = vna.load_s1p(frozen)
        for row, freq, gamma in zip(rows, f, g):
            z = 50*(1+gamma)/(1-gamma)
            for key, expected in dict(frequency_hz=freq, s11_re=gamma.real,s11_im=gamma.imag,
                    magnitude=abs(gamma),phase_deg=np.angle(gamma,deg=True),s11_db=20*np.log10(abs(gamma)),
                    z_re_ohm=z.real,z_im_ohm=z.imag,vswr=(1+abs(gamma))/(1-abs(gamma))).items():
                assert np.isclose(float(row[key]),expected,rtol=1e-9,atol=1e-9), key
        marker = next(row for row in rows if float(row['frequency_hz'])==2.4e9)
        assert abs(float(marker['s11_db'])-(-.52)) <= .005
        assert len(rows)==101
        commands = json.loads((work/'nachweise/RS02-geraet-2026-11-05/frozen-commands.json').read_text())
        buffers = [row['response'] for row in commands if row['command'] == 'data 0']
        assert len(buffers) >= 2 and len(set(buffers)) == 1, 'Frozen buffer changed'
        pilot_points = 0
        for name in ('01', '02', '03'):
            text = run('pilot-rust-' + name, [str(rust), '--import', str(work/f'daten/roh/{name}.s1p')])
            pilot_points += compare_rust_csv(work/f'daten/auswertung/{name}-s11.csv', text)
        assert pilot_points == 303
        # Published figures must match their provenance and all Typst image paths
        # must stay inside arbeit/abbildungen, including paths in other chapters.
        figure_dir = work/'arbeit/abbildungen'
        manifest = json.loads((figure_dir/'quellen.json').read_text())
        for name, record in manifest.items():
            assert sha(figure_dir/name) == record['sha256']
            assert (figure_dir/name).read_bytes() == (work/record['source']).read_bytes(), name
        published_before = {name: sha(figure_dir/name) for name in manifest}
        run('abbildungen-export', [sys.executable, 'scripts/export_abbildungen.py'])
        assert published_before == {name: sha(figure_dir/name) for name in manifest}
        image_paths = []
        for path in (work/'arbeit').rglob('*.typ'):
            for relative in re.findall(r'image\(\s*"([^\"]+)"', path.read_text()):
                target = (path.parent/relative).resolve()
                assert target.is_relative_to(figure_dir.resolve()), (path, relative)
                assert target.is_file(), target
                image_paths.append(str(target.relative_to(work)))
        assert len(image_paths) == 10, image_paths
        export_manifest = json.loads((work/'arbeit/export-quellen.json').read_text())
        for name, record in export_manifest.items():
            target = work/'arbeit'/name
            assert sha(target) == record['sha256'], name
            assert target.read_bytes() == (work/record['source']).read_bytes(), name
        # Citation keys and included assets must resolve; labels are not citations.
        bib = (work/'arbeit/literatur.bib').read_text()
        keys = set(re.findall(r'^@\w+\{([^,]+),',bib,re.M))
        cited = set()
        for path in (work/'arbeit').rglob('*.typ'):
            if path.name == 'arbeitsmarker.typ' or 'vendor' in path.parts:
                continue
            text = path.read_text()
            assert '#aufgabe(' not in text, path
            cited.update(re.findall(r'@(?:lit:)?([\w-]+)',text))
            cited.update(re.findall(r'#cite\(<(?:lit:)?([\w-]+)>',text))
            for relative in re.findall(r'(?:image|include|read)\("([^\"]+)"',text):
                assert (path.parent/relative).exists(), (path,relative)
        labels = set()
        for path in list((work/'arbeit').rglob('*.typ')) + list((work/'daten/auswertung').rglob('*.typ')):
            labels.update(re.findall(r'<([\w-]+)>',path.read_text()))
        assert not (cited-keys-labels), cited-keys-labels
        groups = json.loads((work/'arbeit/literaturgruppen.json').read_text())
        grouped = [key for group in groups for key in group['keys']]
        assert len(grouped) == len(set(grouped)), 'Quelle in mehreren Literaturgruppen'
        assert set(grouped) == cited & keys, 'Literaturgruppen müssen den tatsächlich zitierten Quellen entsprechen'

        run('pdf-build', [sys.executable, 'scripts/compile.py'])
        # This directory contains only arbeit/, without tools/, daten/, scripts/
        # or the root bibliography. Typst must build with that directory as root.
        standalone = Path(tmp)/'standalone'
        shutil.copytree(work/'arbeit', standalone)
        inputs = [p for p in standalone.rglob('*') if p.suffix in ('.typ', '.bib', '.py')]
        epoch = env.get('SOURCE_DATE_EPOCH', str(int(max(p.stat().st_mtime for p in inputs))))
        standalone_pdf = Path(tmp)/'standalone.pdf'
        run('standalone-build', ['typst', 'compile', '--root', str(standalone),
                                '--creation-timestamp', epoch, str(standalone/'main.typ'), str(standalone_pdf)])
        assert sha(standalone_pdf) == sha(work/'arbeit.pdf'), 'Isolierter arbeit/-Build weicht ab'
        assert sha(ROOT/'arbeit.pdf') == sha(work/'arbeit.pdf'), 'Projekt-PDF muss aus aktuellem Quelltext gebaut sein'
        result.update(status='passed', campaign_points=135, symbol_trials=675000,
                      measurement_points=1818, marker_points=101, serial_acquisitions=acquisition_count,
                      rust_export_comparison_points=rust_export_points,
                      pilot_rust_comparison_points=pilot_points,
                      graphics_content_compared=compared, cited_bibliography_keys=sorted(cited & keys),
                      local_image_paths=image_paths, standalone_arbeit_build=True,
                      pdf_sha256=sha(work/'arbeit.pdf'))
    (out/'pruefung.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
    print('Gesamtprüfung bestanden:', out/'pruefung.json')


if __name__ == '__main__':
    main()
