#Initialize default properties
$p = $person | ConvertFrom-Json;
$m = $manager | ConvertFrom-Json;
$success = $False;
$auditMessage = "for person $($p.DisplayName)";

$config = $configuration | ConvertFrom-Json;

#Get AD User info
$adUser = Get-AdUser -Identity $p.Accounts.ActiveDirectory.SamAccountName -Properties CanonicalName;

#Check for Mobile or Home phone
if($p.Contact.Business.Phone.Mobile.ToString().length -gt 0)
{
    $number = $p.Contact.Business.Phone.Mobile.ToString();
}
elseif($p.Contact.Business.Phone.Fixed.ToString().length -gt 0)
{
    $number = $p.Contact.Business.Phone.Fixed.ToString();
}
else
{
    $auditMessage = "No mobile or home phone number available for onboarding verification";
    throw "No mobile or home phone number available for onboarding verification";
}

#Change mapping here
$account = [PSCustomObject]@{
    CanonicalName = $adUser.CanonicalName;
    SamAccountName = $adUser.SamAccountName;
    ObjectSID = $adUser.SID.Value;
    DOB = (Get-Date -Date $p.details.birthdate).AddDays(1).toString("MMddyyyy");
    Phone = $number;
}
$success = $True;
if(-Not($dryRun -eq $True)) {
    try
    {
        $connectionString = "Data Source=$($config.server);Initial Catalog=$($config.database);persist security info=True;Integrated Security=SSPI;";    
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = $ConnectionString;
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandText = "ssrpm.dbo.enrolluser"
        $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
        [void]$SqlCmd.Parameters.AddWithValue("@ProfileID", '10') 
        [void]$SqlCmd.Parameters.AddWithValue("@AD_CononicalName", $account.CanonicalName)
        [void]$SqlCmd.Parameters.AddWithValue("@AD_sAMAccountName", $account.SamAccountName)
        [void]$SqlCmd.Parameters.AddWithValue("@AD_ObjectSID", $account.ObjectSID)
        [void]$SqlCmd.Parameters.AddWithValue("@XML_Answers", "<answers><a id='17'>$($account.Phone)</a><a id='16'>$($account.DOB)</a></answers>")
        $SqlCmd.Connection = $SqlConnection
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        $DataSet = New-Object System.Data.DataSet
        $SqlAdapter.Fill($DataSet)
        $SqlConnection.Close()
            
    }
    catch
    {
        $success = $False;
        $auditMessage = " : General error $($_)";
        Write-Error -Verbose $_; 
        
    }
    
}

$auditMessage = " successfully"; 

#build up result
$result = [PSCustomObject]@{ 
	Success= $success;
	AccountReference= $account.ObjectSID;
	AuditDetails=$auditMessage;
    Account = $account;
};

#send result back
Write-Output $result | ConvertTo-Json -Depth 10
