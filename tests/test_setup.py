"""Offline tests: python3 -m unittest discover -s tests -v"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DotfilesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="cachyos-dotfiles-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home"
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_DATA_HOME=str(self.home / ".local/share"),
                        XDG_CACHE_HOME=str(self.home / ".cache"))

    def setup(self, *args, ok=True):
        result = subprocess.run([str(ROOT / "setup.sh"), *args],
                                env=self.env, text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def test_dry_run_does_not_write(self):
        result = self.setup("--dry-run", "--install-packages", "--with-prefix-help", "--with-pokemon")
        self.assertIn("sudo pacman -Syu --needed", result.stdout)
        self.assertIn("pokemon-terminal-greeting", result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_pokemon_installer_disables_upstream_hooks(self):
        upstream = self.home / ".local/share/pokemon-terminal-greeting"
        upstream.mkdir(parents=True)
        (upstream / "install.sh").write_text(
            'printf "%s\\n" "$@" > "$HOME/install-args"\n')
        self.setup("--only", "git", "--with-pokemon")
        self.assertEqual((self.home / "install-args").read_text(), "--no-hook\n")
        self.assertFalse((self.home / ".zshrc").exists())

    def test_existing_pokemon_install_is_reused(self):
        binary = self.home / ".local/bin/pokemon-greeting"
        binary.parent.mkdir(parents=True)
        binary.write_text("#!/bin/sh\nexit 0\n")
        binary.chmod(0o755)
        result = self.setup("--only", "git", "--with-pokemon")
        self.assertIn("already installed", result.stdout)
        self.assertFalse((self.home / ".local/share/pokemon-terminal-greeting").exists())

    def test_failed_greeter_install_stops_before_linking(self):
        upstream = self.home / ".local/share/pokemon-terminal-greeting"
        upstream.mkdir(parents=True)
        (upstream / "install.sh").write_text("exit 42\n")
        self.setup("--only", "git", "--with-pokemon", ok=False)
        self.assertFalse((self.home / ".gitconfig").exists())

    def test_prefix_help_fetches_and_builds_pinned_submodule(self):
        binaries = self.home / "mock-bin"
        binaries.mkdir()
        for name in ("git", "cargo", "cc"):
            mock = binaries / name
            mock.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/' + name + '-args"\n')
            mock.chmod(0o755)
        self.env["PATH"] = str(binaries) + os.pathsep + self.env["PATH"]
        self.setup("--only", "git", "--with-prefix-help")
        self.assertEqual((self.home / "git-args").read_text().splitlines(),
                         ["-C", str(ROOT), "submodule", "update", "--init", "--recursive"])
        cargo_args = (self.home / "cargo-args").read_text().splitlines()
        self.assertEqual(cargo_args[:3], ["build", "--release", "--locked"])
        self.assertIn(str(ROOT / "tmux/.config/tmux/plugins/tmux-prefix-help/Cargo.toml"), cargo_args)

    @unittest.skipUnless(shutil.which("zsh"), "Zsh is unavailable")
    def test_zsh_runs_greeter(self):
        self.setup("--only", "zsh")
        binary = self.home / ".local/bin/pokemon-greeting"
        binary.parent.mkdir(parents=True)
        binary.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/greeting-args"\n')
        binary.chmod(0o755)
        result = subprocess.run(["zsh", "-df", "-ic", 'source "$HOME/.zshrc"; true'],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / "greeting-args").read_text(), "--speed\n0\n")

    def test_backup_repeat_install_and_fish_state(self):
        rc = self.home / ".bashrc"
        rc.write_text("original")
        old_backup = self.home / ".bashrc.bak"
        old_backup.write_text("older")
        fish = self.home / ".config/fish"
        fish.mkdir(parents=True)
        (fish / "fish_variables").write_text("machine state")
        self.setup()
        self.assertEqual((fish / "fish_variables").read_text(), "machine state")
        self.assertEqual(old_backup.read_text(), "older")
        backups = list(self.home.glob(".bashrc.bak.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "original")
        self.assertEqual(rc.resolve(), ROOT / "bash/.bashrc")
        self.assertFalse((self.home / ".gitconfig").exists())
        self.setup()
        self.assertEqual(list(self.home.glob(".bashrc.bak.*")), backups)
        rc.unlink()
        rc.write_text("second replacement")
        self.setup()
        self.assertEqual(len(list(self.home.glob(".bashrc.bak.*"))), 2)

    def test_broken_symlink_is_backed_up(self):
        rc = self.home / ".zshrc"
        rc.symlink_to("missing")
        self.setup("--only", "zsh")
        backups = list(self.home.glob(".zshrc.bak.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(os.readlink(backups[0]), "missing")
        self.assertEqual(rc.resolve(), ROOT / "zsh/.zshrc")
        self.assertFalse((self.home / ".bashrc").exists())
        self.assertTrue((self.home / ".bash_aliases").exists())

    def test_linked_parent_is_rejected_before_any_changes(self):
        elsewhere = Path(self.temp.name) / "elsewhere"
        elsewhere.mkdir()
        (self.home / ".config").symlink_to(elsewhere)
        self.setup(ok=False)
        self.assertFalse((self.home / ".bashrc").exists())
        self.assertEqual(list(elsewhere.iterdir()), [])

    def test_invalid_profile_is_rejected_before_changes(self):
        for value in ("bash,unknown", "bash,", ",fish", "fish,,zsh", ""):
            self.setup("--only", value, ok=False)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_git_is_explicit(self):
        self.setup("--only", "git")
        self.assertEqual((self.home / ".gitconfig").resolve(), ROOT / "git/.gitconfig")
        self.assertFalse((self.home / ".bashrc").exists())

    def test_shell_syntax(self):
        files = [ROOT / "setup.sh", ROOT / "bash/.bashrc", ROOT / "bash/.bash_profile",
                 ROOT / "common/.config/dotfiles/terminal.sh", ROOT / "scripts/.scripts/auto_venv.sh"]
        for file in files:
            subprocess.run(["bash", "-n", str(file)], check=True)
        if shutil.which("zsh"):
            for file in [ROOT / "zsh/.zshrc", *files[3:]]:
                subprocess.run(["zsh", "-n", str(file)], check=True)
        if shutil.which("fish"):
            for file in (ROOT / "fish").rglob("*.fish"):
                subprocess.run(["fish", "--no-config", "--no-execute", str(file)], check=True)

    def test_bash_zsh_venv_ownership_and_project_boundary(self):
        project = self.home / "project"
        activation = project / ".venv/bin/activate"
        activation.parent.mkdir(parents=True)
        activation.write_text('export VIRTUAL_ENV="$PWD/.venv"\ndeactivate() { unset VIRTUAL_ENV; }\n')
        (project / "child").mkdir()
        sibling = self.home / "project-other"
        sibling.mkdir()
        script = '''
source "$VENV_HELPER"
cd "$HOME/project"
_dotfiles_auto_venv
[[ $VIRTUAL_ENV == "$HOME/project/.venv" ]] || exit 10
cd child
_dotfiles_auto_venv
[[ -n $VIRTUAL_ENV ]] || exit 11
cd "$HOME/project-other"
_dotfiles_auto_venv
[[ -z ${VIRTUAL_ENV:-} ]] || exit 12
export VIRTUAL_ENV=/manual/environment
cd "$HOME/project"
_dotfiles_auto_venv
[[ $VIRTUAL_ENV == /manual/environment ]] || exit 13
'''
        env = dict(self.env, VENV_HELPER=str(ROOT / "scripts/.scripts/auto_venv.sh"))
        for shell in ("bash", "zsh"):
            if shutil.which(shell):
                subprocess.run([shell, "-f", "-c", script], env=env, check=True)

    @unittest.skipUnless(shutil.which("fish"), "Fish is unavailable")
    def test_fish_venv_ownership_and_project_boundary(self):
        project = self.home / "project"
        activation = project / ".venv/bin/activate.fish"
        activation.parent.mkdir(parents=True)
        activation.write_text('set -gx VIRTUAL_ENV "$PWD/.venv"\nfunction deactivate\nset -e VIRTUAL_ENV\nend\n')
        (project / "child").mkdir()
        (self.home / "project-other").mkdir()
        script = '''
source "$VENV_HELPER"
cd "$HOME/project"
test "$VIRTUAL_ENV" = "$HOME/project/.venv"; or exit 10
cd child
test -n "$VIRTUAL_ENV"; or exit 11
cd "$HOME/project-other"
test -z "$VIRTUAL_ENV"; or exit 12
set -gx VIRTUAL_ENV /manual/environment
cd "$HOME/project"
test "$VIRTUAL_ENV" = /manual/environment; or exit 13
'''
        env = dict(self.env, VENV_HELPER=str(ROOT / "fish/.config/fish/conf.d/auto_venv.fish"))
        subprocess.run(["fish", "--no-config", "--interactive", "-c", script], env=env, check=True,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)


if __name__ == "__main__":
    unittest.main()
