#####################################################
# HelloID-Conn-Prov-Target-SSRPM-AutoEnroll-create
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

function Update-SSRPMuser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$connectionString,
        [Parameter(Mandatory = $true)][Object]$account
    )    
    try {
        if ([string]::IsNullOrEmpty($account.sAMAccountName) -OR
            [string]::IsNullOrEmpty($account.CanonicalName) -OR       
            [string]::IsNullOrEmpty($account.ObjectSID)) {
            Throw "one of the mandatory field is empty or missing"
        }

        $XML_Answers = $null   

        foreach ($answer in $account.answers) {
            if (-NOT([string]::IsNullOrEmpty($answer.QuestionID) -OR [string]::IsNullOrEmpty($answer.text))) {
                $XML_Answers += "<a id=""$($answer.QuestionID)"">$($answer.text)</a>"
            }
        }

        $XML_Answers = "<answers>" + $XML_Answers + "</answers>"

        #SQL connection
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = $ConnectionString;
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand

        #sql command
        $SqlCmd.CommandText = "updateUser"
        $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure

        #sql parameters
        [void]$SqlCmd.Parameters.AddWithValue("@SSRPM_ID", $account.SSRPMID)
        [void]$SqlCmd.Parameters.AddWithValue("@AD_CanonicalName", $account.CanonicalName)
        [void]$SqlCmd.Parameters.AddWithValue("@AD_sAMAccountName", $account.SamAccountName)
        [void]$SqlCmd.Parameters.AddWithValue("@AD_EmailAddress", $account.mail)
        [void]$SqlCmd.Parameters.AddWithValue("@AD_ObjectSID", $account.ObjectSID)

        [void]$SqlCmd.Parameters.AddWithValue("@Private_EmailAddress", $account.PrivateMail)
        [void]$SqlCmd.Parameters.AddWithValue("@Private_Mobile", $account.PrivateMobile)
        [void]$SqlCmd.Parameters.AddWithValue("@XML_Answers", $XML_Answers)
        
        $SqlCmd.Connection = $SqlConnection
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        $DataSet = New-Object System.Data.DataSet
        #execute
        $SqlAdapter.Fill($DataSet)
    
        $SqlConnection.Close()
        
    }
    catch {
        Throw "Failed to update new SSRPM user - Error: $($_)"    
    }
}

function format-date {
    [CmdletBinding()]
    Param
    (
        [string]$date,
        [string]$InputFormat,
        [string]$OutputFormat
    )
    try {
        if (-NOT([string]::IsNullOrEmpty($date))) {    
            $dateString = get-date([datetime]::ParseExact($date, $InputFormat, $null)) -Format($OutputFormat)
        }
        else {
            $dateString = $null
        }

        return $dateString
    }
    catch {
        throw("An error was thrown while formatting date: $($_.Exception.Message): $($_.ScriptStackTrace)")
    }
    
}

try {

    $account = [PSCustomObject]@{
        SSRPMID        = $aref
        # #on dependent system:
        # sAMAccountName = $p.accounts._2a468112bb3e42ed87f6f53c936d6640.SamAccountName
        # mail           = $p.accounts._2a468112bb3e42ed87f6f53c936d6640.mail
        # CanonicalName  = $null
        # ObjectSID      = $null

        #based on AD search:
        CanonicalName  = $null
        sAMAccountName = $null
        mail           = $null
        ObjectSID      = $null


        #SSRPM enrolment variables (optional):
        PrivateMobile  = $p.contact.Personal.Phone.Mobile
        privateMail    = $p.contact.Personal.Email
        answers        = @(@{
                QuestionID = 16 #geboortedatum
                text       = format-date -date $p.details.BirthDate  -InputFormat 'yyyy-MM-ddThh:mm:ssZ' -OutputFormat "dd-MM-yyyy"
            },
            @{
                QuestionID = 17 #postcode
                text       = $p.contact.personal.address.PostalCode -Replace '[^a-zA-Z0-9]', ""
            },
            @{
                QuestionID = 18
                text       = $p.externalID
            }
        )
    }

    try {
        $adUser = Get-AdUser -ldapfilter "(employeeid=$($p.externalID))" -Properties CanonicalName, samaccountname, mail
    }
    catch {
        $adUser = null
    }
    
    $account.CanonicalName = $adUser.CanonicalName
    $account.ObjectSID = $aduser.sid.value
    $account.samaccountname = $aduser.samaccountname
    $account.mail = $aduser.mail

    if (-Not($dryRun -eq $True)) {
        $result = Update-SSRPMuser -connectionString $connectionString -account $account       
    }
    else {
        write-verbose "will update during enforcement: $($account | convertto-json)"
    } 

    $auditLogs.Add([PSCustomObject]@{
            Message = "updated user successfully for $($p.displayname)"
            IsError = $false
        })
}
catch {
    $success = $false
    $auditLogs.Add([PSCustomObject]@{
            Message = "$action user failed - $($_)"
            IsError = $true
        })
}
finally {
    #build up result
    $result = [PSCustomObject]@{ 
        Success          = $success
        AccountReference = $account.SSRPMID
        auditLogs        = $auditLogs
        Account          = $account
        # Optionally return data for use in other systems
        ExportData       = @{
            ID             = $account.SSRPMID
            samaccountname = $account.samaccountname
        }
    };

    #send result back
    Write-Output $result | ConvertTo-Json -Depth 10
}

