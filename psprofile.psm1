
# Remove-Variable -Force HOME -erroraction 'silentlycontinue'
#Remove-Item Env:\HOMEPATH -ErrorAction SilentlyContinue
#Remove-Item Env:\HOMEDRIVE -ErrorAction SilentlyContinue
#Set-Variable HOME "C:\Users\villevai"
#(get-psprovider 'FileSystem').Home = 'C:\Users\villevai'
Set-Alias ccat pygmentize

function go_up {Set-Location -Path ..}

Set-Alias up go_up
Export-ModuleMember -Alias *
Export-ModuleMember go_up

Set-PSReadlineOption -BellStyle None
Set-PSReadlineKeyHandler -Key Tab -Function Complete

