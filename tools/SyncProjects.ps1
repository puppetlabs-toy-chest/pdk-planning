[CmdletBinding()]
param()

# Needs PowerShell 5.1+
$ErrorActionPreference = 'Stop'

try {
  # Need the JiraPS module to query Jira
  Import-Module JiraPS -ErrorAction Stop
}
catch {
  Install-Module JiraPS -ErrorAction Stop
  Import-Module JiraPS -ErrorAction Stop
}

$script:GithubToken = $ENV:GITHUB_TOKEN
$script:GithubUsername = $ENV:GITHUB_USERNAME
$script:JiraServer = 'https://tickets.puppetlabs.com'

if ($null -eq $script:GithubToken) { Throw "This script requires the GITHUB_TOKEN environment variable to be set"; Exit 1 }
if ($null -eq $script:GithubUsername) { Throw "This script requires the GITHUB_USERNAME environment variable to be set"; Exit 1 }

Function Invoke-GithubAPI {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory = $True, ParameterSetName = 'RelativeURI')]
    [String]$RelativeUri,

    [Parameter(Mandatory = $True, ParameterSetName = 'AbsoluteURI')]
    [String]$AbsoluteUri,

    [Parameter(Mandatory = $False)]
    [switch]$Raw,

    [String]$Method = 'GET',

    [Object]$Body = $null
  )

  if ($PsCmdlet.ParameterSetName -eq 'RelativeURI') {
    $uri = "https://api.github.com" + $RelativeUri
  }
  else {
    $uri = $AbsoluteUri
  }

  $result = ""

  $oldPreference = $ProgressPreference

  $auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($script:GithubUsername + ':' + $script:GithubToken));

  $ProgressPreference = 'SilentlyContinue'
  $Headers = @{
    'Accept'        = 'application/vnd.github.inertia-preview+json' # Needed for project API
    'Authorization' = $auth;
  }
  $splat = @{
    'Uri'             = $uri
    'UseBasicParsing' = $True
    'Headers'         = $Headers
    'Method'          = $Method
  }
  if ($null -ne $Body) { $splat['Body'] = ConvertTo-Json $Body -Compress }
  try {
    $result = Invoke-WebRequest @splat -ErrorAction 'Stop'
  } catch {
    Write-Verbose "Invoke-WebRequest arguments were $($splat | ConvertTo-JSON -Depth 10)"
    Throw $_
  }
  $ProgressPreference = $oldPreference

  if ($Raw) {
    Write-Output $result
  }
  else {
    Write-Output $result.Content | ConvertFrom-JSON
  }
}

Function Invoke-GithubAPIWithPaging($RelativeUri) {
  $response = Invoke-GithubAPI -RelativeUri $RelativeUri -Raw
  $result = $response.Content | ConvertFrom-Json
  if (!($result -is [Array])) { $result = @($result) }
  $nextLink = $response.RelationLink.next
  do {
    if ($null -ne $nextLink) {
      $response = Invoke-GithubAPI -AbsoluteUri $nextLink -Raw
      $result = $result + ($response.Content | ConvertFrom-Json)
      $nextLink = $response.RelationLink.next
    }
  }
  while ($null -ne $nextLink)

  Write-Output $result
}

Function Get-PDKProjects {
  Invoke-GithubAPIWithPaging -RelativeUri '/repos/puppetlabs/pdk-planning/projects?state=open'
}

Function Convert-GHIssueToNote {
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [Object]$Issue
  )

  Process {
    # We only add the title, because github fills in the description as a rich-link
    $hash = @{
      'cardId'         = -1
      'note'           = @"
[GitHub Issue $($issue.number)]($($issue.html_url))

$($issue.title)
"@
      'expectedColumn' = 'To do'
    }

    # Consider all open pull requests as "in progress"
    if ($Issue.pull_request -ne $null) { $hash['expectedColumn'] = 'In progress' }
    if ($Issue.state -eq 'closed') { $hash['expectedColumn'] = 'Done' }

    Write-Output ([PSCustomObject]$hash)
  }
}

Function Convert-GHCardToNote {
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [Object]$Card,

    [String]$ColumnName
  )

  Process {
    # Write-Host ($Card | ConvertTo-JSON) -ForegroundColor Red
    $hash = @{
      'foundMatchingIssue' = $false
      'note'               = $Card.note
      'id'                 = $Card.id
      'currentColumn'      = $ColumnName
      'expectedColumn'     = '????'
    }
    Write-Output ([PSCustomObject]$hash)
  }
}

Function Get-JiraIssues($fixVersion) {
  Set-JiraConfigServer $script:JiraServer

  $Query = "project = `"Puppet Development Kit`" and fixVersion = `"${fixVersion}`""

  try {
    Get-JiraIssue -Query $Query -Fields "-comment" -ErrorAction 'Stop' | ForEach-Object {
      $Issue = $_

      $hash = @{
        'cardId'         = -1
        'note'           = @"
[Jira Issue $($Issue.key)]($($issue.HttpUrl))

$($issue.Summary)
"@
        'expectedColumn' = 'To do'
      }
      # There's probably more than this for in progress...
      if ($Issue.Status -eq 'In progress') { $hash['expectedColumn'] = 'In progress'}
      if ($Issue.Status -eq 'Ready for merge') { $hash['expectedColumn'] = 'In progress'}
      if ($Issue.Status -eq 'Ready for test') { $hash['expectedColumn'] = 'In progress'}
      if ($Issue.Status -eq 'Ready for ci') { $hash['expectedColumn'] = 'In progress'}
      if ($Issue.Status -eq 'Ready for review') { $hash['expectedColumn'] = 'In progress'}
      if ($Issue.Status -eq 'Closed') { $hash['expectedColumn'] = 'Done'}
      if ($Issue.Status -eq 'Resolved') { $hash['expectedColumn'] = 'Done'}
      if ($Issue.Status -eq 'Completed') { $hash['expectedColumn'] = 'Done'}
      Write-Output ([PSCustomObject]$hash)
    }
  }
  catch {
    Write-Warning "Error querying Jira $_"
  }
}

