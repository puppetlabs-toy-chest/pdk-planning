DRAFT ONLY

# PDK Templating Version 2.0

## Summary

> One paragraph explanation of the feature.

The PDK templating engine originally started from [modulesync](https://github.com/voxpupuli/modulesync) which had a fairly simple use case: To generate the configuration files for the Puppet Labs supported modules.
However since then the PDK use case has greatly expanded in scope. Catering for many CI services, creating files on convert, as well, as keeping files up to date.

The templating system needs to be reviewed, and the architecture changed to support the ever growing need for end user scenarios.

## Background & Assumptions

> What is the context that someone needs to understand the goals of this proposal? This information should be objective
> facts (i.e. not subjective opinions) about the current state of things.

Evidence that the current templating system is in need of attention

* The number of combinations of settings is continually growing. This is evident in the number of commits, and the growth of the pdk-templates repository

* The complexity of managing the templates is becoming difficult. For example [Jira PDK-1463](https://tickets.puppetlabs.com/browse/PDK-1463?focusedCommentId=680851&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-680851)

* The number of outstanding issues indicates either there are many errors (probably not the case), or that fixing things is difficult (which is more likely)

* [Github Issue 220](https://github.com/puppetlabs/pdk-templates/issues/220) shows that the pdk-templates lack sufficient documentation and testing practices to make it easier for the community to contribute changes, or to have their own template repository.

## Motivation & Goals

### Objectives

**Template Users**

* Template users should be able to compose their required environment from the provided templates instead of opting out of a "kitchen sink" template.

* Template users should be able to see information about all of the available templates available and their settings.

* Template users should be able to verify that their custom template settings are sane and valid

* Template users should be to easily test that their custom template settings work as they expect.

**Template Authors**

* Template authors should be able to easily add/modify templates with clear and documented standards e.g. file locations and good practices

* Template authors should be able to easily generate document from their templates instead of manually keeping the code and documentation in sync.

* Template authors should be able to easily test their templates work as expected, both manually and via automation, like rspec.

* Template authors should be able to advertise what their templates do

* Template authors should be able to use ERB for simple templates, but also put more advanced code into Ruby

### Backwards compatibility

The proposed changes must either be backwards compatible, or be segregated so that Template Users can progressively opt in to version 2.0

## Proposed Implementation Design

### Opt-in instead of opt-out

Currently the templating will apply everything, and Template Users must opt-out.  The new templating system will use a composition model, that is, Template User must opt-in to things.

### Easier to discover, and validate, template settings

Currently Template User need to read the README to determine what settings are available or even valid. This also assumes the README is even correct.  The new templating system will have a metadata, and optionally, a validation layer so that users can discover what templates are available to opt-in to, and optionally, to validate template settings.

### Easier to manage template file locations

The new templating design will have descriptive and well documented file locations


**V1 locations**

| Path                      | Description |
| ------------------------- | ----------- |
| `/moduleroot`             | Templates get deployed on new module, convert and update |
| `/moduleroot_init`        | Templates get only deployed when the target module does not yet exist |
| `/object_templates/*.erb` | Template location for `pdk new ...` generation |
| `/robocop`                | Custom ruby code to assist in generating rubocop profiles |

**V2 locations**

Where `name` is a unique name for the template

> The `name` should use snake case (lowercase with underscore) to be cross platform compliant. The more descriptive name can be specified in the template.yml file

| Path                               | Description |
| ---------------------------------- | ----------- |
| `/<name>/README.md`            (1) | A plain text description of the template. Though not really necessary as most of this would be contained in the `template.yml` file. It is expected that this file will be auto-generated |
| `/<name>/template.yml`             | YAML file describing the template |
| `/<name>/template_schema.json` (1) | JSON Schema file describing the valid settings for this template |
| `/<name>/files/**/*`               | Templates to process for new module, convert and update |
| `/<name>/files_init/**/*`      (1) | Templates to process when the module does not yet exist |
| `/<name>/*`                  (1,2) | Additional files used _for_ templating, for example configuration information |

(1) Optional

(2) Ruby files that will be evaluated for the ERB templating process **must** be specified in the `template.yml` file. This is to help (somewhat) safeguard arbitrary Ruby being evaluated. Although it can be argued that ERB templates are also arbitrary code.

> TODO: Does files_init EVEN make sense?!??!
> Actually it does it in an `always_apply` template

> TODO: What about object_templates?

Note - `/object_templates/*.erb` will still be consumed by the V2 Templating Engine.

> TODO: What about `/rubocop/` ?

### `<name>/template.yml`

| YAML Element | Description |
| ------------ | ----------- |
| name (required) | A short descriptive name of the template |
| description | A long (even multiline) description of the template. Default is the name of the template |
| type | What type of item this is a template for. Currently only `module` is supported, but in time `control_repo` and others may be added. Default is `module` |
| evaluate_ruby_files | An array of files to [evaluate](https://ruby-doc.org/core-2.6.4/Kernel.html#method-i-eval) prior to rendering ERB templates. This is used to inject complex logic into the templating system without the troubles of having complex logic in ERB.  For example complex branching based on settings. Default is empty array |
| default_settings | A YAML hash of the default settings for the template. Default is empty hash |
| always_apply | Always apply this template. If not specified in the template list, it will be applied last. Default is `false` |
| tags | An array of string tags for this template. Always includes the directory name of the module. Default is an empty array |

### `<name>/template_schema.json`

### Example templates

#### A template for a default module file

The `.pdkignore` file will be used in all PDK compatible modules therefore it should always be applied.

File layout

``` text
pdkignore/
  +- template.yml
  +- template_schema.json
  +- files/
       +- .pdkignore.erb
```


`template.yml`

``` yaml
---
name: "PDK Ignore"
description: >-
  The PDK Ignore template manages the .pdkignore file for Puppet Modules
type: module
always_apply: true
tags: ignore default
default_settings:
  required:
    - '/appveyor.yml'
    - '/.fixtures.yml'
    - '/Gemfile'
    - '/.gitattributes'
    - '/.gitignore'
    - '/.gitlab-ci.yml'
    - '/.pdkignore'
    - '/Rakefile'
    - '/rakelib/'
    - '/.rspec'
    - '/.rubocop.yml'
    - '/.travis.yml'
    - '/.yardopts'
    - '/spec/'
    - '/.vscode/'
    # ... many other paths
  paths: ~
```

`template_schema.json`

``` json
{
  "$schema": "http://json-schema.org/draft-06/schema#",
  "$id": "http://puppet.com/schema/does_not_exist.json",
  "type": "object",
  "title": "The PDK Ignore Template Schema",
  "properties": {
    "paths": {
      "$id": "#/properties/paths",
      "title": "Paths property",
      "description": "Array of file paths to also ignore by the PDK, for example, when building a module",
      "type": "array",
      "items": {
        "type": "string"
      },
    },
  },
  "definitions": {}
}
```

**Note** that the `required` setting is not documented, or has a schema, as it's internal to the template.

`.pdkignore.erb`

Same as [V1 template](https://github.com/puppetlabs/pdk-templates/blob/90e5efab878facd18f838755d9e95b226b1e0776/moduleroot/.pdkignore.erb).

#### An opt-in template for CI configuration

> TODO

#### A template only for new object


### Changes to `.sync.yml`

Each module may contain a `.sync.yml` file which contains the module specific settings when rendering the templates. For the new templates, the .sync.yml will have additional settings, which will also be backwards compatible with the V1 templating engine.

* Root `pdk_template` element

  The new `pdk_template` element will hold all of the data for templating engine. Due to being backwards compatible the verbose name of `pdk_template` is used instead of the generic name `template`, so that it would probably not conflict with any known files.  For example, Puppet modules have a `templates` directory.

  * `version` element (Integer)

  Which version of the templating engine this module uses. If this is missing (or the root `pdk_template` element is missing) it is assumed this is Version 1 template. If the template specifies a version that the templating engine does not support it is expected the engine will raise a terminating error.

  Note that the type here is an integer. Although we could use a semver (Semantic Versioning) based string here, that would make parsing difficult.

  * `templates` element (Array of string). List of templates (The template directory name) to be applied **IN ORDER** (Order is important.  See [Resolution Order](#resolution_order))

Example V1 `.sync.yml`

``` yaml
---
Gemfile:
  # Gemfile template customisations

.rubocop.yml:
  # Rubocop template customisations

# ... etc
```

Example `.sync.yml` with V2 settings

``` yaml
---
pdk_template:
  version: 2
  templates:
    - appveyor_ci
    - travis_ci
    - rubocop
    - litmus_tests

Gemfile:
  # Gemfile template customisations

.rubocop.yml:
  # Rubocop template customisations

# ... etc
```

### Resolution order

> TODO: What happens with conflicting settings files.  Order is important, first one wins.
> For `always_apply` modules they are last, but in alphabetical order (Needs some kind of deterministic order)

## Unresolved Questions

> TODO:
> Having discrete settings may cause duplicate code because you can't share across templates.  But that's better
> spaghetti dependencies and difficult to diagnose. (DRY isn't always best)

## Future Considerations

> TODO:
> Rake tasks to auto generate documentation
> PDK Templating Engine as a separate gem that other projects can consume (Not just PDK)
>
> * Bolt tasks/plans
> * Control Repos
> * Websites that can autogen template files on demand
> * GUI based selection and Text based "Wizards" to compose modules
> * Reference templates in other locations (e.g. by uri)

## Drawbacks

> TODO: Probably none but I'm sure there's some?

## Alternatives

**What is the impact of doing nothing?**

Development and adoption of PDK Templating slows or forks in different directions entirely

**Could this be done better with other templating engines?**

e.g. Go, .Net Core.

There are plenty of other templating engine out there, that are faster than Ruby. Ruby has an advantage as the PDK is written in that language.
