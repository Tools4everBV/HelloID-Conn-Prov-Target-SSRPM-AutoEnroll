#################################################
# HelloID-Conn-Prov-Target-SSRPM-Import
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function get-SSRPMusers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$ConnectionString
    )
    try {
        Write-Information "retrieve SSRPM users"
        $query = "SELECT * FROM [enrolled users]"

        # Initialize connection and query information
        # Connect to the SQL server

        $SqlConnection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $SqlCmd = [System.Data.SqlClient.SqlCommand]::new($query, $SqlConnection)
        $SqlAdapter = [System.Data.SqlClient.SqlDataAdapter]::new($SqlCmd)
        $DataSet = [System.Data.DataSet]::new()
        $SqlAdapter.Fill($DataSet) | out-null

        $sqlData = $DataSet.Tables[0]
        Write-Information "Found $($sqlData.Rows.Count) user(s) in SSRPM database"
        $Rowlist = [System.Collections.Generic.List[object]]::new()

        foreach ($Row in $sqlData.rows) {
            $Rowlist.Add(($row | Select-Object -Property * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors))
        }
        return , $Rowlist

    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
#endregion

try {
    
    $accounts = get-SSRPMusers -ConnectionString $actionContext.Configuration.ConnectionString
    Write-Information "Successfully queried [$($accounts.count)] existing accounts"

    if ($accounts) {
        foreach ($account in $accounts) {
            if ([string]::IsNullOrEmpty($account.AD_DisplayName)) {
                $displayName = $account.AD_sAMAccountName
            }
            else {
                $displayName = $account.AD_DisplayName
            }

            Write-Output @{
                AccountReference = $account.Id
                DisplayName      = $displayName
                UserName         = $account.sAMAccountName
                Enabled          = $false
                Data             = $account
            }
            $success = $true
        }
    }
    else {
        throw "No accounts found"
    }
}
catch {
    $success = $false
    $ex = $PSItem

    
	$auditMessage = "Could not import SSRPM accounts. Error: $($ex.Exception.Message)"
	Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"

}
finally {
    if ($success -eq $false) {
        Write-Error $auditMessage
    }
}