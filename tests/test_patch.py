import os
from pathlib import Path
import subprocess
import unittest
PATCH = Path(__file__).resolve().parents[1] / 'module' / 'patch.awk'

def run(text):
    return subprocess.run([os.environ.get('AWK', 'awk'), '-f', str(PATCH)], input=text, text=True, capture_output=True)

class PatchTests(unittest.TestCase):
    def test_remove_selected_preserve_protection_and_comments(self):
        source = 'primary {\n  output {\n    prefx STAGE_EFFECT_VOICE_BOOSTER:lazy|STAGE_EFFECT_DOLBY  # keep comment\n    integ-pre STAGE_EFFECT_SOUNDBOOSTER|STAGE_EFFECT_SOUNDALIVE_PLUS\n    postfx STAGE_EFFECT_ADAPTSOUND_PROXY|STAGE_EFFECT_VOLUME_MONITOR_HW\n  }\n}\n'
        r = run(source)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout, source.replace('|STAGE_EFFECT_DOLBY', '').replace('|STAGE_EFFECT_SOUNDALIVE_PLUS', '').replace('STAGE_EFFECT_ADAPTSOUND_PROXY|', ''))
    def test_last_effect_becomes_none(self):
        r = run('primary {\n prefx STAGE_EFFECT_DOLBY_GAME:lazy\n}\n')
        self.assertEqual(r.returncode, 0)
        self.assertIn('prefx STAGE_EFFECT_NONE', r.stdout)
    def test_unknown_effect_retained(self):
        source = 'primary {\n prefx STAGE_EFFECT_DOLBY_FUTURE|STAGE_EFFECT_VENDOR_PROTECTION\n}\n'
        self.assertEqual(run(source).stdout, source)
    def test_not_substring_matching(self):
        source = 'primary {\n prefx STAGE_EFFECT_DOLBY_GAMEPAD|STAGE_EFFECT_NOT_DOLBY\n}\n'
        self.assertEqual(run(source).stdout, source)
    def test_non_assignment_and_comment_preserved(self):
        source = '# prefx STAGE_EFFECT_DOLBY\nprimary {\n globalfx STAGE_EFFECT_DOLBY\n note STAGE_EFFECT_DOLBY\n}\n'
        self.assertEqual(run(source).stdout, source)
    def test_malformed_rejected(self):
        for source in ['primary {\n', '}\n', 'primary { prefx STAGE_EFFECT_DOLBY }\n', 'primary {\n prefx STAGE_EFFECT_DOLBY extra\n}\n', 'primary {\n prefx STAGE_EFFECT_DOLBY:unknown\n}\n', 'prefx STAGE_EFFECT_DOLBY\n']:
            with self.subTest(source=source):
                self.assertNotEqual(run(source).returncode, 0)
    def test_idempotent(self):
        one = run('primary {\n prefx STAGE_EFFECT_DOLBY_PROXY|STAGE_EFFECT_SOUNDALIVE_PLUS_PROXY\n}\n')
        two = run(one.stdout)
        self.assertEqual(one.returncode, 0)
        self.assertEqual(two.returncode, 0)
        self.assertEqual(one.stdout, two.stdout)

if __name__ == '__main__':
    unittest.main()
