param(
    [string]$ToEmail,
    [string]$Subject,
    [string]$emailBodyBase64,  # Ensure correct parameter name
    [string]$FromEmail,
    [string]$AzureCredentialsJson
)

function Send-Email {
    param(
        [string]$ToEmail,
        [string]$Subject,
        [string]$emailBodyBase64,  # Ensure correct parameter name
        [string]$FromEmail,
        [string]$AzureCredentialsJson
    )

    # Step 1: Decode the Base64 email body
    if (-not [string]::IsNullOrEmpty($emailBodyBase64)) {
        $byteArray = [Convert]::FromBase64String($emailBodyBase64)
        $BodyContent = [Text.Encoding]::UTF8.GetString($byteArray)
        Write-Host "Decoded email body."
    } else {
        Write-Host "Error: emailBodyBase64 is empty."
        exit 1
    }

    # Step 2: Parse Azure credentials
    try {
        $AzureCredentials = $AzureCredentialsJson | ConvertFrom-Json
        Write-Host "Parsed Azure credentials successfully."
    } catch {
        Write-Host "Error parsing AzureCredentialsJson: $($_.Exception.Message)"
        exit 1
    }

    # Step 3: Connect to Microsoft Graph
    try {
        $secureClientSecret = ConvertTo-SecureString -String $AzureCredentials.clientSecret -AsPlainText -Force
        $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AzureCredentials.clientId, $secureClientSecret
        Connect-MgGraph -TenantId $AzureCredentials.tenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome
        Write-Host "Connected to Microsoft Graph."
    } catch {
        Write-Host "Error connecting to Microsoft Graph: $($_.Exception.Message)"
        exit 1
    }

    # Step 4: Create the email message object
    # Split ToEmail into an array of addresses if multiple addresses are provided
    $ToRecipients = $ToEmail -split ',' | ForEach-Object {
        @{
            EmailAddress = @{
                Address = $_.Trim()
            }
        }
    }

    $message = @{
        Subject = $Subject
        ToRecipients = $ToRecipients
        Body = @{
            ContentType = "HTML"
            Content = $BodyContent
        }
    }

    # Step 5: Send the email
    try {
        Send-MgUserMail -UserId $FromEmail -Message $message -SaveToSentItems
        Write-Host "Email sent to $ToEmail successfully."
    } catch {
        Write-Host "Error sending email: $($_.Exception.Message)"
        exit 1
    }
}

# Call the function to send the email
Send-Email -ToEmail $ToEmail -Subject $Subject -emailBodyBase64 $emailBodyBase64 -FromEmail $FromEmail -AzureCredentialsJson $AzureCredentialsJson
