
$ErrorActionPreference = "Stop"

$BaseUrl = "http://localhost:3000"
$TemporaryPassword = "Practice-Only-2026!"

# Ask for API key without displaying it
$SecureKey = Read-Host "Enter Redmine admin API key" -AsSecureString
$Pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)

try {
    $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Pointer)
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Pointer)
}

$Headers = @{
    "X-Redmine-API-Key" = $ApiKey
    "Accept" = "application/json"
}

# Common API request function
function Invoke-RM {
    param(
        [string]$Method,
        [string]$Path,
        [hashtable]$Payload
    )

    $Params = @{
        Uri = "$BaseUrl$Path"
        Method = $Method
        Headers = $Headers
        ErrorAction = "Stop"
    }

    if ($null -ne $Payload) {
        $Params.ContentType = "application/json"
        $Params.Body = $Payload | ConvertTo-Json -Depth 15
    }

    try {
        return Invoke-RestMethod @Params
    }
    catch {
        Write-Host "API error: $Method $Path" -ForegroundColor Red

        if ($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message
        }

        throw
    }
}

Write-Host "`nTesting Redmine API..." -ForegroundColor Cyan

$CurrentUser = Invoke-RM -Method GET -Path "/users/current.json"

Write-Host "Authenticated successfully." -ForegroundColor Green

# 1. Create project if it does not exist
Write-Host "`nChecking project..." -ForegroundColor Cyan

$ProjectResponse = Invoke-RM -Method GET -Path "/projects.json?limit=100"

$Project = $ProjectResponse.projects |
    Where-Object { $_.identifier -eq "migration-practice" } |
    Select-Object -First 1

if (-not $Project) {
    $Created = Invoke-RM -Method POST -Path "/projects.json" -Payload @{
        project = @{
            name = "Migration Practice"
            identifier = "migration-practice"
            description = "Sample project for Redmine 4.2.11 to 7.0.3 migration."
            is_public = $false
            enabled_module_names = @(
                "issue_tracking",
                "time_tracking",
                "wiki",
                "files",
                "calendar",
                "gantt"
            )
        }
    }

    $Project = $Created.project
    Write-Host "Project created." -ForegroundColor Green
}
else {
    Write-Host "Project already exists. Reusing it."
}

$ProjectId = [int]$Project.id

# 2. Prepare sample users
$UserSpecs = @(
    @{
        Login = "manager1"
        First = "Ankit"
        Last = "Kumar"
        Mail = "manager1@example.com"
        Role = "Manager"
    },
    @{
        Login = "developer1"
        First = "Rahul"
        Last = "Sharma"
        Mail = "developer1@example.com"
        Role = "Developer"
    },
    @{
        Login = "developer2"
        First = "Amit"
        Last = "Verma"
        Mail = "developer2@example.com"
        Role = "Developer"
    },
    @{
        Login = "tester1"
        First = "Priya"
        Last = "Singh"
        Mail = "tester1@example.com"
        Role = "Reporter"
    }
)

Write-Host "`nCreating sample users..." -ForegroundColor Cyan

$AllUsers = (Invoke-RM -Method GET -Path "/users.json?limit=100").users

$UserIds = @{}

foreach ($Spec in $UserSpecs) {

    $User = $AllUsers |
        Where-Object { $_.login -eq $Spec.Login } |
        Select-Object -First 1

    if (-not $User) {
        $Created = Invoke-RM -Method POST -Path "/users.json" -Payload @{
            user = @{
                login = $Spec.Login
                firstname = $Spec.First
                lastname = $Spec.Last
                mail = $Spec.Mail
                password = $TemporaryPassword
            }
        }

        $User = $Created.user
        $AllUsers += $User

        Write-Host "Created: $($Spec.Login)" -ForegroundColor Green
    }
    else {
        Write-Host "Already exists: $($Spec.Login)"
    }

    $UserIds[$Spec.Login] = [int]$User.id
}

# 3. Find project roles
Write-Host "`nAdding project memberships..." -ForegroundColor Cyan

$RoleResponse = Invoke-RM -Method GET -Path "/roles.json"
$MembershipResponse = Invoke-RM -Method GET -Path "/projects/$ProjectId/memberships.json?limit=100"

foreach ($Spec in $UserSpecs) {

    $Role = $RoleResponse.roles |
        Where-Object { $_.name -eq $Spec.Role } |
        Select-Object -First 1

    if (-not $Role) {
        throw "Role not found: $($Spec.Role)"
    }

    $ExistingMembership = $MembershipResponse.memberships |
        Where-Object {
            $_.user -and [int]$_.user.id -eq $UserIds[$Spec.Login]
        } |
        Select-Object -First 1

    if (-not $ExistingMembership) {
        Invoke-RM -Method POST `
            -Path "/projects/$ProjectId/memberships.json" `
            -Payload @{
                membership = @{
                    user_id = $UserIds[$Spec.Login]
                    role_ids = @([int]$Role.id)
                }
            } | Out-Null

        Write-Host "Added $($Spec.Login) as $($Spec.Role)." -ForegroundColor Green
    }
}

