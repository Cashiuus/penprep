

import logging
import subprocess





def run_cmd(cmd, show_errors=False):
    """
    Simple wrapper to run a command and show output, while handling errors.
    """

    ec, output = subprocess.getstatusoutput(cmd)

    if ec:
        print(f"[!] Cmd exited with error: {output}")
    elif ec == 0:
        return output


