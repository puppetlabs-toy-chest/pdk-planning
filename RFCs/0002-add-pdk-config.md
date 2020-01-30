# Add `pdk config` subcommand

## Summary

Introduce a PDK and project configuration subsystem with a new `pdk config` subcommand providing the user interface
to read and write configuration keys and values.

## Background & Assumptions

Prior to the introduction of the Puppet Development Kit, module development involved the coordination of a set of
distinct tools, rake tasks, etc. which each carried their own implicit and explicit mechanisms for customization and
configuration.

While the PDK has made a lot of strides in providing a unified invocation interface for these tools, thus far we have
not addressed configuration side of the way module developers interact with these tools.

To illustrate this, here is a survey of the current file-based configuration landscape for a single module:

  - metadata.json
  - .sync.yml
  - .fixtures.yml
  - .nodeset.yml
  - .pdkignore
  - .puppet-lint.rc
  - .rspec
  - .rubocop[\_todo].yml
  - .yardopts
  - Rakefile

(Plus the inherent configuration and customization contained within the puppetlabs\_spec\_helper gem and it’s provided
rake tasks, some of which the PDK invokes.)

## Motivation & Goals

- Standardize the way existing module development workflows are configured and customized for PDK users.

- Reduce the number of different ways that module development workflows with PDK are configured and customized.

- Resolve some inconsistencies and design challenges presented by existing PDK features. (See template-url/template-ref
  design discussion and some issues we have had with invalid values cached in answers.json)

- Improve the discoverability of module development configuration and customization. **Currently many of the avenues for
  configuration are based around hidden files and their significance is not obvious to someone who is new to module
  development.**

## Proposed Implementation Design

Implement a new pdk subcommand, `pdk <get|set|remove> config` which will offer the following actions:

