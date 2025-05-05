
# starship prompt gives you a nice prompt with git status and other info

Invoke-Expression (&starship init powershell)


function pm { python -m $args }

# cd ..
function up {Set-Location -Path ..}

# pt runs tasks.py in the current directory or any parent directory.
# we have tasks.py in project root as a convention  
function pt {
    $currentDir = Get-Location
    $parentDir = $currentDir

    while ($parentDir -ne [System.IO.Path]::GetPathRoot($parentDir)) {
        $tasksPyPath = Join-Path -Path $parentDir -ChildPath "tasks.py"
        $venvPath = Join-Path -Path $parentDir -ChildPath ".venv"
        
        if (Test-Path $tasksPyPath) {
            Set-Location $parentDir
            if (Test-Path $venvPath) {
                uv run tasks.py $args
            } else {
                python tasks.py $args
            }
            Set-Location $currentDir
            return
        }
        $parentDir = Get-Item $parentDir | Select-Object -ExpandProperty Parent
    }

    Write-Host "tasks.py not found in any parent directory."
}

# aws autocompleter. You need to have the AWS CLI installed and configured for this to work.

Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        $env:COMP_LINE=$wordToComplete
        if ($env:COMP_LINE.Length -lt $cursorPosition){
            $env:COMP_LINE=$env:COMP_LINE + " "
        }
        $env:COMP_POINT=$cursorPosition
        aws_completer.exe | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
        Remove-Item Env:\COMP_LINE     
        Remove-Item Env:\COMP_POINT  
}


# make it behave like bash completion (show list of options), and make it STFU
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -BellStyle None

# zoxide kinda sucks tbh, but I use it
Invoke-Expression (& { (zoxide init powershell | Out-String) })
