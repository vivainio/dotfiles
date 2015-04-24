Remove-Variable -Force HOME -erroraction 'silentlycontinue'
Remove-Item Env:\HOMEPATH
Remove-Item Env:\HOMEDRIVE
Set-Variable HOME "C:\Users\villevai"
(get-psprovider 'FileSystem').Home = 'C:\Users\villevai'
Set-Alias ccat pygmentize

Export-ModuleMember -Alias *