Ref: (Verb-Noun Reference)[https://docs.google.com/document/d/1zX0FJBAvAIK3d3L3QemD2FGQo3EsgMOD0Ha1BYHVYJE]

  - `pdk get config [--format=<format>]`

    Lists the complete, currently resolved configuration, merging all available layers of config and presenting the
    formatted results.

    If run from within a project, will show system, user and project level config.

    If run outside of a project, will only show system and user level config with an indication to the user that the command was not invoked from within a project.


  - `pdk get config <key> [--format=<format>]`

    Retrieves a specific value from the resolved configuration.

    If `<key>` is a leaf node of the configuration graph, this command will return the raw value:

    ```
    $ pdk get config user.default_template.url
    https://github.com/puppetlabs/pdk-templates.git
    ```

    If `<key>` is a non-leaf node of the configuration graph, this command will return a structure containing the values
    of all sub-keys of the given key:

    ```
    $ pdk get config user.default_template
    user.default_template.url = https://github.com/puppetlabs/pdk-templates.git
    user.default_template.ref = master
    ```

    You can also supply the `--format` option to control how keys and values are presented:

    ```
    $ pdk get config user.default_template.url --format=json
    { "user.default_template.url": "https://github.com/.../pdk-templates.git" }
    ```

    ```
    $ pdk get config user.default_template --format=json
    { "user.default_template.url": "https://github.com/.../pdk-templates.git", "user.default_template.ref": "master" }
    ```

  - `pdk set config [--add] <key> <value>`

    Sets, updates, or adds to the value(s) in the given configuration key and outputs the new value(s).

    If `<key>` is not a leaf node, exits non-zero with an error message.

    If `<key>` already has a value set, issues a notice before replacing existing value.

    If `<key>` is designed to store multiple values (e.g. a list):

      - If the current value list is empty, set the first value in the list to the provided `<value>`.

      - If the current value list is not empty and `<value>` is not already present in the list, add `<value>` to the
        list.

      - If `<value>` is already present in the value list, issues a notice that value was already on list, outputs the
        current values of `<key>`, and exits with a success status.

    If `<key>` is a user-defined configuration key where we cannot infer whether or not it can have multiple values,
    assume it is a single-value key unless the user includes the `--add` flag. If the user includes the `--add` flag,
    treat it as a multi-value key as described above.

    Basic usage examples:

    - Known single value key, initial value:

      ```
      $ pdk set config user.default_template.url "https://github.com/scotje/pdk-templates.git"
      pdk (INFO): Set initial value of user.default_template.url to "..."
      https://github.com/scotje/pdk-templates.git
      ```

    - Known single value key, update value:

      ```
      $ pdk set config user.default_template.url "https://github.com/example/repo.git"
      pdk (INFO): Changed existing value of user.default_template.url from "..." to "..."
      https://github.com/example/repo.git
      ```

    - Known multi-value key, initial value:

      ```
      $ pdk set config module.multi.example apple
      pdk (INFO): Added new value "apple" to module.multi.example
      apple
      ```

    - Known multi-value key, additional value:

      ```
      $ pdk set config module.multi.example banana
      pdk (INFO): Added new value "banana" to module.multi.example
      apple
      banana
      ```

    - Known multi-value key, duplicate value:

      ```
      $ pdk set config module.multi.example apple
      pdk (INFO): No changes made to module.multi.example as it already contains value "apple"
      apple
      banana
      ```

    - User-defined key, initial value:

      ```
      $ pdk set config module.x.example strawberry
      pdk (INFO): Set initial value of modle.x.example to "strawberry"
      strawberry
      ```

    - User-defined key, append value:

      ```
      $ pdk set config --add module.x.example orange
      pdk (INFO): Added new value "orange" to module.x.example
      strawberry
      orange
      ```

  - `pdk remove config <key> [<value>|--all]`

    Unset one more more values from the given configuration key.

    If `<key>` is not a leaf node, exits non-zero with an error message.

    If `<key>` currently stores no value, issues a warning but exits with a success status.

    If `<key>` currently stores a single value:

      - If no `<value>` is provided, unsets existing value.

      - If provided `<value>` matches existing value, unsets existing value.

      - If provided `<value>` does not match existing value, exits non-zero with an error message.

      - If passed `--all` in place of a value, unsets existing value.

    If `<key>` currently stores multiple values:

      - If no `<value>` is provided, exit non-zero with an error message indicating user must pass `--all` if they want
        to clear all values for the key.

      - If provided `<value>` is present in the list of values for `<key>`, removes value from list.

      - If provided `<value>` is not present in the list of values for `<key>`, issues a warning but exits with a
        success status.

      - If passed `--all` in place of a value, empties the list of all existing values.

### Proposed Configuration Keys

#### System Config

The values for these config keys will be persisted in `/opt/puppetlabs/pdk/config` (`%ProgramData%\PuppetLabs\PDK` on Windows).
They are intended to be system-specific settings and will apply to all developer working on the same computer.

These would typically be system level defaults of the same User/Local Config settings defined below. For example:

In the RGBank company, they have their own PDK template store.
To make it easier for onboarding new developers this is stored in the `system.module_defaults.template.url` key.
Developers can choose to override this, by setting `user.module_defaults.template.url`

Setting precedence is discussed in more detail below.

#### User/Local Config

The values for these config keys will be persisted in ~/.pdk/config (`%LOCALAPPDATA%\PDK\config` on Windows).
They are intended to be developer-specific settings and will not apply to another developer working on the same codebase.

| Key | Description |
| --- | --- |
| user.module\_defaults.template.url | Default template URL to use when generating a new module. |
| user.module\_defaults.template.ref | Default template ref to use when generating a new module. (E.g. branch or tag.) |
| user.module\_defaults.metadata.author | Default value for the “author” key in metadata.json for a new module. Supersedes previous ~/.pdk/cache/answers.json functionality. |
| user.module\_defaults.metadata.license | Default value for the “license” key in metadata.json for a new module. Supersedes previous ~/.pdk/cache/answers.json functionality. |
| user.forge.username | Primary Forge username of this developer. Note that this may be an organization rather than a personal username. Used as the default value in metadata.json when generating a new module. Supersedes previous ~/.pdk/cache/answers.json functionality. |
| [user.forge.api\_key] | Placeholder for future Forge API interactions. |
| [user.forge.api\_secret] | Placeholder for future Forge API interactions. |

#### Project-specific Config

The values for these config keys will be persisted in a new .pdk/config file within the project.
Currently a project is only a Puppet Module but in the future this may extend to Control Repos or Bolt projects.
The new file is intended to be checked into VCS and shared with other developers to ensure consistent application of the relevant PDK commands.

For example, in a Module Project:

| Key | Description |
| --- | --- |
| project.template.url | Template URL to use for this module. |
| project.template.ref | Template ref to use for this module. Note that this will differ from what is currently stored in metadata.json, this value will be the “desired” reference (e.g. a branch name) but not the specific commit that the module was last updated to. |
| project.template.custom.[...] | Filename based keys with associated config hashes to govern how the template should be applied to this specific module. Supersedes existing .sync.yml settings. |
| project.test.fixtures.[...] | List of additional modules, etc. and associated config hashes needed in order to run unit tests for this module. Supersedes existing .fixtures.yml settings. |
| project.x.[...] | Arbitrary keys and values to be utilized by users to persist data between module developers. Can be used as a basic shared data store for custom developer Rake tasks, etc. |

### More About `project.x`

The `project.x` configuration key space is intended to be used by project developers and third-party tool developers to
persist configuration data that is relevant to all developers of a project. Ultimately we want to avoid any need for
users to add additional configuration files to their projects beyond what `pdk config` uses.

We will define and document best practices around the usage of the `project.x` key space for the community, including
things like:

 - Namespace your custom configuration settings under a key that matches the name of your organization or tool name,
   e.g. `project.x.mycompany`, `project.x.voxpupuli`, or `project.x.super_module_tool`.

 - If your custom configuration is tool-specific, include a key and value that you can use to version your other
   configuration data. That way you can significantly change the configuration format for your tool in the future
   without breaking older versions. E.g. `project.x.super_module_tool.config_version = 1`

 - Plus any other best practices we come up with.

### Setting Precedence

The settings will typically be enforced using the following order:

1. Project
2. User/Local
3. System

Project settings have the highest precedence whereas System settings have the lowest.
That is, if a setting is defined in both Project and System levels, only the Project level will take affect.

Note that **typically** only the User and System settings will overlap.
It is expected that there will be few, if at all, settings that makes sense in the Project and User levels

## Unresolved Questions

- Should we assign expected types to the pre-defined configuration keys so that we can validate new values and report
  errors if the value cannot be coerced to the expected type?

  - _This seems like it will help avoid a lot of pain on the consumer-side of the `pdk config` API and we already have
    the bits in place to validate using JSON-Schema so I recommend we implement types and type validation/coericion for
    all the non-arbitrary keys and values._

## Future Considerations

- We should ensure that the key/value structure we set up is sufficiently extensible for future PDK functionality such
  as control-repo administration, etc.

## Drawbacks

- There is a lot of existing documentation and accumulated tribal knowledge in the community around how to configure
  module development through things like `.sync.yml`.

  - Some of the issues here can be mitigated by integrating automatic migration of relevant configuration from files
    like `.sync.yml`, `.fixtures.yml`, etc. into `pdk config` equivalents.

- Existing tooling like `pdksync`, etc. will have to be updated to use the `pdk config` subsystem. This includes any
  tools that PDK uses internally.


## Alternatives

- Maintain status quo, with improved documentation and education about what can be configured, which files to update,
  etc.

- Create a similar `pdk config` subcommand but have a translation layer that actually persists configuration in the
  existing files, rather than in new files.
