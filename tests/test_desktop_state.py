"""Appearance migrations preserve unrelated Noctalia settings and backups."""
from pathlib import Path
import runpy
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
API = runpy.run_path(str(ROOT / "scripts/configure_desktop.py"))
CONFIG = ROOT / "desktop/.config/noctalia/config.toml"


class DesktopStateTests(unittest.TestCase):
    def test_appearance_override_migration_preserves_other_state(self):
        text = '''config_version = 16
# Keep custom notification settings.
[notification]
width = 420
[theme]
source = "wallpaper"
mode = "light"
[bar.default]
thickness = 60
[lockscreen_widgets]
enabled = false
[wallpaper.default]
path = "/old.jpg"
[wallpaper.monitors."DP-1"]
path = "/other.jpg"
[wallpaper.automation]
enabled = true
'''
        preset = tomllib.loads(CONFIG.read_text())
        result = API["appearance_state"](text, preset, Path("/new.jpg"))
        data = tomllib.loads(result)
        self.assertEqual(data["notification"]["width"], 420)
        self.assertFalse(data["lockscreen_widgets"]["enabled"])
        self.assertEqual(data["theme"], {"mode": "light"})
        self.assertEqual(data["bar"]["default"], {})
        self.assertEqual(data["wallpaper"]["automation"], {})
        self.assertEqual(data["wallpaper"]["monitors"]["DP-1"]["path"], "/new.jpg")
        self.assertIn("# Keep custom notification settings.", result)
        self.assertEqual(API["appearance_state"](result, preset, Path("/new.jpg")), result)

    def test_empty_wallpaper_table_and_new_state(self):
        preset = tomllib.loads(CONFIG.read_text())
        for original in ("", "[wallpaper.default]\n"):
            result = API["appearance_state"](original, preset, Path("/new.jpg"))
            self.assertEqual(tomllib.loads(result)["wallpaper"]["default"]["path"], "/new.jpg")

    def test_quoted_managed_keys(self):
        preset = tomllib.loads(CONFIG.read_text())
        original = '[theme]\n"source" = "wallpaper"\n[wallpaper.default]\n\'path\' = "/old.jpg"\n'
        result = API["appearance_state"](original, preset, Path("/new.jpg"))
        self.assertEqual(tomllib.loads(result)["theme"], {})
        self.assertEqual(tomllib.loads(result)["wallpaper"]["default"]["path"], "/new.jpg")

    def test_dry_run_backup_and_repeat_install(self):
        with tempfile.TemporaryDirectory() as temporary:
            state = Path(temporary) / "noctalia/settings.toml"
            API["configure"](CONFIG, state, Path("/new.jpg"), True)
            self.assertFalse(state.parent.exists())
            state.parent.mkdir()
            state.write_text('[theme]\nsource = "wallpaper"\n')
            original = state.read_text()
            API["configure"](CONFIG, state, Path("/new.jpg"))
            backups = list(state.parent.glob("settings.toml.bak.*/original"))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), original)
            API["configure"](CONFIG, state, Path("/new.jpg"))
            self.assertEqual(list(state.parent.glob("settings.toml.bak.*/original")), backups)
