#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import shutil
import sys
import tempfile
import zipfile

def MakeTimestampsFileName(root, sha1):
    return os.path.join(root, os.pardir, '%s.timestamps' % sha1)

def GetFileList(root):
    """Gets a normalized list of files under |root|."""
    assert not os.path.isabs(root)
    assert os.path.normpath(root) == root
    file_list = []
    # Ignore WER ReportQueue entries that vctip/cl leave in the bin dir if/when
    # they crash. Also ignores the content of the
    # Windows Kits/10/debuggers/x(86|64)/(sym|src)/ directories as this is just
    # the temporarily location that Windbg might use to store the symbol files
    # and downloaded sources.
    #
    # Note: These files are only created on a Windows host, so the
    # ignored_directories list isn't relevant on non-Windows hosts.
    # The Windows SDK is either in `win_sdk` or in `Windows Kits\10`. This
    # script must work with both layouts, so check which one it is.
    # This can be different in each |root|.
    if os.path.isdir(os.path.join(root, 'Windows Kits', '10')):
        win_sdk = 'Windows Kits\\10'
    else:
        win_sdk = 'win_sdk'
    ignored_directories = [
        'wer\\reportqueue', win_sdk + '\\debuggers\\x86\\sym\\',
        win_sdk + '\\debuggers\\x64\\sym\\',
        win_sdk + '\\debuggers\\x86\\src\\', win_sdk + '\\debuggers\\x64\\src\\'
    ]
    ignored_directories = [d.lower() for d in ignored_directories]
    for base, _, files in os.walk(root):
        paths = [os.path.join(base, f) for f in files]
        for p in paths:
            if any(ignored_dir in p.lower()
                   for ignored_dir in ignored_directories):
                continue
            file_list.append(p)
    return sorted(file_list, key=lambda s: s.replace('/', '\\').lower())

def CalculateHash(root, expected_hash):
    """Calculates the sha1 of the paths to all files in the given |root| and the
    contents of those files, and returns as a hex string.
    |expected_hash| is the expected hash value for this toolchain if it has
    already been installed.
    """
    if expected_hash:
        full_root_path = os.path.join(root, expected_hash)
    else:
        full_root_path = root
    file_list = GetFileList(full_root_path)
    # Check whether we previously saved timestamps in
    # $root/../{sha1}.timestamps. If we didn't, or they don't match, then do the
    # full calculation, otherwise return the saved value.
    timestamps_file = MakeTimestampsFileName(root, expected_hash)
    timestamps_data = {'files': [], 'sha1': ''}
    if os.path.exists(timestamps_file):
        with open(timestamps_file, 'rb') as f:
            try:
                timestamps_data = json.load(f)
            except ValueError:
                # json couldn't be loaded, empty data will force a re-hash.
                pass
    matches = len(file_list) == len(timestamps_data['files'])
    # Don't check the timestamp of the version file as we touch this file to
    # indicates which versions of the toolchain are still being used.
    vc_dir = os.path.join(full_root_path, 'VC').lower()
    if matches:
        for disk, cached in zip(file_list, timestamps_data['files']):
            if disk != cached[0] or (disk != vc_dir
                                     and os.path.getmtime(disk) != cached[1]):
                matches = False
                break
    elif os.path.exists(timestamps_file):
        # Print some information about the extra/missing files. Don't do this if
        # we don't have a timestamp file, as all the files will be considered as
        # missing.
        timestamps_data_files = []
        for f in timestamps_data['files']:
            timestamps_data_files.append(f[0])
        missing_files = [f for f in timestamps_data_files if f not in file_list]
        if len(missing_files):
            print('%d files missing from the %s version of the toolchain:' %
                  (len(missing_files), expected_hash))
            for f in missing_files[:10]:
                print('\t%s' % f)
            if len(missing_files) > 10:
                print('\t...')
        extra_files = [f for f in file_list if f not in timestamps_data_files]
        if len(extra_files):
            print('%d extra files in the %s version of the toolchain:' %
                  (len(extra_files), expected_hash))
            for f in extra_files[:10]:
                print('\t%s' % f)
            if len(extra_files) > 10:
                print('\t...')
    if matches:
        return timestamps_data['sha1']
    # Make long hangs when updating the toolchain less mysterious.
    print('Calculating hash of toolchain in %s. Please wait...' %
          full_root_path)
    sys.stdout.flush()
    digest = hashlib.sha1()
    for path in file_list:
        path_without_hash = str(path).replace('/', '\\')
        if expected_hash:
            path_without_hash = path_without_hash.replace(
                os.path.join(root, expected_hash).replace('/', '\\'), root)
        digest.update(bytes(path_without_hash.lower(), 'utf-8'))
        with open(path, 'rb') as f:
            digest.update(f.read())
    # Save the timestamp file if the calculated hash is the expected one.
    # The expected hash may be shorter, to reduce path lengths, in which case
    # just compare that many characters.
    if expected_hash and digest.hexdigest().startswith(expected_hash):
        SaveTimestampsAndHash(root, digest.hexdigest())
        # Return the (potentially truncated) expected_hash.
        return expected_hash
    return digest.hexdigest()

