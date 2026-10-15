#!/usr/bin/env python3
"""
builder.py — builds a boot/recovery image for Tecno Spark Go 2023 (BF7)
that fits the device's 32MB partition budget, automatically shrinking it
through the same layered strategy as CyberRecoveryProject's image_shrink.c
(non-destructive steps first, user prompt only if those aren't enough).

This is a standalone Python tool — you run it directly against a real
boot.img, no C toolchain/build step needed, which makes it faster to
iterate on than the full device tree build while you're still shrinking
things down. Once you've got a build that fits, the same reasoning is
what's baked into CyberRecoveryProject's on-device C code.

Requires on PATH: magiskboot, gzip, strip (binutils), dtc (optional, only
for DTB inspection). Run this under WSL / a Linux shell on Windows, same
place your existing magiskboot/CI workflow already runs.

Usage:
    python3 builder.py patched-boot.img --out boot-32mb.img
    python3 builder.py patched-boot.img --out boot-32mb.img --target-mb 32
    python3 builder.py patched-boot.img --out boot-32mb.img --dry-run
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile

# ---- BF7-specific constants (from your confirmed device investigation) ---
TARGET_PARTITION_BYTES_DEFAULT = 33_554_432  # 32MB boot/recovery budget
MTK_DTB_HEADER_SIZE = 64                      # proprietary MTK DTB wrapper
RAMDISK_COMPRESSION = "gzip"                  # kernel only has CONFIG_RD_GZIP
STOCK_REFERENCE = {                           # sanity baseline, not inputs
    "kernel": 11_883_603,
    "ramdisk": 13_413_567,
    "dtb": 121_231,
}

KNOWN_DEBUG_PATTERNS = [
    "libclang_rt.ubsan_standalone-aarch64-android.so",
    "libasan.so",
    "strace",
    "gdbserver",
]
KNOWN_UNUSED_EXTRAS = ["bin/bash", "bin/nano", "lib64/libssh.so"]


def human(n: int) -> str:
    n = float(n)
    for unit in ["B", "KB", "MB", "GB"]:
        if abs(n) < 1024:
            return f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}TB"


def run(cmd, **kw):
    return subprocess.run(cmd, shell=True, **kw)


def require_tool(name):
    if not shutil.which(name):
        print(f"ERROR: `{name}` not found on PATH. This script needs to run "
              f"where your magiskboot/binutils toolchain already lives "
              f"(WSL, same shell as your existing CI steps).", file=sys.stderr)
        sys.exit(1)


def dir_size(path: str) -> int:
    total = 0
    for root, _, files in os.walk(path):
        for f in files:
            fp = os.path.join(root, f)
            if not os.path.islink(fp):
                try:
                    total += os.path.getsize(fp)
                except OSError:
                    pass
    return total


def unpack(image_path: str, workdir: str):
    """Unpack via magiskboot, then slice MTK's header off dtb.img if present."""
    require_tool("magiskboot")
    log_path = os.path.join(workdir, "unpack.log")
    with open(log_path, "w") as log:
        r = run(f"cd '{workdir}' && magiskboot unpack '{os.path.abspath(image_path)}'",
                stdout=log, stderr=subprocess.STDOUT)
    if r.returncode != 0:
        print(f"magiskboot unpack failed — see {log_path}", file=sys.stderr)
        sys.exit(1)

    dtb_path = os.path.join(workdir, "dtb.img")
    if os.path.exists(dtb_path):
        size = os.path.getsize(dtb_path)
        if size > MTK_DTB_HEADER_SIZE:
            with open(dtb_path, "rb") as f:
                f.seek(MTK_DTB_HEADER_SIZE)
                real = f.read()
            with open(dtb_path, "wb") as f:
                f.write(real)
            print(f"  Sliced {MTK_DTB_HEADER_SIZE}-byte MTK header off dtb.img "
                  f"({human(size)} -> {human(len(real))})")


