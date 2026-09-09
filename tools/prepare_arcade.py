"""Prepare offline Spicy Adventure artifacts with a coordinator-owned Godot.

Python's standard library only. This does not download/install an engine,
templates or dependencies, modify live caches, or run a shell command string.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = re.compile(r"^4\.5\.2\.stable(?:\.|$)")
TEST_MARKER = "SPICY_ARCADE_TESTS_PASSED"


def run(args: list[str], *, env: dict[str, str], timeout: int = 600, cwd: Path = ROOT) -> str:
    print("+", subprocess.list2cmdline(args), flush=True)
    result = subprocess.run(
        args, cwd=cwd, env=env, capture_output=True, text=True,
        encoding="utf-8", errors="replace", timeout=timeout, check=False,
    )
    output = result.stdout + result.stderr
    # Keep diagnostics and test evidence visible without hundreds of individual
    # export/import progress lines. The full text still participates in checks.
    plain_output = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", output)
    lines = [line for line in plain_output.splitlines()
             if not re.match(r"^\[\s*\d+%\s*\]\s+\w+\s+\|", line)]
    print("\n".join(lines), flush=True)
    # Godot can report script failures while returning zero. Fail closed.
    if result.returncode or "ERROR:" in output or "Parse Error:" in output or "instances leaked" in output:
        raise RuntimeError(f"Godot step failed (exit {result.returncode})")
    return output


def fingerprint(path: Path) -> dict[str, str | int]:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return {"file": path.name, "bytes": path.stat().st_size, "sha256": digest.hexdigest()}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, type=Path, help="4.5.2-stable console/editor binary")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "release" / "spicy-arcade")
    parser.add_argument("--native", action="append", choices=("linux", "windows"), default=[],
                        help="Optional executable export; matching templates must already exist")
    parser.add_argument("--tests-only", action="store_true", help="Import and run tests, without exporting")
    args = parser.parse_args()
    godot = args.godot.expanduser().resolve(strict=True)
    if not godot.is_file():
        parser.error("--godot must name an executable file")
    env = dict(os.environ)
    version_output = run([str(godot), "--version"], env=env, timeout=30).strip()
    if not VERSION.match(version_output):
        raise RuntimeError(f"Refusing to import with {version_output!r}; use 4.5.2-stable")
    output = args.output_dir.expanduser().resolve()
    if output.is_relative_to(ROOT) and not output.is_relative_to(ROOT / "release"):
        parser.error("In-repository artifacts must be under release/, not source/asset directories")
    output.mkdir(parents=True, exist_ok=True)
    (output / ".gdignore").touch(exist_ok=True)
    headless = [str(godot), "--headless", "--path", str(ROOT)]
    # --import waits for the import queue; --quit here could cut imports short.
    run(headless + ["--editor", "--import"], env=env)
    with tempfile.TemporaryDirectory(prefix="spicy-arcade-fixtures-") as fixtures:
        test_env = dict(env, ARCADE_MODE="1", ARCADE_GAME_DATA_DIR=fixtures)
        tests = run(
            headless + ["--max-fps", "120", "res://tests/arcade_test.tscn", "--", "--arcade"],
            env=test_env, timeout=180,
        )
        if TEST_MARKER not in tests:
            raise RuntimeError("Test runner exited without its successful root-exit marker")
        if args.tests_only:
            return 0
        pack = output / "spicy-arcade.pck"
        run(headless + ["--export-pack", "Linux Arcade", str(pack)], env=env)
        if not pack.is_file() or pack.stat().st_size < 1024:
            raise RuntimeError("Godot did not produce a usable native PCK")
        # Run the SAME full lifecycle suite on the actual PCK from an artifact-only
        # working directory. Only the external fixture is loose; game res:// paths
        # and autoloads must resolve inside the prepared pack.
        fixture_args = [
            "--max-fps", "120", "--script", str(ROOT / "tools" / "run_fixture.gd"),
            "--", "--arcade",
            f"--spicy-arcade-fixture={ROOT / 'tests' / 'arcade_test.gd'}",
        ]
        packed_tests = run(
            [str(godot), "--headless", "--main-pack", str(pack),
             "--rendering-method", "gl_compatibility"] + fixture_args,
            env=test_env, timeout=180, cwd=output,
        )
        if TEST_MARKER not in packed_tests:
            raise RuntimeError("Prepared pack did not complete its controller lifecycle tests")
        artifacts = [fingerprint(pack)]
        for platform in dict.fromkeys(args.native):
            directory = output / f"spicy-arcade-{platform}"
            directory.mkdir(exist_ok=True)
            executable = directory / ("spicy-arcade.exe" if platform == "windows" else "spicy-arcade.x86_64")
            preset = "Windows Desktop" if platform == "windows" else "Linux Arcade"
            run(headless + ["--export-release", preset, str(executable)], env=env)
            native_files = [executable, executable.with_suffix(".pck")]
            if not all(path.is_file() for path in native_files):
                raise RuntimeError(f"Incomplete {platform} executable export")
            for path in native_files:
                record = fingerprint(path)
                record["file"] = str(path.relative_to(output))
                artifacts.append(record)
            if (platform == "windows") == (os.name == "nt"):
                native_tests = run(
                    [str(executable), "--headless", "--rendering-method", "gl_compatibility"] + fixture_args,
                    env=test_env, timeout=180, cwd=directory,
                )
                if TEST_MARKER not in native_tests:
                    raise RuntimeError(f"Native {platform} executable did not complete its lifecycle tests")
    manifest = {
        "engine": version_output,
        "renderer": "gl_compatibility",
        "main_scene": "uid://ds4vob4h38lsv",
        "pack_preset": "Linux Arcade",
        "tests": TEST_MARKER,
        "artifacts": artifacts,
        "physical_cabinet_validated": False,
    }
    manifest_path = output / "spicy-arcade-build.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Prepared artifacts: {output}\nManifest: {manifest_path}")
    print("Linux display/USB controls/frame pacing/gallery return still require coordinator checks.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"Preparation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