def CalculateHashFromZip(zip_path):
    """Calculate hash directly from zip contents without extracting."""
    digest = hashlib.sha1()
    with zipfile.ZipFile(zip_path, 'r') as zf:
        all_files = []
        rel_root = "vs_files"
        has_windows_kits = any(
            n.startswith(rel_root + "/Windows Kits/10/")
            for n in zf.namelist()
        )
        if has_windows_kits:
            win_sdk = "Windows Kits\\10"
        else:
            win_sdk = "win_sdk"
        ignored_directories = [
            "wer\\reportqueue",
            win_sdk + "\\debuggers\\x86\\sym\\",
            win_sdk + "\\debuggers\\x64\\sym\\",
            win_sdk + "\\debuggers\\x86\\src\\",
            win_sdk + "\\debuggers\\x64\\src\\",
        ]
        ignored_directories = [d.lower() for d in ignored_directories]
        for name in zf.namelist():
            if name.endswith("/"):
                continue
            full_path = os.path.join(rel_root, name).replace("/", "\\")
            lower_path = full_path.lower()
            if any(ignored in lower_path for ignored in ignored_directories):
                continue
            all_files.append((full_path, name))
        all_files.sort(key=lambda s: s[0].replace("/", "\\").lower())
        for full_path, zip_name in all_files:
            digest.update(full_path.lower().encode("utf-8"))
            digest.update(zf.read(zip_name))
    return digest.hexdigest()

def RenameToSha1(output, no_extract=False, dry_run=False, print_only=False):
    """Determine the hash in the same way that the unzipper does to rename the .zip file."""
    if print_only:
        if no_extract:
            sha1 = CalculateHashFromZip(output)[:10]
        else:
            tempdir = tempfile.mkdtemp()
            old_dir = os.getcwd()
            try:
                os.chdir(tempdir)
                rel_dir = 'vs_files'
                with zipfile.ZipFile(os.path.join(old_dir, output), 'r') as zf:
                    zf.extractall(rel_dir)
                sha1 = CalculateHash(rel_dir, None)[:10]
            finally:
                os.chdir(old_dir)
                shutil.rmtree(tempdir, ignore_errors=True)
        print(sha1 + '.zip')
        return
    if no_extract:
        sha1 = CalculateHashFromZip(output)[:10]
    else:
        print('Extracting to determine hash...')
        tempdir = tempfile.mkdtemp()
        old_dir = os.getcwd()
        try:
            os.chdir(tempdir)
            rel_dir = 'vs_files'
            with zipfile.ZipFile(os.path.join(old_dir, output), 'r') as zf:
                zf.extractall(rel_dir)
            print('Hashing...')
            sha1 = CalculateHash(rel_dir, None)
            sha1 = sha1[:10]
        finally:
            os.chdir(old_dir)
            shutil.rmtree(tempdir, ignore_errors=True)
    final_name = sha1 + '.zip'
    if dry_run:
        print(f"[Dry run] Would rename {output} -> {final_name}")
        return
    try:
        os.rename(output, final_name)
    except OSError as e:
        print(f"Error renaming file: {e}")
        sys.exit(1)
    print('Renamed %s to %s' % (output, final_name))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Rename a toolchain zip file to its SHA1-based name."
    )
    parser.add_argument("zip_file", help="Input .zip file")
    parser.add_argument("--dry-run", action="store_true",
                        help="Compute hash but do not rename the file")
    parser.add_argument("--print-only", action="store_true",
                        help="Print only the final filename (no extra output)")
    parser.add_argument("--no-extract", action="store_true",
                    help="Calculate hash directly from zip without extracting")
    args = parser.parse_args()
    toolchainfile = args.zip_file
    if not os.path.exists(toolchainfile):
        print(f"Error: file not found: {toolchainfile}")
        sys.exit(1)
    if not toolchainfile.lower().endswith('.zip'):
        print("Error: input file must be a .zip file")
        sys.exit(1)
    RenameToSha1(toolchainfile,
        no_extract=args.no_extract,
        dry_run=args.dry_run,
        print_only=args.print_only)
