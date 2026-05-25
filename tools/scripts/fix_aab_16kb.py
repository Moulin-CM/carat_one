"""Post-process an AAB to set PAGE_ALIGNMENT_16K in BundleConfig.pb.

AGP 8.6 emits `optimizations.uncompress_native_libraries { enabled: true }`
without setting `alignment`, so bundletool defaults to PAGE_ALIGNMENT_4K when
Google Play generates per-device APKs. Google Play then rejects the bundle
with "Your app does not support 16 KB memory page sizes."

This script rewrites that sub-message to include `alignment: PAGE_ALIGNMENT_16K`,
then re-signs the AAB with jarsigner using android/key.properties.

Run after `flutter build appbundle`:
    python tools/scripts/fix_aab_16kb.py <path/to/app.aab>
"""

import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path


# Proto layout from bundletool's config.proto:
#   message Optimizations {
#     SplitsConfig splits_config = 1;
#     UncompressNativeLibraries uncompress_native_libraries = 2;
#     ... StoreArchive store_archive = 6;
#   }
#   message UncompressNativeLibraries {
#     bool enabled = 1;
#     PageAlignment alignment = 2;   // PAGE_ALIGNMENT_16K = 2
#   }
#
# Existing 12-byte payload AGP writes:
#   12 0a              field 2 (Optimizations), length 10
#     0a 00            splits_config = {}
#     12 02 08 01      uncompress_native_libraries { enabled: true }
#     32 02 08 01      store_archive { enabled: true }
#
# Patched 14-byte payload:
#   12 0c              field 2, length 12
#     0a 00            splits_config
#     12 04 08 01 10 02   uncompress_native_libraries { enabled: true, alignment: 2 }
#     32 02 08 01      store_archive
OLD_OPT = bytes.fromhex("120a 0a00 1202 0801 3202 0801".replace(" ", ""))
NEW_OPT = bytes.fromhex("120c 0a00 1204 0801 1002 3202 0801".replace(" ", ""))


def patch_bundle_config(data: bytes) -> bytes:
    if NEW_OPT in data:
        return data
    idx = data.find(OLD_OPT)
    if idx < 0:
        raise RuntimeError(
            "Could not find Optimizations field marker in BundleConfig.pb. "
            "The AGP-generated layout may have changed; inspect with "
            "`bundletool dump config --bundle=<aab>` and update OLD_OPT."
        )
    return data[:idx] + NEW_OPT + data[idx + len(OLD_OPT):]


def patch_aab(aab_path: Path, out_path: Path) -> None:
    with zipfile.ZipFile(aab_path, "r") as zin:
        names = zin.namelist()
        if "BundleConfig.pb" not in names:
            raise RuntimeError("AAB has no BundleConfig.pb")
        bc = zin.read("BundleConfig.pb")
        new_bc = patch_bundle_config(bc)
        if new_bc == bc:
            print("BundleConfig.pb unchanged (already patched?)")
        # Rebuild the AAB. Preserve compression method per entry.
        with zipfile.ZipFile(out_path, "w") as zout:
            for name in names:
                info = zin.getinfo(name)
                data = zin.read(name) if name != "BundleConfig.pb" else new_bc
                # Preserve compression / no-compression decision from original.
                new_info = zipfile.ZipInfo(filename=info.filename, date_time=info.date_time)
                new_info.compress_type = info.compress_type
                new_info.external_attr = info.external_attr
                zout.writestr(new_info, data)
    print(f"Patched AAB written to {out_path}")


def sign_aab(aab_path: Path, project_root: Path) -> None:
    key_props = project_root / "android" / "key.properties"
    if not key_props.exists():
        print("WARN: android/key.properties not found - skipping sign step")
        return
    props = {}
    for line in key_props.read_text().splitlines():
        if "=" in line and not line.strip().startswith("#"):
            k, v = line.split("=", 1)
            props[k.strip()] = v.strip()
    store_path = props.get("storeFile")
    if not store_path:
        print("WARN: storeFile not set in key.properties")
        return
    store_file = (project_root / "android" / store_path).resolve()
    if not store_file.exists():
        # try unmodified path
        store_file = Path(store_path)
        if not store_file.exists():
            print(f"WARN: keystore not found: {store_path}")
            return
    java_home = os.environ.get("JAVA_HOME", "")
    jarsigner = (
        Path(java_home) / "bin" / "jarsigner.exe"
    ) if java_home else Path("jarsigner")
    if not jarsigner.exists():
        # fall back
        jarsigner = Path("jarsigner")
    print(f"Signing {aab_path} with {store_file}")
    cmd = [
        str(jarsigner),
        "-keystore", str(store_file),
        "-storepass", props["storePassword"],
        "-keypass", props["keyPassword"],
        "-sigalg", "SHA256withRSA",
        "-digestalg", "SHA-256",
        str(aab_path),
        props["keyAlias"],
    ]
    subprocess.run(cmd, check=True)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        sys.exit(2)
    aab = Path(argv[1]).resolve()
    if not aab.exists():
        print(f"No such file: {aab}")
        sys.exit(1)
    backup = aab.with_suffix(aab.suffix + ".bak")
    if not backup.exists():
        shutil.copy2(aab, backup)
        print(f"Backup saved to {backup}")
    out = aab.with_suffix(aab.suffix + ".tmp")
    patch_aab(aab, out)
    shutil.move(str(out), str(aab))
    # Determine project root: arg-relative
    project_root = Path(__file__).resolve().parents[2]
    sign_aab(aab, project_root)
    print("Done.")


if __name__ == "__main__":
    main(sys.argv)
