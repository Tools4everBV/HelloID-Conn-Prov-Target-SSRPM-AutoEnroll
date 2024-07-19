#####################################################
# HelloID-Conn-Prov-Target-SSRPM-AutoEnroll-delete
#
# Version: 2.0.0
#####################################################

#Initialize default properties
$p = $person | ConvertFrom-Json
$c = $configuration | ConvertFrom-Json
$aref = $accountreference | ConvertFrom-Json

$connectionString = "Data Source=$($c.server);Initial Catalog=$($c.database);persist security info=True;Integrated Security=SSPI;";    

$success = $true # Set to true at start, because only when an error occurs it is set to false
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

# Set debug logging
switch ($($c.isDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}

function Remove-SSRPMuser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$connectionString,
        [Parameter(Mandatory = $true)][Object]$account
    )    
    try {
        #SQL connection
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = $ConnectionString;
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand

        #sql command
        $SqlCmd.CommandText = "deleteUser"
        $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure

        #sql parameters
        [void]$SqlCmd.Parameters.AddWithValue("@SSRPM_ID", $account.SSRPMID)        
        
        $SqlCmd.Connection = $SqlConnection
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        $DataSet = New-Object System.Data.DataSet
        #execute
        $SqlAdapter.Fill($DataSet)
    
        $SqlConnection.Close()
        
    }
    catch {
        Throw "Failed to delete SSRPM user - Error: $($_)"    
    }
}

try {
    $account = [PSCustomObject]@{
        SSRPMID = $aref
    }

    if (-Not($dryRun -eq $True)) {
        $result = Remove-SSRPMuser -connectionString $connectionString -account $account       
    }
    else {
        write-verbose -verbose "will be deleted during enforcement: $($account | convertto-json)"
    } 

    $auditLogs.Add([PSCustomObject]@{
            Message = "deleted user successfully for $($p.displayname)"
            IsError = $false
        })
}
catch {
    $success = $false
    $auditLogs.Add([PSCustomObject]@{
            Message = "deleting user failed - $($_)"
            IsError = $true
        })
}

#build up result
$result = [PSCustomObject]@{ 
    Success          = $success
    AccountReference = $account.SSRPMID
    auditLogs        = $auditLogs
    Account          = $account
};

#send result back
Write-Output $result | ConvertTo-Json -Depth 10