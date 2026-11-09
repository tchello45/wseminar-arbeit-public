#!/usr/bin/env python3
"""NanoVNA-F V2: serial capture and reproducible S11 figures.

Protocol checked against the locally installed NanoVNA-Saver F_V2 driver.
Only the text-shell F_V2 is supported, not the binary-protocol S-A-A-2.
"""
from __future__ import annotations
import argparse
import csv
from datetime import datetime
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sys
import time

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
PROMPT = re.compile(rb"(?:^|[\r\n])ch> ?$")


class ProtocolError(RuntimeError):
    pass


class Device:
    def __init__(self, port, timeout=20, transport=None):
        if transport is None:
            import serial
            transport = serial.Serial(port, baudrate=115200, timeout=0.1,
                                      write_timeout=2, exclusive=True)
        self.io = transport
        self.timeout = timeout
        self.transcript = []
        self.info = {}

    def close(self):
        self.io.close()

    def command(self, command):
        self.io.reset_input_buffer()
        self.io.write((command + '\r').encode('ascii'))
        response = bytearray()
        deadline = time.monotonic() + self.timeout
        while time.monotonic() < deadline:
            response.extend(self.io.read(max(1, min(getattr(self.io, 'in_waiting', 0), 8192))))
            if PROMPT.search(response):
                raw = response.decode('ascii')
                self.transcript.append({'command': command, 'response': raw})
                lines = raw.replace('\r', '').split('\n')
                return [line.strip() for line in lines
                        if line.strip() and line.strip() != command
                        and not line.strip().startswith('ch>')]
            if len(response) > 2_000_000:
                raise ProtocolError('Antwort zu groß; falsches Gerät oder Protokoll.')
        raise ProtocolError(f'Keine vollständige Antwort auf {command!r} (Timeout).')

    def identify(self):
        info = '\n'.join(self.command('info'))
        if not re.search(r'NanoVNA[-_ ]F[-_ ]V2', info, re.IGNORECASE):
            raise ProtocolError('Kein NanoVNA-F V2 erkannt. Geräteantwort: ' + info)
        version = '\n'.join(self.command('version'))
        help_text = '\n'.join(self.command('help'))
        if not all(re.search(r'\b' + name + r'\b', help_text)
                   for name in ('scan', 'frequencies', 'data')):
            raise ProtocolError('Firmware bietet nicht alle benötigten Textbefehle.')
        self.info = {'model': 'NanoVNA-F V2', 'info': info, 'version': version,
                     'help': help_text, 'cal_state_response': '\n'.join(self.command('cal'))}
        return self.info

    def sweep(self, start, stop, points=101):
        # F_V2: blocking scan updates the internal arrays and stops continuous sweeping.
        answer = self.command(f'scan {start} {stop} {points}')
        if any(re.search(r'error|usage|unknown|invalid', line, re.I) for line in answer):
            raise ProtocolError('Scan abgelehnt: ' + '\n'.join(answer))
        frequencies = np.array([float(x) for x in self.command('frequencies')])
        rows = [x.split() for x in self.command('data 0')]
        if any(len(x) != 2 for x in rows):
            raise ProtocolError('S11-Antwort enthält keine Real-/Imaginärpaare.')
        gamma = np.array([complex(float(x[0]), float(x[1])) for x in rows])
        validate(frequencies, gamma)
        if len(frequencies) != points or not np.allclose(
                frequencies, np.linspace(start, stop, points), rtol=0, atol=1):
            raise ProtocolError('Geliefertes Frequenzraster passt nicht zum Auftrag.')
        return frequencies, gamma


def validate(f, g):
    if len(f) < 2 or len(f) != len(g):
        raise ValueError('Mindestens zwei Frequenzen und genau ein S11-Wert je Punkt nötig.')
    if not np.all(np.isfinite(f)) or not np.all(np.isfinite(g)):
        raise ValueError('Nichtendliche Messwerte werden nicht übernommen.')
    if np.any(np.diff(f) <= 0) or f[0] <= 0:
        raise ValueError('Frequenzen müssen positiv und streng aufsteigend sein.')


def values(g):
    mag = np.abs(g)
    with np.errstate(divide='ignore', invalid='ignore'):
        db = 20 * np.log10(mag)
        z = 50 * (1 + g) / (1 - g)
        vswr = (1 + mag) / (1 - mag)
    z = np.where(np.abs(1-g) < 1e-12, complex(np.nan, np.nan), z)
    vswr = np.where(mag < 1, vswr, np.nan)
    phase = np.where(mag >= 1e-3, np.angle(g, deg=True), np.nan)
    return mag, db, phase, z, vswr


