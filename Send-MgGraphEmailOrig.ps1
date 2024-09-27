function Send-Email {
    param(
        [string]$ToEmail,
        [string]$Subject,
        [string]$emailBodyBase64,
        [string]$FromEmail,
        [string]$AzureCredentialsJson
    )

    # Step 1: Parse the Azure Credentials
    $azureCredentials = $AzureCredentialsJson | ConvertFrom-Json

    # Extract values from the parsed JSON object
    $TenantId = $azureCredentials.tenantId
    $ClientId = $azureCredentials.clientId
    $ClientSecret = $azureCredentials.clientSecret

    # Step 2: Decode the Base64 email body to HTML
    $byteArray = [Convert]::FromBase64String($BodyContentBase64)
    $BodyContent = [Text.Encoding]::UTF8.GetString($byteArray)

    # Ensure necessary modules are imported
    Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Force
    Install-Module -Name Microsoft.Graph.Users.Actions -Scope CurrentUser -Force
    Install-Module -Name Microsoft.Graph.Applications -Scope CurrentUser -Force
    Install-Module -Name Microsoft.Graph.Mail -Scope CurrentUser -Force
    Import-Module -Name Microsoft.Graph.Authentication -Scope Local -Force
    Import-Module -Name Microsoft.Graph.Users.Actions -Scope Local -Force
    Import-Module -Name Microsoft.Graph.Applications -Scope Local -Force
    Import-Module -Name Microsoft.Graph.Mail -Scope Local -Force

    # Create a PSCredential object for the client secret
    $secureClientSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
    $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $secureClientSecret

    # Connect to Microsoft Graph using client credentials
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome

    # Create the email message object
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

    # Send the email
    Send-MgUserMail -UserId $FromEmail -Message $message -SaveToSentItems

    # Output for logging or debugging
    Write-Host "Email sent to $ToEmail with subject: '$Subject'"
}

# Example usage: replace this with your actual values or pass them via inputs in a composite action
# Send-Email -ToEmail "recipient@example.com" -Subject "Test Email" -BodyContentBase64 "<Base64EncodedHTML>" -FromEmail "your-email@ciellos.com" -AzureCredentialsJson "<AzureCredentialsJSON>"