Function Resize-String($Value, $MaxLength) {
  if ($Value.Length -gt $MaxLength) {
    Write-Output ($Value.SubString(0, $MaxLength) + "...")
  }
  else {
    Write-Output $Value
  }
}

Function Invoke-ParsePDKProject($project) {
  if ($project.name -notmatch '^Release ([\w ]+)$') {
    Write-Verbose "Project $($project.name) is not a release"
    return
  }
  Write-Verbose "Parsing Project $($project.name) ..."
  $ProjectVersion = $Matches[1]
  $MilestoneName = $ProjectVersion
  $JiraFixVersion = "PDK $ProjectVersion"

  # Get all columns
  $ProjectColumns = Invoke-GithubAPIWithPaging -RelativeUri "/projects/$($project.id)/columns"

  # Get all cards, including archived
  Write-Verbose "Getting existing cards ..."
  $ProjectCards = @()
  $ColumnIds = @{}
  $ProjectColumns | ForEach-Object {
    $ColumnName = $_.name
    $ColumnIds[$_.name] = $_.id
    Invoke-GithubAPIWithPaging -RelativeUri "/projects/columns/$($_.Id)/cards?archived_state=all" | ForEach-Object { $ProjectCards += (Convert-GHCardToNote -Card $_ -ColumnName $ColumnName) }
  }

  # Sanity check for columns we need
  if ($null -eq $ColumnIds['To do']) { Write-Warning "Project $($Project.number) is missing expected column 'To do'"; Return}
  if ($null -eq $ColumnIds['In progress']) { Write-Warning "Project $($Project.number) is missing expected column 'In progress'"; Return}
  if ($null -eq $ColumnIds['Done']) { Write-Warning "Project $($Project.number) is missing expected column 'Done'"; Return}

  Write-Verbose "Getting current issues in the PDK repo for milestone ${MilestoneName} ..."
  # Get all of the issues for the PDK version milestone
  $GHIssues = (Invoke-GithubAPIWithPaging -RelativeUri "/search/issues?q=repo:puppetlabs/pdk+milestone:`"${MilestoneName}`"").items | Convert-GHIssueToNote

  Write-Verbose "Getting current tickets in the PDK project for fix version ${JiraFixVersion} ..."
  # Get all of the Jira tickets
  $JiraTickets = Get-JiraIssues -fixVersion $JiraFixVersion

  Write-Verbose "Matching Issues to Notes ..."
  # Match things up
  $ProjectCards | ForEach-Object -Process {
    $thisCard = $_
    # Try and find a matching GHIssue
    $GHIssues | Where-Object { $_.cardId -eq -1} | ForEach-Object -Process {
      if ($_.note -eq $thisCard.note) {
        Write-Verbose "Found a match for card $($thisCard.Id)"
        $_.cardId = $thisCard.Id
        $thisCard.expectedColumn = $_.expectedColumn
        $thisCard.foundMatchingIssue = $true
      }
    }
    if (!$thisCard.foundMatchingIssue) {
      $JiraTickets | Where-Object { $_.cardId -eq -1} | ForEach-Object -Process {
        if ($_.note -eq $thisCard.note) {
          Write-Verbose "Found a match for card $($thisCard.Id)"
          $_.cardId = $thisCard.Id
          $thisCard.expectedColumn = $_.expectedColumn
          $thisCard.foundMatchingIssue = $true
        }
      }
    }
  }

  # Create new cards from GH Issues
  $GHIssues | Where-Object { $_.cardId -eq -1 } | ForEach-Object {
    $Issue = $_
    $body = @{ 'note' = $Issue.note }
    Write-Host "Adding card for `"$(Resize-String -Value $Issue.note -MaxLength 50)`""
    Invoke-GithubAPI -RelativeUri "/projects/columns/$($ColumnIds[$Issue.expectedColumn])/cards" -Method 'POST' -Body $body | Out-Null
  }

  # Create new cards from Jira Issues
  $JiraTickets | Where-Object { $_.cardId -eq -1 } | ForEach-Object {
    $Issue = $_
    $body = @{ 'note' = $Issue.note }
    Write-Host "Adding card for `"$(Resize-String -Value $Issue.note -MaxLength 50)`""
    Invoke-GithubAPI -RelativeUri "/projects/columns/$($ColumnIds[$Issue.expectedColumn])/cards" -Method 'POST' -Body $body | Out-Null
  }

  # Remove cards which can not be matched
  $ProjectCards | Where-Object { -not $_.foundMatchingIssue } | ForEach-Object -Process {
    Write-Host "Removing card `"$(Resize-String -Value $_.note -MaxLength 50)`""
    Invoke-GithubAPI -RelativeUri "/projects/columns/cards/$($_.id)" -Method 'DELETE' | Out-Null
  }
  # Move cards which are in the wrong column
  $ProjectCards | Where-Object { $_.foundMatchingIssue -and ($_.expectedColumn -ne $_.currentColumn) } | ForEach-Object -Process {
    $body = @{ 'position' = 'top'; 'column_id' = $ColumnIds[$_.expectedColumn] }
    Write-Host "Moving card `"$(Resize-String -Value $_.note -MaxLength 50)`" to `"$($_.expectedColumn)`""
    Invoke-GithubAPI -RelativeUri "/projects/columns/cards/$($_.id)/moves" -Method 'POST' -Body $Body | Out-Null
  }
}

Get-PDKProjects | ForEach-Object { Invoke-ParsePDKProject $_ }
