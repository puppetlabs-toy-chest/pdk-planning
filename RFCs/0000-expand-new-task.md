# Expanded Bolt Task Authoring

## Summary

Implement various enhancements to the `pdk new task` command to make it easier to use PDK to implement Bolt Tasks that conform to current best practices.

## Background & Assumptions

- PDK has supported basic Bolt Task generation since version 1.2.0 which was released in October 2017.

- Since that time, Bolt has continued to grow and evolve, and new helper libraries and best practices for writing Bolt Tasks have emerged.

- See also: https://puppet.com/docs/bolt/latest/writing_tasks.html

## Motivation & Goals

PDK should provide up-to-date and robust tools for authoring all kinds of Puppet-related content, including Bolt Tasks. The current basic implementation of `pdk new task` can be improved in the following specific ways:

- Users should be able to specify what language they plan to implement a new task in and PDK should generate a language-appropriate scaffold.

- Users should be able to easily convert existing scripts into Bolt Tasks using PDK.

- Users should be able to more easily author "cross-platform" and "shared implementation" tasks.

## Proposed Implementation Design

### Add `--language` option to `pdk new task`

- Extend the current Bolt Task object templates to support language-specific templates.

- Add templates for Bash, PowerShell, Ruby, and Python.

- Ruby and Python templates should have scaffold implementations based on those languages Bolt Task helper libraries. (https://github.com/puppetlabs/puppetlabs-ruby_task_helper and https://github.com/puppetlabs/puppetlabs-python_task_helper)

- Ideally, users could configure a default task language as a module-specific configuration option.

- The new `--language` option will require an argument which is the name of the language-specific task template to be used.

- Acceptable values for the `--language` option will initially be `bash`, `powershell`, `ruby`, and `python`.

- The format of future language option values should be a concise, unique, all lowercase language identifier.

- If an unrecognized language option value is specified, PDK will exit with an error.

- If the `--language` option is specified without an argument, PDK will exit with an error.

#### Examples:

```bash
$ pdk new task my_default_task
pdk (INFO): Using default task language: 'bash'
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/my_default_task.sh' from template.
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/my_default_task.json' from template.
```

```bash
$ pdk new task --language=ruby my_ruby_task
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/my_ruby_task.rb' from template.
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/my_ruby_task.json' from template.
```

```bash
$ pdk new task --language=powershell my_ps_task
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/my_ps_task.ps1' from template.
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/my_ps_task.json' from template.
```

### Add `--from` option to `pdk new task`

- The new `--from` option will require an argument which is an absolute or relative path to an existing script file.

- If the `--from` option is specified without an argument, PDK will exit with an error.

- If the given file does not exist or is not readable, PDK will exit with an error.

- If the given file exists and is readable, PDK will copy it into the `tasks` subdirectory of the current module and write the copy with a name matching the task name supplied to `pdk new task`.

  - For example: `pdk new task --from=/tmp/myscript.sh restart` will copy `/tmp/myscript.sh` to `tasks/restart.sh`.

- For languages that support it (currently only PowerShell?), PDK will attempt to automatically determine the parameters (and output format?) of the source script and use that data to automatically populate the Bolt Task metadata file.

### Add `--private` and `--remote` flags to `pdk new task`

- When specified, these flags will simply pre-populate the generated Bolt Task metadata with `"private": true` and `"remote": true` key/value pairs respectively.

### Add optional `<implementations>` argument to `pdk new task`

- Allow `pdk new task` to accept an unbounded, space-separated list of `implementations` to be provided after the task name.

- When one or more implementation files are provided, PDK will only generate a `tasks/<taskname>.json` file for the new task. The generated metadata will contain an `"implementations"` key with each given implementation file listed.

- If the `--language` option is provided at the same time as one or more `<implementation>` arguments, PDK should exit with an appropriate error message.

#### Examples

The following example illustrates how a user might use PDK to author a new "cross-platform" task with Windows- and Linux-specific implementations:

```bash
$ pdk new task --private --language=bash sql_linux
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/sql_linux.sh' from template.
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/sql_linux.json' from template.

$ pdk new task --private --language=powershell sql_windows
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/sql_windows.ps1' from template.
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/sql_windows.json' from template.

$ pdk new task sql tasks/sql_linux.sh tasks/sql_windows.ps1
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/sql.json' from template.
pdk (INFO): Added implementation 'sql_linux.sh' to '/Users/jesse/sandbox/pdk/testmod/tasks/sql.json'
pdk (INFO): Added implementation 'sql_windows.rb' to '/Users/jesse/sandbox/pdk/testmod/tasks/sql.json'
```

Given the following task implementation script already exists at `tasks/init.rb`:

```ruby
#!/usr/bin/env ruby
require 'json'

params = JSON.parse(STDIN.read)
action = params['action'] || params['_task']
if ['start',  'stop'].include?(action)
  `systemctl #{params['_task']} #{params['service']}`
end
```

The following example illustrates how a user might use PDK to author a new set of "shared-implementation" tasks

```bash
$ pdk new task start tasks/init.rb
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/start.json' from template.
pdk (INFO): Added implementation 'init.rb' to '/Users/jesse/sandbox/pdk/testmod/tasks/start.json'

$ pdk new task stop tasks/init.rb
pdk (INFO): Creating '/Users/jesse/sandbox/pdk/testmod/tasks/stop.json' from template.
pdk (INFO): Added implementation 'init.rb' to '/Users/jesse/sandbox/pdk/testmod/tasks/stop.json'
```

## Unresolved Questions

- Should `--private` and/or `--remote` be disallowed in combination with `<implementations>`?

- Is there a way to infer implementation "requirements" from the given implementation arguments? E.g. can we safely infer a `shell` requirement for an implementation file ending in `.sh`?

## Future Considerations

- As Bolt continues to iterate and add functionality we may need to add additional options and flags to the task generators.

- We should consider ways that PDK could help authors define their task's parameters.

- We should consider ways that PDK could help authors declare their task's file/module dependencies.

- We should consider ways that PDK could help authors with the "Wrapping an existing script" workflow described in the Bolt "Writing Tasks" documentation[^1]

## Drawbacks

- New options and flags add additional complexity to the user-interface. Some combinations of options and flags may be invalid or have unexpected outcomes that are hard to document in the limited space afforded in command-line `--help` output.

- Listing task implementations as positional arguments after the task name may not be intuitive and precludes the addition of new positional arguments to `pdk new task` for other purposes in the future.

## Alternatives

- Considered adding an `--implementations=<implementations>` option instead of using positional arguments to list implementations. Decided that the value of shell-provided tab completion for implementation files and reduced verbosity outweighed the value provided by a more explicit option.

[^1]: https://puppet.com/docs/bolt/latest/writing_tasks.html