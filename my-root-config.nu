# This is my nushell starting point. I have it checked out in /r/dotfiles.
# Take it to use by running: 
# config nu
# and then add this line to the file:
# source /r/dotfiles/my-root-config.nu
 
# on windows, you want to have the --wait here so the editor doesn't return before time.
# ctrl+o editing hoesn't work without it.

$env.config.buffer_editor = ["code.cmd", "--wait"]


# if you are using "python tasks.py dostuff", iykyk
use task_tools.nu pt

# delete this line unless you have access to my secret sauces 
use my-proprietary-config.nu *

# place where I have done: git clone https://github.com/nushell/nu_scripts

const nu_scripts = "/r/nu_scripts"
const comp = $nu_scripts + "/custom-completions/"

# this was generated with:  uv generate-shell-completion nushell > /r/dotfiles/uv-completions.nu

use uv-completions.nu *

use ($comp + "aws/aws-completions.nu") *
use ($comp + "curl/curl-completions.nu") *
use ($comp + "dotnet/dotnet-completions.nu") *
use ($comp + "git/git-completions.nu") *
use ($comp + "rg/rg-completions.nu") *

# Some libs I'm using from std lib

use std-rfc/kv *


# activate virtualenv in current dir

alias act = overlay use .venv/Scripts/activate.nu