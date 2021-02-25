# Add `--puppet-dev` flag to validate and test unit

## Summary

Introduces a new flag to the `validate` and `test unit` commands that provides a user, with public internet access, to validate and test against the latest puppet source code on GitHub.

## Background & Assumptions

Since the release of v1.5.0, PDK has been able to validate and test against various versions of the Puppet gem via the `--puppet-version` and `--pe-version` flags, however users anticipating upcoming Puppet releases may want to test and validate their modules against the unreleased [Puppet source](https://github.com/puppetlabs/puppet). This feature is geared towards giving module developers or consumers a head start on preparing their modules or installations for the new version of Puppet before it releases.

## Motivation & Goals

- Allow PDK Users to update their modules in preparation for upcoming releases of Puppet.
- Minimizes the risk of upgrading established Puppet installations to new versions of Puppet.
- Promotes more updated modules on the Forge immediately upon each Puppet version release.

## Proposed Implementation Design

Implement a new flag, `--puppet-dev`, to the `pdk test unit` and `pdk validate` subcommands. This flag will only be available to users with access to public internet and is able to access [GitHub](https://github.com). PDK installations in air-gapped or firewalled networks attempting to use this flag will result in a connectivity error, resulting in a non-zero exit code. To get this behavior with environment variables, you can also set `PDK_PUPPET_DEV=true` instead of calling validate and unit test commands with the `--puppet-dev` flag. PDK will result in an error if `PDK_PUPPET_DEV` is set to true in combination with `PDK_PUPPET_VERSION` or `PDK_PE_VERSION` variables being set as well.

- `pdk validate --puppet-dev`

  Validates metadata and puppet code against the Puppet source on the `main` branch on GitHub.

  If `--puppet-version` or `--pe-version` is specified in addition to `--puppet-dev` this will result in an invalid options error, and return a non-zero exit code.

  The `--puppet-dev` flag will automatically result in running the validation using the latest version of Ruby packaged with PDK.

- `pdk test unit --puppet-dev`

  Runs unit tests against the Puppet source on the `main` branch on GitHub.

  If `--puppet-version` or `--pe-version` is specified in addition to `--puppet-dev` this will result in an invalid options error, and return a non-zero exit code.

  The `--puppet-dev` flag will automatically result in running the validation using the latest version of Ruby packaged with PDK.

## Future Considerations

In the future, we may add optional arguments to the `--puppet-dev` flag, which will allow the user to specify which version branch to retrieve from GitHub.

Examples:

- `pdk validate --puppet-dev`

  This will result in the default behavior defined above.

- `pdk validate --puppet-dev=5.5.x`

  This will reset the cloned Puppet repo to the `5.5.x` branch, and run validation against that.

  PDK will match the major and minor version from this branch with the built-in versions map and decide which Ruby to use to run validation or tests against, branches that fail matching will default to the latest Ruby packaged with PDK. E.g. `5.5.x` will run against Ruby 2.4.4 and `4.10.x` will run against Ruby 2.1.9. 

- `pdk validate --puppet-dev=5`

  The option will require an explicit branch name. Unmatched branches will result in an error and a non-zero exit code.

## Drawbacks

A drawback with this new feature is the requirement for public network access. Air-gapped users will be unable to use this feature. However, this feature should not change or impact the behavior of the basic validation and test unit functions previously defined.

## Alternatives

Alternatives discussed include potentially using packaged puppet-agent nightly builds, either installing them or requiring the user to install them so that PDK can access the puppet commands. We decided this option was more complicated to develop, in addition to potentially more complicated for the user.