# 4. Get tracker, status and priority IDs dynamically
$Trackers = (Invoke-RM -Method GET -Path "/trackers.json").trackers

$Statuses = (Invoke-RM -Method GET -Path "/issue_statuses.json").issue_statuses

$Priorities = (Invoke-RM -Method GET `
    -Path "/enumerations/issue_priorities.json").issue_priorities

$FeatureTracker = $Trackers |
    Where-Object { $_.name -eq "Feature" } |
    Select-Object -First 1

$BugTracker = $Trackers |
    Where-Object { $_.name -eq "Bug" } |
    Select-Object -First 1

if (-not $FeatureTracker -or -not $BugTracker) {
    throw "Required Bug or Feature tracker was not found."
}

$NewStatus = $Statuses |
    Where-Object { $_.name -eq "New" } |
    Select-Object -First 1

$ProgressStatus = $Statuses |
    Where-Object { $_.name -eq "In Progress" } |
    Select-Object -First 1

$NormalPriority = $Priorities |
    Where-Object { $_.name -eq "Normal" } |
    Select-Object -First 1

$HighPriority = $Priorities |
    Where-Object { $_.name -eq "High" } |
    Select-Object -First 1

$UrgentPriority = $Priorities |
    Where-Object { $_.name -eq "Urgent" } |
    Select-Object -First 1

if (-not $NewStatus -or -not $NormalPriority -or -not $HighPriority -or -not $UrgentPriority) {
    throw "Required issue status or priority was not found."
}

# 5. Create sample issues
Write-Host "`nCreating sample issues..." -ForegroundColor Cyan

$IssueSpecs = @(
    @{
        Subject = "Configure PostgreSQL database"
        Type = "Feature"
        Priority = "High"
        Status = "New"
        Assignee = "developer1"
        Description = "Configure and validate the PostgreSQL database connection."
    },
    @{
        Subject = "Configure application server"
        Type = "Feature"
        Priority = "Normal"
        Status = "In Progress"
        Assignee = "developer2"
        Description = "Prepare application server configuration and startup."
    },
    @{
        Subject = "Login page not working"
        Type = "Bug"
        Priority = "Urgent"
        Status = "New"
        Assignee = "developer1"
        Description = "Investigate and resolve the login functionality issue."
    },
    @{
        Subject = "Test user authentication"
        Type = "Feature"
        Priority = "High"
        Status = "In Progress"
        Assignee = "developer2"
        Description = "Test login, logout and user permission functionality."
    },
    @{
        Subject = "Prepare migration backup procedure"
        Type = "Feature"
        Priority = "Normal"
        Status = "New"
        Assignee = "manager1"
        Description = "Document database and attachment backup and restoration procedures."
    }
)

$ExistingIssues = Invoke-RM -Method GET `
    -Path "/issues.json?project_id=$ProjectId&status_id=*&limit=100"

foreach ($Spec in $IssueSpecs) {

    $AlreadyExists = $ExistingIssues.issues |
        Where-Object { $_.subject -eq $Spec.Subject } |
        Select-Object -First 1

    if ($AlreadyExists) {
        Write-Host "Already exists: $($Spec.Subject)"
        continue
    }

    $Tracker = if ($Spec.Type -eq "Bug") {
        $BugTracker
    } else {
        $FeatureTracker
    }

    $Priority = switch ($Spec.Priority) {
        "High" { $HighPriority }
        "Urgent" { $UrgentPriority }
        default { $NormalPriority }
    }

    $Status = if ($Spec.Status -eq "In Progress" -and $ProgressStatus) {
        $ProgressStatus
    } else {
        $NewStatus
    }

    $Created = Invoke-RM -Method POST -Path "/issues.json" -Payload @{
        issue = @{
            project_id = $ProjectId
            tracker_id = [int]$Tracker.id
            priority_id = [int]$Priority.id
            status_id = [int]$Status.id
            assigned_to_id = $UserIds[$Spec.Assignee]
            subject = $Spec.Subject
            description = $Spec.Description
        }
    }

    Write-Host "Created issue #$($Created.issue.id): $($Spec.Subject)" -ForegroundColor Green

    # Add an issue comment to create history
    Invoke-RM -Method PUT -Path "/issues/$($Created.issue.id).json" -Payload @{
        issue = @{
            notes = "Initial sample update created for migration testing."
        }
    } | Out-Null

    $ExistingIssues.issues += $Created.issue
}

# 6. Final count
$FinalIssues = Invoke-RM -Method GET `
    -Path "/issues.json?project_id=$ProjectId&status_id=*&limit=100"

Write-Host "`n========== SEEDING COMPLETED ==========" -ForegroundColor Green
Write-Host "Project: Migration Practice"
Write-Host "Project ID: $ProjectId"
Write-Host "Users: $($UserSpecs.Count)"
Write-Host "Issues in project: $($FinalIssues.total_count)"
Write-Host "Temporary user password: $TemporaryPassword"
Write-Host "======================================="
Write-Host "Change temporary passwords before real use."
