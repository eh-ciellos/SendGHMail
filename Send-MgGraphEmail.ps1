param(
    [Parameter(Mandatory = $true, HelpMessage = "Recipient email address(es), comma-separated if multiple")]
    [string]$ToEmail,
    [Parameter(Mandatory = $false, HelpMessage = "Cc email address(es), comma-separated if multiple")]
    [string]$CcEmail,
    [Parameter(Mandatory = $true, HelpMessage = "Subject of the email")]
    [string]$Subject,
    [Parameter(Mandatory = $true, HelpMessage = "Base64-encoded email body content")]
    [string]$emailBodyBase64,
    [Parameter(Mandatory = $true, HelpMessage = "Sender email address")]
    [string]$FromEmail,
    [Parameter(Mandatory = $true, HelpMessage = "Azure credentials as a JSON string")]
    [string]$AzureCredentialsJson
)

function Send-Email {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Recipient email address(es), comma-separated if multiple")]
        [string]$ToEmail,
        [Parameter(Mandatory = $false, HelpMessage = "Cc email address(es), comma-separated if multiple")]
        [string]$CcEmail,
        [Parameter(Mandatory = $true, HelpMessage = "Subject of the email")]
        [string]$Subject,
        [Parameter(Mandatory = $true, HelpMessage = "Base64-encoded email body content")]
        [string]$emailBodyBase64,
        [Parameter(Mandatory = $true, HelpMessage = "Sender email address")]
        [string]$FromEmail,
        [Parameter(Mandatory = $true, HelpMessage = "Azure credentials as a JSON string")]
        [string]$AzureCredentialsJson
    )

    try {
        # Step 1: Decode the Base64 email body
        $byteArray = [Convert]::FromBase64String($emailBodyBase64)
        $BodyContent = [Text.Encoding]::UTF8.GetString($byteArray)
        Write-Host "Decoded email body."

        # Step 2: Parse Azure credentials
        $AzureCredentials = $AzureCredentialsJson | ConvertFrom-Json
        Write-Host "Parsed Azure credentials successfully."

        # Step 3: Connect to Microsoft Graph
        $secureClientSecret = ConvertTo-SecureString -String $AzureCredentials.clientSecret -AsPlainText -Force
        $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AzureCredentials.clientId, $secureClientSecret
        Connect-MgGraph -TenantId $AzureCredentials.tenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome
        Write-Host "Connected to Microsoft Graph."

        # Step 4: Split email addresses into arrays
        $ToEmailArray = $ToEmail -split ',' | ForEach-Object { $_.Trim() }
        $CcEmailArray = if ($CcEmail) { $CcEmail -split ',' | ForEach-Object { $_.Trim() } } else { @() }
        $FromEmailAddress = ($FromEmail -split ',' | ForEach-Object { $_.Trim() })[0]

        # Prepare recipients
        $ToRecipients = $ToEmailArray | ForEach-Object {
            @{
                EmailAddress = @{
                    Address = $_
                }
            }
        }

        $CcRecipients = $CcEmailArray | ForEach-Object {
            @{
                EmailAddress = @{
                    Address = $_
                }
            }
        }

        # Step 5: Create the email message object
        $message = @{
            Subject = $Subject
            ToRecipients = $ToRecipients
            CcRecipients = $CcRecipients
            Body = @{
                ContentType = "HTML"
                Content = $BodyContent
            }
        }

        # Step 6: Send the email
        Send-MgUserMail -UserId $FromEmailAddress -Message $message -SaveToSentItems:$true
        Write-Host "Email sent successfully from $FromEmailAddress to $($ToEmailArray -join ', ')."

    } catch {
        Write-Error "An error occurred: $_"
        exit 1
    } finally {
        # Disconnect from Microsoft Graph
        Disconnect-MgGraph
        Write-Host "Disconnected from Microsoft Graph."
    }
}

# Call the function
Send-Email -ToEmail $ToEmail -CcEmail $CcEmail -Subject $Subject -emailBodyBase64 $emailBodyBase64 -FromEmail $FromEmail -AzureCredentialsJson $AzureCredentialsJson