def write_capture(folder, name, f, g, metadata, transcript):
    validate(f, g)
    folder.mkdir(parents=True, exist_ok=False)
    s1p = folder / (name + '.s1p')
    with s1p.open('x') as out:
        out.write('! NanoVNA-F V2; see metadata.json and serial.json\n# HZ S RI R 50\n')
        for freq, gamma in zip(f, g):
            out.write(f'{freq:.0f} {gamma.real:.17g} {gamma.imag:.17g}\n')
    mag, db, phase, z, vswr = values(g)
    def cell(v):
        return format(float(v), '.12g') if math.isfinite(float(v)) else ''
    with (folder / (name + '.csv')).open('x', newline='') as out:
        writer = csv.writer(out)
        writer.writerow(['frequency_hz', 's11_real', 's11_imag', 'magnitude',
                         's11_db', 'phase_deg', 'z_real_ohm', 'z_imag_ohm', 'vswr'])
        for row in zip(f, g.real, g.imag, mag, db, phase, z.real, z.imag, vswr):
            writer.writerow([cell(x) for x in row])
    meta = dict(metadata, timestamp=datetime.now().astimezone().isoformat(),
                sha256=hashlib.sha256(s1p.read_bytes()).hexdigest(),
                reference_impedance_ohm=50, sample_count=len(f),
                calibration='device output; no additional software correction',
                phase_display_threshold_magnitude=0.001,
                csv_undefined='empty cell; VSWR undefined for |Gamma| >= 1')
    (folder / 'metadata.json').write_text(json.dumps(meta, indent=2, ensure_ascii=False)+'\n')
    (folder / 'serial.json').write_text(json.dumps(transcript, indent=2, ensure_ascii=False)+'\n')
    return s1p


def load_s1p(path):
    rows = []
    header = False
    for line in path.read_text().splitlines():
        line = line.split('!')[0].strip()
        if not line:
            continue
        if line.startswith('#'):
            if header or rows:
                raise ValueError(f'{path}: genau eine Kopfzeile vor den Daten erwartet.')
            if line.upper().split() != ['#', 'HZ', 'S', 'RI', 'R', '50']:
                raise ValueError(f'{path}: unterstützt wird # HZ S RI R 50.')
            header = True
            continue
        if not header:
            raise ValueError(f'{path}: Touchstone-Header fehlt vor den Daten.')
        parts = line.split()
        if len(parts) != 3:
            raise ValueError(f'{path}: genau drei Spalten erwartet.')
        rows.append([float(x) for x in parts])
    if not header:
        raise ValueError(f'{path}: Touchstone-Header fehlt.')
    a = np.array(rows).reshape(-1, 3)
    f, g = a[:, 0], a[:, 1] + 1j*a[:, 2]
    validate(f, g)
    return f, g


