"""Transaction and behaviour-preservation checks; never contact the live desktop."""
import importlib.util
from pathlib import Path
import re
import shutil
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("theme_switch", SOURCE / "switch.py")
switch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(switch)


class ThemeSwitchTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="theme-switch-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.base = self.root / "themes"
        shutil.copytree(SOURCE, self.base, symlinks=True,
                        ignore=shutil.ignore_patterns("__pycache__", "tests"))
        switch.select_link(self.base, "rose-pine")
        self.starship = self.root / "starship.toml"
        self.mako = self.root / "mako.conf"
        self.state = self.root / "state"
        self.starship.write_text("# keep this comment\nformat = '$directory$character'\n"
                                 "palette = 'rose_pine'\nadd_newline = false\n\n"
                                 "[palettes.rose_pine]\nred = '#eb6f92'\n"
                                 "[palettes.gruvbox_muted]\nred = '#cc241d'\n")
        self.mako.write_text(SOURCE.parent.joinpath("hypr/mako.conf").read_text())
        colours = switch.json.loads((self.base / "profiles/rose-pine/mako.json").read_text())
        self.mako.write_text(switch.mako_text(self.mako.read_text(), colours))
        self.original = (self.starship.read_bytes(), self.mako.read_bytes())

    def apply(self, choice):
        return switch.apply_profile(self.base, self.starship, self.mako, self.state, choice)

    def test_round_trip_preserves_every_non_colour_setting(self):
        original_layout = re.sub(r"(?m)^palette = .*", "palette = SELECTED", self.starship.read_text())
        original_mako_layout = re.sub(r"(?m)^((?:background|text|border|progress)-color)=.*", r"\1=COLOUR", self.mako.read_text())
        self.apply("gruvbox")
        self.assertEqual(switch.current(self.base), "gruvbox")
        self.assertEqual(original_layout, re.sub(r"(?m)^palette = .*", "palette = SELECTED", self.starship.read_text()))
        self.assertEqual(original_mako_layout, re.sub(r"(?m)^((?:background|text|border|progress)-color)=.*", r"\1=COLOUR", self.mako.read_text()))
        self.apply("rose-pine")
        self.assertEqual(self.original, (self.starship.read_bytes(), self.mako.read_bytes()))

    def test_missing_asset_is_rejected_before_any_write(self):
        (self.base / "profiles/gruvbox/kitty.conf").unlink()
        with self.assertRaises(ValueError):
            self.apply("gruvbox")
        self.assertEqual("rose-pine", switch.current(self.base))
        self.assertEqual(self.original, (self.starship.read_bytes(), self.mako.read_bytes()))
        self.assertFalse(self.state.exists())

    def test_edited_selector_is_not_silently_overwritten(self):
        self.starship.write_text(self.starship.read_text().replace("palette = 'rose_pine'", "# palette selected elsewhere"))
        before = self.starship.read_bytes()
        with self.assertRaises(ValueError):
            self.apply("gruvbox")
        self.assertEqual(before, self.starship.read_bytes())
        self.assertEqual("rose-pine", switch.current(self.base))

    def test_write_failure_rolls_back_entire_selection(self):
        original_atomic = switch.atomic_text
        count = 0

        def fail_once(path, text):
            nonlocal count
            count += 1
            if count == 2:
                raise OSError("simulated interrupted second write")
            original_atomic(path, text)

        with patch.object(switch, "atomic_text", fail_once):
            with self.assertRaises(OSError):
                self.apply("gruvbox")
        self.assertEqual(self.original, (self.starship.read_bytes(), self.mako.read_bytes()))
        self.assertEqual("rose-pine", switch.current(self.base))
        self.assertEqual([], list(self.base.glob(".select-*")))

    def test_repeat_selection_is_a_noop(self):
        self.apply("rose-pine")
        self.assertFalse(self.state.exists())

    def test_invalid_selection_cannot_escape_profiles(self):
        with self.assertRaises(ValueError):
            self.apply("../elsewhere")
        self.assertEqual("rose-pine", switch.current(self.base))

    def test_legacy_kitty_palette_can_return_to_hyprland(self):
        kitty = self.root / "kitty.conf"
        kitty.write_text("# BEGIN_KITTY_THEME\ninclude old-plasma-palette.conf\n# END_KITTY_THEME\n"
                         "font_size 18\nbackground_opacity 0.86\nmap ctrl+shift+t new_tab\n")
        switch.apply_profile(self.base, self.starship, self.mako, self.state, "gruvbox", kitty)
        self.assertIn("include ../desktop-themes/current/kitty.conf", kitty.read_text())
        self.assertTrue(kitty.read_text().endswith("font_size 18\nbackground_opacity 0.86\nmap ctrl+shift+t new_tab\n"))


if __name__ == "__main__":
    unittest.main()
