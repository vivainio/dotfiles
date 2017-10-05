
Remove-Variable -Force HOME -erroraction 'silentlycontinue'
Remove-Item Env:\HOMEPATH -ErrorAction SilentlyContinue
Remove-Item Env:\HOMEDRIVE -ErrorAction SilentlyContinue
Set-Variable HOME "C:\Users\villevai"
(get-psprovider 'FileSystem').Home = 'C:\Users\villevai'
Set-Alias ccat pygmentize

function go_up {Set-Location -Path ..}

Set-Alias up go_up
Export-ModuleMember -Alias *
Export-ModuleMember go_up


#$GitPromptSettings.EnableFileStatus = $false

function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    # Reset color, which can be messed up by Enable-GitColors
    #$Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

    Write-Host($pwd.ProviderPath) -nonewline -ForegroundColor Green

    Write-VcsStatus

    # Prompt on newline, with cmder colours.
    Write-Host
    Write-Host ">" -nonewline -ForegroundColor DarkGray

    $global:LASTEXITCODE = $realLASTEXITCODE
    return " "
}

# More posh-git init.
#Enable-GitColors