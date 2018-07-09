# Add `pdk release` Subcommand

## Summary

Add a new `pdk release` subcommand with multiple actions to allow us to separate release preparation and release
packaging.

## Background & Assumptions

- It is sub-optimal that the current implementation of the `pdk build` subcommand can have side-effects on the module's
  code before it is packaged.  For example, if the module’s metadata needs to be modified to make the module Forge
  compatible, the contents of the tarball produced by `pdk build` may no longer match what the developer has committed
  (and possibly tagged) in their version control system.

- This issue will only get worse if we add more “preflight” style tasks into the existing `pdk build` (e.g. changelog
  generation, version bump checking, etc.)

## Motivation & Goals

- PDK should provide an easy way for module authors to package and distribute their modules via the Puppet Forge.

- PDK should provide composable commands and actions so that module authors can automate the packaging and distribution
  of their modules, and integrate those steps into a comprehensive CI/CD pipeline.

- PDK should encourage module authors to adopt good development and release practices, such as ensuring that distributed
  release artifacts are consistent with tagged content in their version control system.

- PDK subcommands should be reasonably extensible without any single command or action being overloaded with multiple,
  distinct functions.

## Proposed Implementation Design

Implement a new pdk subcommand, `pdk release` which will offer the following actions.

- `pdk release prep`

  - Performs all the pre-release checks to ensure module is ready to be packaged, prompts user for missing info,
    modifies files on disk as needed, etc.

  - User is directed to review changes and commit the new state of the module’s code to their version control system.
    (The exact contents of this prompt can be predicated on whether or not there is VCS metadata present in the module’s
    working directory.)

  - Ideally the user would be able to customize the pre-release checks that were performed, including defining their own
    custom checks. This customization could be implemented through the [proposed `pdk config`
    subcommand](https://github.com/puppetlabs/pdk-planning/pull/4).

  - When run non-interactively (e.g. as part of a continuous delivery pipeline), it will exit non-zero if it would
    require any user input to complete successfully.

- `pdk release build [--target-dir=<value>]`

  - Replicates the existing `pdk build` functionality with the modification that it will fail and exit non-zero if any
    of the checks performed by `pdk release prep` would result in modification to the module’s code.

  - If there is VCS metadata present in the module, this action could also fail and exit non-zero if there are changes
    to the module’s code that have not been committed to VCS.

  - If there is VCS metadata present in the module, this action could also automatically add a tag to the VCS repository
    based on the module’s version string, or direct the user to do so.

  - This command has no interactive elements, it either succeeds or fails.

- `pdk release push [tarball] [--force]`

  - _All functionality of this action is pending availability of proper Forge publish API._

  - Publishes the given module tarball to the Forge.

  - When not passed a path to a tarball, looks in `metadata.json` for the current version and then looks for a tarball
    in the default build path matching that version and pushes it to Forge. Exits non-zero if it can’t find a tarball
    matching the current metadata.json version.

  - Defaults to asking for confirmation when run interactively, but can be disabled with the `--force` flag. Note that a
    push will still fail, regardless of the `--force` flag, if a release of the module with the same version already
    exists on the Forge.

  - When run non-interactively (e.g. as part of a continuous delivery pipeline), it will default to not asking for
    confirmation (`--force` behavior) and exit non-zero if it would require any user input to complete successfully.

## Unresolved Questions

- It seems like we may need to change PDK's user interface from a `pdk <verb>` pattern to a `pdk <noun> <verb>` pattern
  in the near future, so maybe this command should wait until it can be introduced as `pdk module release`?

- Should `pdk release prep` perhaps be called `pdk release check` instead?

## Future Considerations

Once the Forge API prerequisites for `pdk release push` are completed, we could also add:

- `pdk release delete <version|--all> [--force] <deletion_reason>`

  - When given a single module release version, marks that version as “deleted” on the Forge.

  - When invoked with the `--all` flag, marks all released versions of the current module as “deleted” on the Forge.

  - Deletion reason is a required argument.

  - Defaults to asking for confirmation when run interactively, but confirmation prompt can be skipped with the
    `--force` flag.

  - When run non-interactively (e.g. as part of a continuous delivery pipeline), it will default to not asking for
    confirmation (`--force` behavior) and exit non-zero if it would require any user input to complete successfully.

However this functionality might also make more sense in a new, non-module specific PDK subcommand that includes other
Forge-specific actions.

## Drawbacks

- We just recently introduced the `pdk build` subcommand so it's not ideal to already be deprecating it.

- This is introducing additional steps and more cognitive complexity to the release process for a module.

## Alternatives

- Status quo, however there will be continued tension around adding any new behaviors to `pdk build`. Also `pdk build`
  is a module-specific command and may be confusing when we add control-repo functions to PDK.
