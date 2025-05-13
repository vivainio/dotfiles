use task_tools.nu pt

# these won't make sense to you, delete them unless I work with you ;-)
use /r/nu-aws/dh.nu *
use /r/nu-aws/aws.nu *
use /r/nu-aws/cmos.nu *

# place where I have done: git clone https://github.com/nushell/nu_scripts

const nu_scripts = "/r/nu_scripts"
const comp = $nu_scripts + "/custom-completions/"

# this was generated with:  uv generate-shell-completion nushell > /r/dotfiles/uv-completions.nu

use uv-completions.nu *

use ($comp + "git/git-completions.nu") *
use ($comp + "aws/aws-completions.nu") *
use ($comp + "dotnet/dotnet-completions.nu") *
use ($comp + "rg/rg-completions.nu") *
use ($comp + "curl/curl-completions.nu") *