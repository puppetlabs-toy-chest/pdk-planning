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

## when\_projects\_created.rb (Github Workflow Script)

This ruby script is attached to a Github workflow (see `.github/workflows/when_project_created.yml`) which responds
to a new project being created in the `pdk-planning` repo and, if the new project name matches `/\ARelease /` it
will create the appropriate Milestones in the `pdk`, `pdk-templates`, and `pdk-vanagon` repos.

### How to test the standalone script

The script itself can be tested simply by running it with Ruby/Bundler. When run outside of the Github action context
it will not actually create any new milestones:

```
~/pdk-planning $ cd tools
~/pdk-planning/tools $ GITHUB_TOKEN=<github_api_token> GITHUB_EVENT_PATH=fixtures/gh_new_release_project_created.json bundle exec when_project_created.rb
Would have created milestone 'January TEST' on puppetlabs/pdk
Would have created milestone 'January TEST' on puppetlabs/pdk-templates
Would have created milestone 'January TEST' on puppetlabs/pdk-vanagon
```

There are additional fixture event payloads you can test in the `tools/fixtures` directory. Specify which payload
you want to test using the `GITHUB_EVENT_PATH` environment variable as shown above.

### How to test the Github workflow

You will need Docker and the [`act`](https://github.com/nektos/act#installation) tool to test the full workflow.

**Warning: The Docker image that is pulled to make this workflow run locally is very large (~18GB at the time of this writing).**

Run the following from the _root_ of this repo:

```
~/pdk-planning $ act -P ubuntu-latest=nektos/act-environments-ubuntu:18.04 -s PDKBOT_GITHUB_TOKEN=$GITHUB_TOKEN -e tools/fixtures/gh_new_release_project_created.json
```

Note that you still need a valid `GITHUB_TOKEN` set.

You should see something like the following:

```
[New Project Created/Run when_project_created.rb] 🚀  Start image=nektos/act-environments-ubuntu:18.04
[New Project Created/Run when_project_created.rb]   🐳  docker run image=nektos/act-environments-ubuntu:18.04 entrypoint=["/usr/bin/tail" "-f" "/dev/null"] cmd=[]
[New Project Created/Run when_project_created.rb]   🐳  docker cp src=/Users/jesse/src/sdk/pdk-planning/. dst=/github/workspace
[New Project Created/Run when_project_created.rb] ⭐  Run actions/checkout@v2
[New Project Created/Run when_project_created.rb]   ✅  Success - actions/checkout@v2
[New Project Created/Run when_project_created.rb] ⭐  Run ruby/setup-ruby@v1.20.1
[New Project Created/Run when_project_created.rb]   ☁  git clone 'https://github.com/ruby/setup-ruby' # ref=v1.20.1
[New Project Created/Run when_project_created.rb]   🐳  docker cp src=/Users/jesse/.cache/act/ruby-setup-ruby@v1.20.1 dst=/actions/
| Using 2.6.3 as input from file .ruby-version
| https://github.com/ruby/ruby-builder/releases/download/builds-no-warn/ruby-2.6.3-ubuntu-18.04.tar.gz
[New Project Created/Run when_project_created.rb]   💬  ::debug::Downloading https://github.com/ruby/ruby-builder/releases/download/builds-no-warn/ruby-2.6.3-ubuntu-18.04.tar.gz
[New Project Created/Run when_project_created.rb]   💬  ::debug::Downloading /home/actions/temp/9a747bcf-dcae-4cb0-a0f9-eb8e2693017f
[New Project Created/Run when_project_created.rb]   💬  ::debug::download complete
| [command]/bin/tar xz -C /github/home/.rubies -f /home/actions/temp/9a747bcf-dcae-4cb0-a0f9-eb8e2693017f
[New Project Created/Run when_project_created.rb]   ⚙  ::add-path:: /github/home/.rubies/ruby-2.6.3/bin
[New Project Created/Run when_project_created.rb]   ⚙  ::set-output:: ruby-prefix=/github/home/.rubies/ruby-2.6.3
[New Project Created/Run when_project_created.rb]   ✅  Success - ruby/setup-ruby@v1.20.1
[New Project Created/Run when_project_created.rb] ⭐  Run when_project_created.rb
| Fetching bundler-2.0.2.gem
| Successfully installed bundler-2.0.2
| 1 gem installed
| Don't run Bundler as root. Bundler can ask for sudo if it is needed, and
| installing your bundle as root will break this application for all non-root
| users on this machine.
| Using public_suffix 4.0.3
| Using addressable 2.7.0
| Using bundler 2.0.2
| Using multipart-post 2.1.1
| Using faraday 1.0.0
| Using sawyer 0.8.2
| Using octokit 4.16.0
| Bundle complete! 2 Gemfile dependencies, 7 gems now installed.
| Gems in the group development were not installed.
| Bundled gems are installed into `./.bundle`
| Would have created milestone 'January TEST' on puppetlabs/pdk
| Would have created milestone 'January TEST' on puppetlabs/pdk-templates
| Would have created milestone 'January TEST' on puppetlabs/pdk-vanagon
[New Project Created/Run when_project_created.rb]   ✅  Success - when_project_created.rb
```
