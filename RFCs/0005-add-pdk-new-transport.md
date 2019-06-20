# Add `pdk publish` subcommand

## Summary

Add a new `pdk publish` subcommand that allows publishing a given module tarball to the Forge.  
*Note that this RFC supersedes [RFC-0003](https://github.com/puppetlabs/pdk-planning/blob/master/RFCs/0003-add-pdk-release.md). While RFC-0003 may eventually still be implemented (likely as part of a PDK 2.x major release), this work represents a smaller scope that is more appropriate to the current PDK 1.x series.*

## Background & Assumptions

- With the addition of module management endpoints to the Forge API and authentication via API keys, [authenticating](https://forgeapi.puppet.com/#section/Authentication) and [publishing](https://forgeapi.puppet.com/#operation/addRelease) to the Forge has a public and stable interface.

- Publishing to the Forge is a natural progression beyond the current `pdk build` subcommand, and is an action that may be performed manually or through an automated process.

## Motivation & Goals

- PDK should provide an easy way for module authors to package and distribute their modules via the Puppet Forge.

- PDK should provide composable commands and actions so that module authors can automate the packaging and distribution of their modules, and integrate those steps into a comprehensive CI/CD pipeline.


## Proposed Implementation Design

Implement a new pdk subcommand, `pdk publish`, with the following syntax, options, and arguments.

- Basic syntax:
    - `pdk publish [--package-dir=<path>] [--force] [tarball.tar.gz]`


- Options and arguments:
    - `--package-dir=<path>`
      - Use given path as path to find tarball to publish.

    - `--force`
      - Do not prompt for confirmation.

    - `tarball.tar.gz`
      - Relative or absolute path to tarball to publish.

- Option combination behaviors:
    - `(no options/arguments)`
      - Looks in current module’s `metadata.json` for namespace, module name, and version and then attempts to publish `<namespace>-<module_name>-<version>.tar.gz` from default package path. Default package path is located at `<moduleroot>/pkg`, where `<moduleroot>` is the directory containing the module's `metadata.json` file.
      - If file matching the `<namespace>-<module_name>-<version>.tar.gz` pattern cannot be found in the default package path, exits with an error suggesting that user needs to use `pdk build` first.


    - `tarball.tar.gz`
      - Attempts to publish given pathed tarball.
      - If given tarball cannot be found, exits with an error.


    - `--package-dir=<path>`
      - Looks in current module’s `metadata.json` for namespace, module name, and version and then attempts to publish `<namespace>-<module_name>-<version>.tar.gz` from given path.
      - If file matching the `<namespace>-<module_name>-<version>.tar.gz` cannot be found in the given path, exits with an error.
      

    - `--package-dir=<path> tarball.tar.gz`
      - Logs a warning that `--package-dir` option is being ignored in favor of pathed tarball argument.
      - Attempts to publish given pathed tarball.
      - If given pathed tarball cannot be found, exits with an error.


    - `(any valid options/args) --force`
      - Attempts to publish without stopping to ask for confirmation.
      - Note that command will still fail, regardless of the `--force` flag, if a release of the module with the same version already exists on the Forge.

- Defaults to asking for confirmation when run interactively, but this can be disabled. (See `--force` flag.)

- When run non-interactively (e.g. as part of a continuous delivery pipeline), it will default to not asking for confirmation (`--force` behavior) and exit non-zero if it would require any user input to complete successfully.

- Need to track namespace/api-key mapping in user-level config.
    - Look inside tarball to determine namespace
    - Check to see if config contains an api-key for that namespace
    - Prompt for api-key if not (can use existing wrappers around tty-prompt)

- Need to be able to provide api-key as an environment variable with the name PDK_FORGE_KEY

- As much as possible, the HTTP calls to the Forge API should be implemented in the puppet_forge gem and invoked from PDK, to allow sharing of the API interaction logic across projects.

### Examples

#### Publishing a tarball matching data from metadata.json when no options / arguments are provided 
```
$ pdk publish  
pdk (INFO): Attempting to publish puppetlabs-mysql-0.1.0.tar.gz  

Once published to the Forge, your module will be made available for public download. Continue? (y/N) yes  
pdk (INFO): Authenticating to the Forge API using key with namespace: puppetlabs  
Publish successful, new release available at https://forge.puppet.com/v3/releases/puppetlabs-mysql-0.1.0  
```

#### Attempting to publish a release that already exists on the Forge, bypassing confirmation with `--force`
```
$ pdk publish --force  
pdk (INFO): Attempting to publish puppetlabs-mysql-0.1.0.tar.gz  
pdk (INFO): Authenticating to the Forge API using key with namespace: puppetlabs  
Error: 409 Conflict, a release version 0.1.0 for module puppetlabs-mysql already exists on the Forge. To create a new version of your module to publish, update the version number in metadata.json and run `pdk build`.
```

#### Prompt for API key with pathed tarball
```
$ pdk publish ../dist/puppetlabs-mysql-9.1.1.tar.gz
pdk (INFO): Attempting to publish puppetlabs-mysql-0.1.1.tar.gz  

Once published to the Forge, your module will be made available for public download. Continue? (y/N) yes
No API key was found for namespace: puppetlabs in PDK user config or as an environment variable. If you have an API key you'd like to use, enter it now:
--> **************  

pdk (INFO): Authenticating to the Forge API using key with namespace: puppetlabs  
Publish successful, new release available at https://forge.puppet.com/v3/releases/puppetlabs-mysql-0.1.1 
```

## Future Considerations

- In addition to release publishing, the recent Forge API additions include endpoints for release and module deletion, and module deprecation. We may eventually want to provide PDK users access to any or all of these actions through some combination of subcommands and options.

## Drawbacks

- If we choose to move forward with RFC-0003 or similar implementation at a later date, we may add to a user’s cognitive overhead in changing publish commands, and more generally, in switching from `pdk <verb>` to `pdk <noun> <verb>`. This is a drawback that would not be limited to this particular subcommand though.

## Alternatives

- As noted above, the proposed implementation supersedes RFC-0003. An alternative would be to move forward with the proposal in RFC-0003, which includes a publish action for the proposed `pdk release` subcommand.