def plot(paths, output, demo=False):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    curves = [(p.stem, *load_s1p(p)) for p in paths]
    for p in paths:
        metadata_path = p.parent/'metadata.json'
        if metadata_path.exists() and json.loads(metadata_path.read_text()).get('synthetic'):
            demo = True
    colors = ['#087f8c', '#e07a36', '#6054a6', '#b33d56', '#47834b']
    with plt.rc_context({'font.family': 'DejaVu Sans', 'font.size': 10,
                         'axes.spines.top': False, 'axes.spines.right': False,
                         'axes.labelcolor': '#293442', 'text.color': '#182b3a',
                         'axes.titleweight': 'bold', 'svg.fonttype': 'none'}):
        fig = plt.figure(figsize=(13, 8), facecolor='#f5f7fa', layout='constrained')
        grid = fig.add_gridspec(2, 2, width_ratios=[1.15, 1])
        smith = fig.add_subplot(grid[:, 0], aspect='equal')
        amp = fig.add_subplot(grid[0, 1])
        phase = fig.add_subplot(grid[1, 1])
        theta = np.linspace(0, 2*np.pi, 1200)
        smith.plot(np.cos(theta), np.sin(theta), color='#9caab5', lw=1)
        for r in [0.2, 0.5, 1, 2, 5]:
            smith.plot(r/(1+r)+np.cos(theta)/(1+r), np.sin(theta)/(1+r),
                       color='#dce3e9', lw=.7)
        for x in [-5, -2, -1, -.5, -.2, .2, .5, 1, 2, 5]:
            z = np.linspace(0, 200, 1500) + 1j*x
            trace = (z-1)/(z+1)
            smith.plot(trace.real, trace.imag, color='#dce3e9', lw=.7)
        smith.axhline(0, color='#dce3e9', lw=.8)
        for loc, label in [(-1, 'Short'), (0, '50 Ω'), (1, 'Open')]:
            smith.plot(loc, 0, '.', color='#8d9ca9')
            smith.annotate(label, (loc, 0), xytext=(0, -18), textcoords='offset points',
                           ha='center', fontsize=9, color='#637685')
        groups = {}
        for i, (name, f, g) in enumerate(curves):
            group = re.sub(r'_\d{2}$', '', name)
            first_in_group = group not in groups
            if first_in_group:
                groups[group] = colors[len(groups) % len(colors)]
            color = groups[group]
            _, db, ph, _, _ = values(g)
            label = group.replace('_', ' ') if first_in_group else '_nolegend_'
            smith.plot(g.real, g.imag, color=color, lw=1.7, label=label)
            smith.plot(g.real[0], g.imag[0], 'o', ms=4, color=color)
            amp.plot(f/1e9, db, color=color, lw=1.7, label=label)
            # Break the line at wrap boundaries, rather than draw false vertical jumps.
            ph = ph.copy()
            ph[np.r_[False, np.abs(np.diff(ph)) > 180]] = np.nan
            phase.plot(f/1e9, ph, color=color, lw=1.5)
        smith.set_title('Reflexion im Smith-Diagramm · 50 Ω', loc='left', pad=20)
        extent = max(1.12, max(float(np.abs(g).max()) for _, _, g in curves)*1.08)
        smith.set(xlim=(-extent, extent), ylim=(-extent, extent),
                  xlabel='Re Γ', ylabel='Im Γ')
        smith.spines[['top', 'right', 'left', 'bottom']].set_visible(False)
        smith.set_xticks([-1, 0, 1]); smith.set_yticks([-1, 0, 1])
        amp.set_title('Reflexionspegel', loc='left', pad=12)
        amp.set(ylabel='S11 = 20 log₁₀ |Γ| / dB', xlabel='Frequenz / GHz')
        phase.set_title('Reflexionsphase', loc='left', pad=12)
        phase.set(ylabel='arg Γ / Grad', xlabel='Frequenz / GHz', ylim=(-190, 190),
                  yticks=[-180, -90, 0, 90, 180])
        for ax in (amp, phase):
            ax.grid(True, color='#e1e7ee', lw=.7)
            ax.set_axisbelow(True)
        amp.legend(loc='best', fontsize=8, frameon=False)
        title = 'SYNTHETISCHE DEMO · keine Gerätemessung' if demo else 'NanoVNA-F V2 · S11-Messvergleich'
        fig.suptitle(title, fontsize=19, fontweight='bold', x=.035, ha='left')
        fig.supxlabel('Punkt im Smith-Diagramm: Startfrequenz. Phase bei |Γ| < 0,001 ausgeblendet.\n'
                      'Kalibrierung, Referenzebene und Aufbau: metadata.json jeder Messung.',
                      fontsize=9, color='#637685')
        output.parent.mkdir(parents=True, exist_ok=True)
        for suffix in ('png', 'svg', 'pdf'):
            target = output.with_suffix('.'+suffix)
            if target.exists():
                raise FileExistsError(f'Grafik existiert bereits: {target}')
        for suffix in ('png', 'svg', 'pdf'):
            fig.savefig(output.with_suffix('.'+suffix), dpi=180)
        plt.close(fig)


def ports():
    from serial.tools import list_ports
    return list(list_ports.comports())


def choose_port(port):
    if port:
        return port
    # Do not send commands to unrelated serial devices.
    matches = [p for p in ports() if (p.vid, p.pid) == (0x0483, 0x5740)]
    if len(matches) != 1:
        raise ValueError('Kein eindeutiger NanoVNA-USB-Port. Zuerst ports, dann --port verwenden.')
    return matches[0].device


