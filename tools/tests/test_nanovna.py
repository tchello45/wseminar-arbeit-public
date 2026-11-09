"""Protocol and data-integrity checks; no physical hardware evidence."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import numpy as np

spec = importlib.util.spec_from_file_location('nanovna', Path(__file__).parents[2]/'scripts/nanovna.py')
vna = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vna)

class Serial:
    def __init__(self, replies):
        self.replies = replies
        self.buffer = b''
        self.written = []
    def reset_input_buffer(self): self.buffer = b''
    def write(self, value):
        command = value.decode().strip()
        self.written.append(command)
        self.buffer = self.replies[command]
    def read(self, size):
        # Force split prompts and split CRLF boundaries.
        result, self.buffer = self.buffer[:2], self.buffer[2:]
        return result
    def close(self): pass

def reply(command, lines):
    return (command+'\r\n'+'\r\n'.join(lines)+'\r\nch> ').encode()

class Checks(unittest.TestCase):
    def test_partial_prompt_and_echo(self):
        dev = vna.Device('', transport=Serial({'version': reply('version', ['0.5.8'])}))
        self.assertEqual(dev.command('version'), ['0.5.8'])
        self.assertIn('ch>', dev.transcript[0]['response'])
    def test_unrecognized_model_rejected(self):
        dev = vna.Device('', transport=Serial({'info': reply('info', ['NanoVNA-H'])}))
        with self.assertRaises(vna.ProtocolError): dev.identify()
    def test_complete_sweep_and_grid(self):
        replies = {x: reply(x, y) for x, y in [
            ('scan 100 200 3', []), ('frequencies', ['100', '150', '200']),
            ('data 0', ['1 0', '0 0', '-1 0'])]}
        dev = vna.Device('', transport=Serial(replies))
        f, g = dev.sweep(100, 200, 3)
        np.testing.assert_array_equal(g, [1, 0, -1])
        self.assertEqual(len(f), 3)
    def test_wrong_grid_rejected(self):
        replies = {x: reply(x, y) for x, y in [
            ('scan 100 200 3', []), ('frequencies', ['100', '151', '203']),
            ('data 0', ['1 0']*3)]}
        with self.assertRaises(vna.ProtocolError):
            vna.Device('', transport=Serial(replies)).sweep(100, 200, 3)
    def test_scan_error_rejected(self):
        cmd = 'scan 100 200 3'
        dev = vna.Device('', transport=Serial({cmd: reply(cmd, ['usage: scan start stop'])}))
        with self.assertRaises(vna.ProtocolError): dev.sweep(100, 200, 3)
    def test_timeout(self):
        dev = vna.Device('', timeout=.01, transport=Serial({'info': b'incomplete'}))
        with self.assertRaises(vna.ProtocolError): dev.command('info')
    def test_invalid_values_rejected(self):
        for f, g in [([1, 1], [0, 0]), ([1, 2], [0, float('nan')]),
                     ([1, 2], [0]), ([0, 1], [0, 0])]:
            with self.assertRaises(ValueError): vna.validate(np.array(f), np.array(g))
    def test_touchstone_roundtrip_and_no_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)/'capture'
            f = np.array([2.3e9, 2.5e9]); g = np.array([.1+.2j, -.9j])
            path = vna.write_capture(folder, 'test', f, g, {'synthetic': True}, [])
            ff, gg = vna.load_s1p(path)
            np.testing.assert_array_equal(ff, f)
            np.testing.assert_array_equal(gg, g)
            with self.assertRaises(FileExistsError):
                vna.write_capture(folder, 'test', f, g, {}, [])
    def test_wrong_header_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)/'wrong.s1p'
            path.write_text('# MHZ S DB R 50\n100 1 0\n200 1 0\n')
            with self.assertRaises(ValueError): vna.load_s1p(path)
    def test_header_must_precede_data_and_be_unique(self):
        header = '# HZ S RI R 50\n'
        for content in ('100 1 0\n' + header + '200 1 0\n',
                        header + header + '100 1 0\n200 1 0\n',
                        header + '100 1 0\n' + header + '200 1 0\n'):
            with self.subTest(content=content), tempfile.TemporaryDirectory() as tmp:
                path = Path(tmp) / 'invalid.s1p'
                path.write_text(content)
                with self.assertRaises(ValueError):
                    vna.load_s1p(path)

    def test_hand_cases_and_singularities(self):
        mag, db, phase, z, vswr = vna.values(np.array([0, -1, 1, .5, 1.1], complex))
        self.assertEqual(z[0], 50)
        self.assertEqual(z[1], 0)
        self.assertTrue(np.isnan(z[2]))
        self.assertEqual(z[3], 150)
        self.assertEqual(vswr[3], 3)
        self.assertAlmostEqual(db[3], -6.020599913)
        self.assertTrue(np.isnan(vswr[4]))
        self.assertTrue(np.isnan(phase[0]))

if __name__ == '__main__': unittest.main()
