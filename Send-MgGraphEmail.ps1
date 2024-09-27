function Send-Email {
    param(
        [string]$ToEmail,
        [string]$Subject,
        [string]$emailBodyBase64,
        [string]$FromEmail,
        [string]$AzureCredentialsJson
    )

    # Step 1: Decode the Base64 email body
    if ($emailBodyBase64) {
        $byteArray = [Convert]::FromBase64String($emailBodyBase64)
        $BodyContent = [Text.Encoding]::UTF8.GetString($byteArray)
    } else {
        Write-Host "Error: BodyContentBase64 is empty"
        exit 1
    }

    # Step 2: Parse Azure credentials
    try {
        $AzureCredentials = $AzureCredentialsJson | ConvertFrom-Json
    } catch {
        Write-Host "Error parsing AzureCredentialsJson"
        exit 1
    }

    # Step 3: Connect to Microsoft Graph
    try {
    # Ensure necessary modules are imported
        Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Force
        Install-Module -Name Microsoft.Graph.Users.Actions -Scope CurrentUser -Force
        Install-Module -Name Microsoft.Graph.Applications -Scope CurrentUser -Force
        Install-Module -Name Microsoft.Graph.Mail -Scope CurrentUser -Force
        Import-Module -Name Microsoft.Graph.Authentication -Scope Local -Force
        Import-Module -Name Microsoft.Graph.Users.Actions -Scope Local -Force
        Import-Module -Name Microsoft.Graph.Applications -Scope Local -Force
        Import-Module -Name Microsoft.Graph.Mail -Scope Local -Force
        $secureClientSecret = ConvertTo-SecureString -String $AzureCredentials.clientSecret -AsPlainText -Force
        $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AzureCredentials.clientId, $secureClientSecret
        Connect-MgGraph -TenantId $AzureCredentials.tenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome
    } catch {
        Write-Host "Error connecting to Microsoft Graph: $($_.Exception.Message)"
        exit 1
    }

    # Step 4: Create the email message object
    $message = @{
        Subject = $Subject
        ToRecipients = @(
            @{
                EmailAddress = @{
                    Address = $ToEmail
                }
            }
        )
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
Send-Email -ToEmail $ToEmail -Subject $Subject -BodyContentBase64 $emailBodyBase64 -FromEmail $FromEmail -AzureCredentialsJson $AzureCredentialsJson
