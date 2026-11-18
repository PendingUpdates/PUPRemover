"""Safe default: supplied synthetic inventory only; never dispatches legacy code."""
import importlib.util
from pathlib import Path
import sys


def main(argv=None):
    source = Path(__file__).resolve().parent / "audit-planner" / "audit_candidate.py"
    spec = importlib.util.spec_from_file_location("pallette_audit_planner", source)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.main(argv)


if __name__ == "__main__":
    sys.exit(main())