def extract_ramdisk(workdir: str):
    """Expand ramdisk.cpio into a browsable ramdisk/ folder for strategies
    that need to inspect/remove individual files."""
    cpio = os.path.join(workdir, "ramdisk.cpio")
    extracted = os.path.join(workdir, "ramdisk")
    if not os.path.exists(cpio):
        return None
    os.makedirs(extracted, exist_ok=True)
    run(f"cd '{extracted}' && cpio -idm < '{cpio}'",
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return extracted


def find_matches(root: str, needles):
    matches = []
    for dirpath, _, files in os.walk(root):
        for f in files:
            full = os.path.join(dirpath, f)
            rel = os.path.relpath(full, root)
            for needle in needles:
                if needle in rel:
                    try:
                        size = os.path.getsize(full)
                    except OSError:
                        size = 0
                    matches.append((full, rel, size))
    return matches


def strategy_strip_debug_runtimes(ramdisk_dir: str, apply: bool) -> int:
    matches = find_matches(ramdisk_dir, KNOWN_DEBUG_PATTERNS)
    freed = sum(m[2] for m in matches)
    print(f"[1] Strip debug/sanitizer runtimes — {len(matches)} file(s), {human(freed)}")
    for full, rel, size in matches:
        print(f"      {rel} ({human(size)})")
        if apply:
            os.remove(full)
    return freed if apply else freed


def strategy_strip_known_unused(ramdisk_dir: str, apply: bool) -> int:
    matches = find_matches(ramdisk_dir, KNOWN_UNUSED_EXTRAS)
    freed = sum(m[2] for m in matches)
    print(f"[2] Strip known-unused extras (bash/nano/libssh) — {len(matches)} file(s), {human(freed)}")
    for full, rel, size in matches:
        print(f"      {rel} ({human(size)})")
        if apply:
            os.remove(full)
    return freed


def strategy_strip_symbols(ramdisk_dir: str, apply: bool) -> int:
    if not shutil.which("strip"):
        print("[3] Strip ELF symbols — SKIPPED (no `strip` on PATH)")
        return 0
    before = dir_size(ramdisk_dir)
    if apply:
        for dirpath, _, files in os.walk(ramdisk_dir):
            for f in files:
                full = os.path.join(dirpath, f)
                if full.endswith(".so") or f"{os.sep}bin{os.sep}" in full:
                    run(f"strip --strip-unneeded '{full}'",
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        after = dir_size(ramdisk_dir)
        freed = max(before - after, 0)
        print(f"[3] Strip ELF symbols — freed {human(freed)}")
        return freed
    else:
        print("[3] Strip ELF symbols — (dry-run: impact only known with --apply)")
        return 0


def regenerate_ramdisk(workdir: str, ramdisk_dir: str):
    """Rebuild ramdisk.cpio.gz from the (possibly shrunk) ramdisk/ folder.
    ALWAYS regenerates from source — never trusts a cached .comp file.
    This is the direct fix for the 'edits don't survive repack' bug you
    hit before."""
    cpio = os.path.join(workdir, "ramdisk.cpio")
    comp = os.path.join(workdir, "ramdisk.cpio.gz")
    r = run(f"cd '{ramdisk_dir}' && find . | cpio -o -H newc > '{cpio}' 2>/dev/null")
    if r.returncode != 0:
        print("ERROR: failed to regenerate ramdisk.cpio from folder", file=sys.stderr)
        sys.exit(1)
    run(f"gzip -9 -f -c '{cpio}' > '{comp}'")
    print(f"  Regenerated ramdisk.cpio.gz from ramdisk/ folder "
          f"({human(os.path.getsize(comp))})")


def current_size(workdir: str) -> int:
    return dir_size(workdir)


TRADEOFFS = {
    "extra_languages": {
        "description": "Remove extra language packs (keep English + device default)",
        "pattern": ["res/values-"],
        "keep_pattern": "values-en",
    },
    "theme_hires_assets": {
        "description": "Remove high-resolution theme assets",
        "pattern": ["theme/"],
        "keep_pattern": None,
    },
}


def prompt_tradeoffs(ramdisk_dir: str, bytes_needed: int) -> int:
    print(f"\nAutomatic shrinking wasn't enough — still need to free "
          f"~{human(bytes_needed)}.")
    print("Available trade-offs:")
    keys = list(TRADEOFFS.keys())
    for i, k in enumerate(keys):
        print(f"  [{i}] {TRADEOFFS[k]['description']}")
    print(f"  [c] Cancel")

    choice = input("Apply which? (comma-separated indices, or c to cancel): ").strip()
    if choice.lower() == "c" or choice == "":
        return 0

    freed_total = 0
    for idx_str in choice.split(","):
        idx_str = idx_str.strip()
        if not idx_str.isdigit():
            continue
        idx = int(idx_str)
        if idx < 0 or idx >= len(keys):
            continue
        key = keys[idx]
        spec = TRADEOFFS[key]
        matches = find_matches(ramdisk_dir, spec["pattern"])
        for full, rel, size in matches:
            if spec["keep_pattern"] and spec["keep_pattern"] in rel:
                continue
            os.remove(full)
            freed_total += size
    return freed_total


def build(image_path: str, out_path: str, target_mb: float, dry_run: bool, interactive: bool):
    require_tool("magiskboot")
    target_bytes = int(target_mb * 1024 * 1024)

    with tempfile.TemporaryDirectory(prefix="bf7_build_") as workdir:
        print(f"Unpacking {image_path} ...")
        unpack(image_path, workdir)

        ramdisk_dir = extract_ramdisk(workdir)
        if not ramdisk_dir:
            print("WARNING: no ramdisk.cpio found after unpack — nothing to shrink, "
                  "will just repack as-is.")

        size = current_size(workdir)
        print(f"\nUnpacked size: {human(size)} (target: {human(target_bytes)})")

        for name, ref in STOCK_REFERENCE.items():
            print(f"  (stock {name} reference: {human(ref)})")

        if size <= target_bytes:
            print("Already within budget — no shrinking needed.")
        elif ramdisk_dir:
            apply = not dry_run
            freed = 0
            freed += strategy_strip_debug_runtimes(ramdisk_dir, apply)
            freed += strategy_strip_known_unused(ramdisk_dir, apply)
            freed += strategy_strip_symbols(ramdisk_dir, apply)

            remaining = size - target_bytes - freed
            if remaining > 0 and apply and interactive:
                freed += prompt_tradeoffs(ramdisk_dir, remaining)
            elif remaining > 0:
                print(f"\nStill ~{human(remaining)} over budget after automatic "
                      f"strategies. Re-run with --apply (and without --no-interactive) "
                      f"to be prompted for trade-offs, or trim manually.")

        if dry_run:
            print("\nDry run complete — nothing was written. "
                  "Re-run without --dry-run to actually build.")
            return

        if ramdisk_dir:
            print("\nRegenerating ramdisk from (possibly shrunk) folder ...")
            regenerate_ramdisk(workdir, ramdisk_dir)

        print("Repacking ...")
        r = run(f"cd '{workdir}' && magiskboot repack original '{os.path.abspath(out_path)}'")
        if r.returncode != 0:
            print("ERROR: magiskboot repack failed", file=sys.stderr)
            sys.exit(1)

        final_size = os.path.getsize(out_path)
        print(f"\nBuilt: {out_path} ({human(final_size)})")
        if final_size > target_bytes:
            print(f"⚠️  STILL {human(final_size - target_bytes)} over the {target_mb}MB "
                  f"budget — avbtool's add_hash_footer check will fail on this. "
                  f"Try again with trade-offs applied, or pick a larger target.")
        else:
            print(f"✅ Fits within {target_mb}MB with {human(target_bytes - final_size)} to spare.")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image", help="Path to the source boot.img (already patched, pre-shrink)")
    ap.add_argument("--out", required=True, help="Path to write the final boot.img")
    ap.add_argument("--target-mb", type=float, default=32,
                     help="Target partition size in MB (default: 32, this device's budget)")
    ap.add_argument("--dry-run", action="store_true",
                     help="Report what would happen; write nothing")
    ap.add_argument("--no-interactive", dest="interactive", action="store_false",
                     help="Never prompt for trade-offs (fail instead if automatic steps aren't enough) — use this in CI")
    args = ap.parse_args()

    if not os.path.isfile(args.image):
        print(f"Not a file: {args.image}", file=sys.stderr)
        sys.exit(1)

    build(args.image, args.out, args.target_mb, args.dry_run, args.interactive)


if __name__ == "__main__":
    main()
