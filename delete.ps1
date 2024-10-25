##################################################
# HelloID-Conn-Prov-Target-SSRPM-AutoEnroll-Delete
# PowerShell V2
##################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function get-SSRPMuserById {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][String]$Id
        , [Parameter(Mandatory)][string]$ConnectionString
    )
    try {
        Write-Information "Select user from [enrolled users] with id $Id"
        $query = "SELECT * FROM [enrolled users] WHERE id = '$($Id)'"

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
function Remove-SSRPMuser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$connectionString,
        [Parameter(Mandatory)][String]$Id
    )
    try {
        #SQL connection
        $SqlConnection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $SqlCmd = [System.Data.SqlClient.SqlCommand]::new()

        #sql command
        $SqlCmd.CommandText = "deleteUser"
        $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure

        #sql parameters
        [void]$SqlCmd.Parameters.AddWithValue("@SSRPM_ID", $Id)

        $SqlCmd.Connection = $SqlConnection
        $SqlAdapter = [System.Data.SqlClient.SqlDataAdapter]::new($SqlCmd)
        $DataSet = [System.Data.DataSet]::new()
        #execute
        $SqlAdapter.Fill($DataSet)
        $SqlConnection.Close()
    }
    catch {
        Throw "Failed to delete SSRPM user - Error: $($_)"
    }
}


#endregion

try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw 'The account reference could not be found'
    }

    Write-Information 'Verifying if a SSRPM-AutoEnroll account exists'
    $SSRPMUser = get-SSRPMuserById -Id $actionContext.References.Account -ConnectionString $actionContext.Configuration.ConnectionString

    # Always compare the account against the current account in target system
    if ($null -ne $SSRPMUser) {
        $action = 'DeleteAccount'
    }
    else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'DeleteAccount' {
            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information "Deleting SSRPM-AutoEnroll account with accountReference: [$($actionContext.References.Account)]"

                $result = Remove-SSRPMuser -connectionString $actionContext.Configuration.ConnectionString -Id $actionContext.References.Account
            }
            else {
                Write-Information "[DryRun] Delete SSRPM-AutoEnroll account with accountReference: [$($actionContext.References.Account)], will be executed during enforcement"
            }

            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = 'Delete account was successful'
                    IsError = $false
                })
            break
        }

        'NotFound' {
            Write-Information "SSRPM-AutoEnroll account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "SSRPM-AutoEnroll account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
                    IsError = $false
                })
            break
        }
    }
}
catch {
    $outputContext.success = $false
    $ex = $PSItem

    $auditMessage = "Could not delete SSRPM-AutoEnroll account. Error: $($_.Exception.Message)"
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"

    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}