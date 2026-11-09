"""Lance les bancs de test VHDL avec VUnit et GHDL (backend GCC pour la couverture)."""
from pathlib import Path
from vunit import VUnit

ROOT = Path(__file__).parent
vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files(ROOT / "../../rtl/fifo_sync.vhd")
lib.add_source_files(ROOT / "*.vhd")

lib.set_compile_option("enable_coverage", True)
lib.set_sim_option("enable_coverage", True)


def post_run(results):
    results.merge_coverage(file_name="coverage_data")


vu.main(post_run=post_run)
