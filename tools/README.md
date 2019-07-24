# Tools

Contains useful scripts and tools for managing PDK planning

## SyncProjects.ps1

This script combines the [GitHub issues and pull requests in the PDK GitHub repository](https://github.com/puppetlabs/pdk) and the [Jira issues for the PDK Project](https://tickets.puppetlabs.com/projects/PDK/issues) into a single GitHub project. This allows people to view the state of a PDK release from a single place.

### Requirements

* Windows PowerShell version 5.1+ or PowerShell Core version 6.0+

* The `JiraPS` PowerShell module. This is installed automatically if not available

* A GitHub account. The script uses authenticated requests to avoid tripping the API rate limiting

### Requirements for GitHub and Jira

* The script only manages GitHub projects that match the following criteria:

  * Located in the [pdk-planning](https://github.com/puppetlabs/pdk-planning) repository

  * The project is named `Release x.y.z`, where x.y.z is the version.  For example `Release 1.12.0`

  * The project must have columns called `To do`, `In progress`, and `Done`.

  When creating a project, use the 'Basic Kanban' template to quickly create a compliant project.

* The script only detects GitHub issues in the [GitHub PDK repository](https://github.com/puppetlabs/pdk) which have a [Milestone](https://github.com/puppetlabs/pdk/milestones) that matches the project version.  For example a project with name `Release 1.12.0` expects a milestone called `1.12.0`

* The script only detects Jira tickets in the [Jira PDK project](https://tickets.puppetlabs.com/projects/PDK/issues) which have a [Fix Version](https://tickets.puppetlabs.com/projects/PDK?selectedItem=com.atlassian.jira.jira-projects-plugin:release-page&status=released-unreleased&contains=PDK) that matches the project version.  For example a project with name `Release 1.12.0` expects a fix version called `PDK 1.12.0`

### Running the script

* Set two environment variables

``` powershell
PS> $ENV:GITHUB_TOKEN = 'your github token or password'

PS> $ENV:GITHUB_USERNAME = 'your github username'
```

**WARNING** If you run the script with the Verbose flag (`-Verbose`) it is possible your GitHub Token could be output to the console in cleartext

* Run the script

``` powershell
PS> .\tools\SyncProjects.ps1
```

**WARNING** If you run the script with the Verbose flag (`-Verbose`) it is possible your GitHub Token could be output to the console in cleartext

Alternately, if you are running PowerShell on macOS or Linux, you can invoke the script like this:

```bash
pwsh -File tools/SyncProjects.ps1
```

which will inherit your parent shell's environment variables (such as previously exported `GITHUB_USERNAME/TOKEN`).

