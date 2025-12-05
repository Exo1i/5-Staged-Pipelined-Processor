import os
import argparse
import glob
import sys

from assembler.simulator import solve_asm
from assembler.assembler import Assembler


def run_tests():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--src', default='tests/assembly',
                        help='Directory with .asm files')
    parser.add_argument('--dest', default='tests/machine_code',
                        help='Directory for output .mem files')
    parser.add_argument('files', nargs='*',
                        help='Specific files to test (optional)')
    args = parser.parse_args()

    # Determine paths relative to where script is run
    # Use os.getcwd() or relative paths if running from root
    src_dir = os.path.abspath(args.src)
    dest_dir = os.path.abspath(args.dest)
    os.makedirs(dest_dir, exist_ok=True)

    # Gather files
    files = []
    if args.files:
        files = [f if os.path.exists(f) else os.path.join(
            src_dir, f) for f in args.files]
    else:
        files = glob.glob(os.path.join(src_dir, "*.asm"))

    if not files:
        print(f"No test files found in {src_dir}")
        return

    print(f"Running {len(files)} tests...")
    print(f"Source: {src_dir}")
    print(f"Output: {dest_dir}\n")

    errors = 0
    for src_path in files:
        if not os.path.exists(src_path):
            print(f"Skipping missing file: {src_path}")
            continue

        base_name = os.path.splitext(os.path.basename(src_path))[0]

        # 1. Assemble
        prog_out = os.path.join(dest_dir, f"{base_name}.mem")
        print(f"[TEST] {base_name:20} ... ", end='', flush=True)

        asm = Assembler(verbose=False)
        if not asm.assemble(src_path):
            print("ASSEMBLY FAILED")
            for e in asm.errors:
                print(f"  {e}")
            errors += 1
            continue

        asm.generate_output(prog_out)

        # 2. Simulate for Expected State
        expected_out = os.path.join(dest_dir, f"{base_name}_expected.mem")
        try:
            if solve_asm(src_path, expected_out):
                print("OK")
            else:
                print("SIMULATION FAILED")
                errors += 1
        except Exception as e:
            print(f"CRASH: {e}")
            errors += 1

    print("\n" + "="*40)
    if errors == 0:
        print("All tests passed successfully.")
    else:
        print(f"Finished with {errors} errors.")
        sys.exit(1)


if __name__ == "__main__":
    run_tests()
