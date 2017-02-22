#!/usr/bin/env python
#
# Purpose: Clone Git Repo for powercat and copy file to windows-binaries directory
#
#

import os
import shutil
import subprocess



install_base = os.path.expanduser('~/git')
git_url = 'https://github.com/besimorhino/powercat'
dest_path = '/usr/share/windows-binaries/powercat.ps1'



def git_new(app, url, install_path, app_script=None):

    # Change dir to the install_path
    os.chdir(install_path)

    # Clone the app into a new folder called $app
    try:
        proc = subprocess.check_output('git clone ' + str(url) + '.git ' + str(app), shell=True)
        print("[*] Output: {}".format(proc))
    except subprocess.CalledProcessError:
        print("[-] Error cloning. Git project already exists!")
        os.chdir(os.path.join(install_path, app))
        subprocess.call('git pull', shell=True)
    
    # Now process all special git apps, which require additional installation
    if app_script:
        run_helper_script(os.path.join(install_path, app, app_script))
    return

def main():
    #subprocess.call('git pull', shell=True)
    app_name = 'powercat'
    git_new(app_name, git_url, install_base)

    # copy file over to permanent residence
    orig_path = os.path.join(install_base, 'powercat', 'powercat.ps1')
    shutil.copy2(orig_path, dest_path)

    print("[*] Powercat setup complete")
    return



if __name__ == '__main__':
    main()
