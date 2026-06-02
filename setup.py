from __future__ import annotations

import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

from setuptools import Distribution, setup
from setuptools.command.build_py import build_py
from setuptools.errors import ExecError


ROOT = Path(__file__).resolve().parent
PACKAGE_NAME = "mzproto"


class BinaryDistribution(Distribution):
    def has_ext_modules(self) -> bool:
        return True


class BuildPy(build_py):
    def run(self) -> None:
        generated_root = ROOT / "zig-out" / "lib"
        generated_package = generated_root / PACKAGE_NAME

        # Avoid packaging stale extensions left behind by previous local builds
        # for a different Python version or platform.
        if generated_package.exists():
            shutil.rmtree(generated_package)

        self._run_zig_build()

        if not generated_package.is_dir():
            raise ExecError(f"Zig build did not create {generated_package}")

        target_package = Path(self.build_lib) / PACKAGE_NAME
        if target_package.exists():
            shutil.rmtree(target_package)

        shutil.copytree(
            generated_package,
            target_package,
            ignore=shutil.ignore_patterns("__pycache__", "*.pyc", "*.pyo"),
        )

        native_extensions = [
            path
            for path in target_package.iterdir()
            if path.name.startswith("_native") and path.suffix in {".so", ".pyd"}
        ]
        if not native_extensions:
            raise ExecError(f"Zig build did not create a native extension in {target_package}")

        self.byte_compile([str(path) for path in target_package.rglob("*.py")])

    def get_outputs(self, include_bytecode: bool = True) -> list[str]:
        package_dir = Path(self.build_lib) / PACKAGE_NAME
        if not package_dir.exists():
            return []

        outputs = []
        for path in package_dir.rglob("*"):
            if not path.is_file():
                continue
            if not include_bytecode and path.suffix in {".pyc", ".pyo"}:
                continue
            outputs.append(str(path))
        return outputs

    def get_source_files(self) -> list[str]:
        files = [
            path
            for path in (ROOT / "build.zig", ROOT / "build.zig.zon", ROOT / "LICENSE")
            if path.exists()
        ]
        src = ROOT / "src"
        if src.exists():
            files.extend(path for path in src.rglob("*") if path.is_file())
        return [str(path) for path in files]

    def _run_zig_build(self) -> None:
        zig = os.environ.get("ZIG") or shutil.which("zig")
        if zig is None:
            raise ExecError(
                "Building mzproto from source requires Zig. "
                "Install Zig or use a prebuilt wheel."
            )

        cmd = [
            zig,
            "build",
            "-Dtarget-language=python",
            f"-Dpython-exe={sys.executable}",
        ]

        optimize = os.environ.get("MZPROTO_ZIG_OPTIMIZE", "ReleaseSafe")
        if optimize:
            cmd.append(f"-Doptimize={optimize}")

        extra_args = os.environ.get("MZPROTO_ZIG_BUILD_ARGS")
        if extra_args:
            cmd.extend(shlex.split(extra_args))

        try:
            subprocess.check_call(cmd, cwd=ROOT)
        except subprocess.CalledProcessError as err:
            raise ExecError(f"Zig build failed with exit code {err.returncode}") from err


setup(
    packages=[PACKAGE_NAME],
    distclass=BinaryDistribution,
    cmdclass={"build_py": BuildPy},
    zip_safe=False,
)
