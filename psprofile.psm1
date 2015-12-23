Remove-Variable -Force HOME -erroraction 'silentlycontinue'
Remove-Item Env:\HOMEPATH
Remove-Item Env:\HOMEDRIVE
Set-Variable HOME "C:\Users\villevai"
(get-psprovider 'FileSystem').Home = 'C:\Users\villevai'
Set-Alias ccat pygmentize

function go_up {Set-Location -Path ..}

Set-Alias up go_up
Export-ModuleMember -Alias *
Export-ModuleMember go_up
