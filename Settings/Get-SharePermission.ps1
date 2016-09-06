function Get-SharePermission {
    Param($ComputerName = $env:ComputerName)
    $ShareData = @{}; $Shares = @()
    Try {
        #Calling Win32_Share to get the names of all the shares that exist
        Get-WMIObject win32_Share -ComputerName $ComputerName -ErrorAction Stop | Foreach {$ShareData += @{$_.Name= @{'Path'=$_.Path;'Description'=$_.Description}}}
        #Calling Win32_LogicalShareSecuritySetting. This only returns shares that have explicitly defined ACLs
        $ShareSecurity = Get-WMIObject win32_LogicalShareSecuritySetting -comp $ComputerName
        foreach($Share in $ShareSecurity) {
            $ShareName = $Share.Name
            $ACLS = $Share.GetSecurityDescriptor().Descriptor.DACL
            foreach($ACL in $ACLS) {
                $User = "$($ACL.Trustee.Domain)\$($ACL.Trustee.Name)"
                switch ($ACL.AccessMask) {
                    2032127   {$Perm = "Full Control"}
                    1245631   {$Perm = "Change"}
                    1179817   {$Perm = "Read"}
                }
                New-Object PSobject -Property @{
                    'Server'      = $ComputerName
                    'ShareName'   = $ShareName
                    'Path'        = $ShareData[$ShareName].Path
                    'Description' = $ShareData[$ShareName].Description
                    'User'        = $User
                    'Permission'  = $Perm
                } # End property specification
            } # End each ACL
        } # End each Share
    } # End Try
    Catch {} # End Catch
}