def demo(output):
    output.mkdir(parents=True, exist_ok=False)
    f = np.linspace(2.3e9, 2.5e9, 101)
    paths = []
    for name, g in [('Open', .985*np.exp(-1j*2*np.pi*f*25e-12)),
                    ('Short', -.98*np.exp(-1j*2*np.pi*f*25e-12)),
                    ('Load', .012*np.exp(-1j*2*np.pi*f*.8e-9)),
                    ('Kabel_Open', .86*np.exp(-1j*2*np.pi*f*2.3e-9))]:
        paths.append(write_capture(output/name, name, f, g,
                                   {'synthetic': True, 'reference_plane': 'demo'}, []))
    plot(paths, output/'vorschau', demo=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest='action', required=True)
    subs.add_parser('ports', help='USB-Ports auflisten, ohne Geräte zu öffnen')
    p = subs.add_parser('probe', help='Gerät/Firmware/Kalibrierantwort lesen; kein Sweep')
    p.add_argument('--port')
    p.add_argument('--output', type=Path, default=ROOT/'daten/nanovna/probe.json')
    for action in ('measure', 'series'):
        p = subs.add_parser(action, help='Einzelmessung' if action == 'measure' else 'Geführte Standards-/Kabelreihe')
        p.add_argument('--port')
        p.add_argument('--start', type=int, default=2300000000)
        p.add_argument('--stop', type=int, default=2500000000)
        p.add_argument('--output', type=Path, default=ROOT/'daten/nanovna')
        p.add_argument('--calibration-note', required=True, help='Tatsächliche Gerätekalibrierung, Bereich, Zeitpunkt')
        p.add_argument('--reference-plane', required=True, help='z.B. Geräteport CH0 plus Adapter')
        p.add_argument('--setup', required=True, help='Kabel, Adapter, Aufbau und ggf. Foto-Datei')
        if action == 'measure':
            p.add_argument('--name', required=True)
    p = subs.add_parser('plot', help='Eigene RI/50-Ω-Touchstone-Dateien vergleichen')
    p.add_argument('files', nargs='+', type=Path)
    p.add_argument('--output', type=Path, required=True, help='Dateistamm ohne Endung')
    p = subs.add_parser('demo', help='Nur synthetische Daten; keine USB-Verbindung')
    p.add_argument('--output', type=Path, required=True)
    args = parser.parse_args(argv)
    if args.action == 'ports':
        found = ports()
        for port in found:
            print(f'{port.device}: {port.description} [{port.hwid}]')
        if not found:
            print('Keine seriellen Geräte gefunden.')
        return
    if args.action == 'demo':
        demo(args.output)
        print(args.output/'vorschau.png')
        return
    if args.action == 'plot':
        plot(args.files, args.output)
        return
    if args.action in ('measure', 'series'):
        if not 50000 <= args.start < args.stop <= 3000000000:
            parser.error('Erwartet: 50 kHz <= Start < Stop <= 3 GHz.')
        if args.action == 'measure' and not re.fullmatch(r'[A-Za-z0-9_-]+', args.name):
            parser.error('Messname: nur Buchstaben, Ziffern, _ und -.')
    device = Device(choose_port(args.port))
    try:
        info = device.identify()
        print(json.dumps(info, indent=2, ensure_ascii=False))
        if args.action == 'probe':
            args.output.parent.mkdir(parents=True, exist_ok=True)
            with args.output.open('x') as out:
                json.dump({'device': info, 'serial': device.transcript}, out, indent=2)
            print('Geräteabfrage gespeichert:', args.output)
            return
        print('\nGerätekalibrierung muss am angegebenen Messport und im Messbereich gültig sein.')
        print('Es wird keine Kalibrierung erzeugt oder als unabhängig geprüft behauptet.')
        if input('Zum Bestätigen KALIBRIERT eingeben: ').strip() != 'KALIBRIERT':
            raise ValueError('Ohne bestätigte Kalibrierung keine Messung.')
        session = args.output / datetime.now().astimezone().strftime('%Y%m%dT%H%M%S_%f')
        session.mkdir(parents=True, exist_ok=False)
        plan = [(args.name, 1)] if args.action == 'measure' else [
            (name, repeat) for name in ('Open', 'Short', 'Load', 'Kabel_Open', 'Kabel_Short')
            for repeat in range(1, 4)]
        paths = []
        for name, repeat in plan:
            if args.action == 'series':
                print(f'\n{name}, Anschluss {repeat}/3: Abschluss vollständig lösen und neu anschließen.')
                print('Bei Kabel_*: Kabel an der unveränderten Referenzebene; Abschluss am Kabelende.')
            answer = input(f'{name}: anschließen, Hände weg, dann Enter (q = beenden): ')
            if answer.strip().lower() == 'q':
                break
            first = len(device.transcript)
            f, g = device.sweep(args.start, args.stop)
            label = f'{name}_{repeat:02d}'
            meta = {'synthetic': False, 'device': info, 'name': name, 'repeat': repeat,
                    'reference_plane': args.reference_plane, 'setup': args.setup,
                    'calibration_note': args.calibration_note,
                    'requested_start_hz': args.start, 'requested_stop_hz': args.stop,
                    'standards_are_independent_accuracy_proof': False}
            path = write_capture(session/label, label, f, g, meta,
                                 {'identification': info, 'acquisition': device.transcript[first:]})
            paths.append(path)
            plot([path], path.parent/'abbildung')
            print('Gespeichert:', path)
        if paths:
            plot(paths, session/'vergleich')
            print('Messreihe und Grafiken:', session)
    finally:
        device.close()


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, RuntimeError, KeyboardInterrupt, EOFError) as exc:
        print(f'Abgebrochen: {exc}', file=sys.stderr)
        sys.exit(1)
