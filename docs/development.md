# Offline development checks

Run `python3 -B -m unittest discover -s audit-planner/tests -v` and `python3 -B -m unittest discover -s tests -v` from the repository root. Fixtures only; never run legacy PowerShell. New workflow is scoped to these Python tests. No pip installation, credentials, live inventory, endpoint collection or removal is used. Windows/Proxmox and real-product acceptance remain unperformed. Python 3.11 is the proposed minimum; only the locally recorded interpreter has been executed so far.
