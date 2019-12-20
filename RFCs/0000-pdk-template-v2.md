DRAFT ONLY

# PDK Templating Version 2.0

## Summary

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

* Template users should be able to easily display the _intended_ output of their template settings

  * Template users should be able to easily output the _intended_ output of their template settings, to facilitate testing (manual or automated)

**Template Authors**

* Template authors should be able to easily add/modify templates with clear and documented standards e.g. file locations and good practices

* Template authors should be able to easily generate documentation from their templates, instead of manually keeping the code and documentation in sync.

* Template authors should be able to easily test their templates work as expected, both manually and via automation, like rspec.

* Template authors should be able to use ERB for simple templates, but also put more advanced code into Ruby

### Backwards compatibility

The proposed changes must either be backwards compatible, or be segregated so that Template Users can progressively opt in to version 2.0

* Ideally, the proposed implementation would make a one-time conversion process available.
* Ideally, this conversion process would happen as part of the `pdk convert` or `pdk update` process automatically

## Out-Of-Scope Items

Note - This is just a list collating all out-of-scope items. A full description as to why it is out of scope can be found later in this RFC

* `/object_templates/*.erb` files will still be consumed by the V2 Templating Engine, and is currently outside the scope of this particular RFC.

* Renaming `.sync.yml`.

* Template repositories that are not on the Filesystem or on Github




## Proposed User Experience

### User Experience as a Template User

**Opt-in instead of opt-out**

Currently the templating will apply everything, and Template Users must opt-out.  The new templating system will use a composition model, that is, a Template User must opt-in to things.

**Easier to discover, and validate, template settings**

Currently a Template User needs to read the README _and_ the templates (and even the code itself!) to determine what settings are available or even valid. This also assumes the README is even correct.  The new templating system will have a metadata layer so that users can discover what templates are available to opt-in to. Optionally each template would have a validation layer, to validate template settings.

**Example Future PDK Commands**

To help with the discovery, the Template Engine should have an API to query template information, which can then be consumed by clients.  This would mean the PDK could in the future have commands like:

Note that these are examples only, and are out scope for this RFC.  Later RFCs will discuss the PDK integration and UX when querying the Template Engine.

```
> pdk list templates
appveyor_ci
travis_ci (already in use)
rubocop
litmus_tests (already in use)


> pdk show template rubocop

rubocop template
----------------

Description: Lorem ipsum

Settings:
* selected_profile
  Description: Lorem ipsum
  Values: cleanups_only, strict, hardcore, off

* include_todos
  Description: Lorem ipsum
  Values: true, false


> pdk add template_source filesystem location=/something/somewhere

Added template source. Template sources are now:

  template_sources:
    -
      type: filesystem
      location: "/something/somewhere"
    - default
```


#### Configuring settings for the Template Engine

A Template User will continue to have a `.sync.yml` file in the root of their project which contains all of the per-project settings required for the template engine

Example `.sync.yml` with V2 settings

``` yaml
---
pdk_template:
  version: 2
  template_sources:
    -
      type: git
      location: 'https://github.com/user/custom-templates.git'
    - default
  templates:
    - appveyor_ci
    - travis_ci
    - rubocop
    - litmus_tests

gemfile:
  # Gemfile template customisations

rubocop:
  # Rubocop template customisations

# and so on ...
```

#### Multiple template sources

A Template User will be able to specify more than one template source. See [sync.yml reference](#Changes_to_.sync.yml) for more information

### User Experience as a Template Author







## Proposed Implementation Reference

### Changes to `.sync.yml`

Renaming `.sync.yml` is considered out of scope for this RFC.  There is a large body of work already using this file to store per-project settings and renaming it would really be an RFC in of itself.

Each project may contain a `.sync.yml` file which contains the project specific settings when rendering the templates. For the new templates, the .sync.yml will have additional settings, which will also be backwards compatible with the V1 templating engine.

``` yaml
---
pdk_template:
  version: 2
  template_sources:
    -
      type: git
      location: 'https://github.com/user/custom-templates.git'
    - default
  templates:
    - appveyor_ci
    - travis_ci
    - rubocop
    - litmus_tests

gemfile:
  # Gemfile template customisations

rubocop:
  # Rubocop template customisations

# and so on ...
```

* Root `pdk_template` element

  The new `pdk_template` element will hold all of the data for templating engine. Due to being backwards compatible the verbose name of `pdk_template` is used instead of the generic name `template`, so that it would probably not conflict with any known files.  For example, Puppet modules have a `templates` directory.

  * `version` element (Integer) (**Required**)

  Which version of the templating engine this module uses. If the template specifies a version that the templating engine does not support it is expected the engine will raise a terminating error.

  Note that the type here is an integer. Although we could use a semver (Semantic Versioning) based string here, that would make parsing difficult.

* `template_sources` element (Array of String)

  A list of places to find Template Repositories. Order is important. If the same template (specifically the same template directory name) is specified in two sources, then the top-most source will be used ("First one wins")

  Support source types:
  * Filesystem based repository

    A directory on disk can be specified as a Template Repository.

  * Git based repository

    A git repository (For example Github, GitLab or in internal git repo)

  * `default`

    This special source type will use whatever the Template Engine considers the default.  In the case of the PDK, this would be the cached `pdk-templates` repo that is packaged as part of the PDK. Other tools using the Template Engine may specify a different location.

  If no template sources are specified `default` is used.

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
  template_sources:
    -
      type: git
      location: 'https://github.com/user/custom-templates.git'
    - default
  templates:
    - appveyor_ci
    - travis_ci
    - rubocop
    - litmus_tests

gemfile:
  # Gemfile template customisations

rubocop:
  # Rubocop template customisations

# ... etc
```

A Template User will be able to use one or more template sources

#### Using a default template source

``` yaml
---
pdk_template:
  template_sources:
    - default
```

Uses the default location as determined by the Template Engine. For example the PDK would use it's packaged template location for packaged PDK distributions, but use the Git based one for gem based PDK distributions

#### Using a git based template source

``` yaml
---
pdk_template:
  template_sources:
    -
      type: git
      location: 'https://github.com/user/custom-templates.git'
      ref: master
```

| YAML Element | Description |
| ------------ | ----------- |
| type         | Must be `git` |
| location     | The git remote to clone |
| ref          | (Optional) The git reference to checkout. Default is what the git remote deems the default branch |

#### Using a filesystem based template sources

Example:

``` yaml
---
pdk_template:
  template_sources:
    -
      type: filesystem
      location: 'C:/templates/custom'
    #  Unix style path
    # -
    #   type: filesystem
    #   location: '/templates/custom'
```

| YAML Element | Description |
| ------------ | ----------- |
| type         | Must be `filesystem` |
| location     | Absolute path to the template source |








<!-- ############################################################################################# -->











## Proposed Implementation Design



### File locations

* A template repository (called a Templates Repo for the rest of this RFC) will contain one or more templates

  * For this version of the RFC, only filesystem and Github based repositories will be supported. It is fully expected that after this RFC is implemented, additional repository types would be added (e.g. Gitlab).  Therefore any implementation should be modular in design.

* Each template within a Templates Repo will be self-contained.

* The files for both V1 and V2 templates will be segrgated therefore they can both exist in the same Templates Repo.

#### V1 locations

| Path                      | Description |
| ------------------------- | ----------- |
| `/moduleroot`             | Templates get deployed on new module, convert and update |
| `/moduleroot_init`        | Templates get only deployed when the target module does not yet exist |
| `/object_templates/*.erb` | Template location for `pdk new ...` generation |
| `/robocop`                | Custom ruby code to assist in generating rubocop profiles |

#### V2 locations

Where `name` is a unique name for the template

> The `name` will use snake case (lowercase with underscore) to be cross platform compliant. The more descriptive name can be specified in the template.json file

> The `name` _should_ not match any V1 template directories in order  to keep the segregation, however this is not a hard requirement.  A Templates Repo can simply not support V1 templates.

| Path                               | Description |
| ---------------------------------- | ----------- |
| `/<name>/README.md`            (1) | A plain text description of the template. Though not really necessary as most of this would be contained in the `template.json` file. It is expected that this file will be auto-generated TODO: Is this even required if it's already in the `template.json`? |
| `/<name>/template.json`            | JSON file describing the template |
| `/<name>/template_schema.json`     | JSON Schema file describing the template settings |
| `/<name>/files/**/*`               | Templates to process for new module, convert and update |
| `/<name>/files_init/**/*`      (1) | Templates to process when the module does not yet exist |
| `/<name>/*`                  (1,2) | Additional files used _for_ templating (as opposed to output as part of the templating process); for example template configuration information |

(1) Optional

(2) See lifecycle hooks for more information

Note - `/object_templates/*.erb` files will still be consumed by the V2 Templating Engine, and is currently outside the scope of this particular RFC.

> TODO: Does files_init EVEN make sense?!??!
> Actually it does it in an `always_apply` template
>
> TODO: What about `/rubocop/` ?

``` text
+------------------------------------------------------------------+
| +------------+  +------------+  +------------+   +-------------+ |
| |            |  |            |  |            |   | V1 Template | |
| | template_1 |  | template_2 |  | template_3 |   |    Files    | |
| |            |  |            |  |            |   |     and     | |
| +------------+  +------------+  +------------+   | Directories | |
|                                                  +-------------+ |
|                      Templates Repository                        |
|                                                                  |
+------------------------------------------------------------------+
```

### Template Settings

Each template will (more than likely) have configuration settings which can change how it renders its files.

#### V1 Templates

V1 templates use only two layers of template settings:

* Per-project setting as defined in the (`<Project>/.sync.yml`)
* Default settings as defined by Templates Repo (`<Templates Repo>/config_defaults.yml`)

Where the per-project settings have the highest priority.

#### V2 Templates

V2 templates will operate in a similar manner except that template default settings will move from a central file in the Templates Repo, to each individual template directrory: For example the `git` settings will live in the git template. So the setting hierarchy will look as follows:

* Per-project setting as defined in the (`<Project>/.sync.yml`)
* Default settings as defined in a Template (`<Templates Repo>/<Template>/template.json`)

Again, where the per-project settings have the highest priority.

However, there is a need for cross-template setting changes. Take for example the case of Litmus and Gemfiles: The Litmus template needs to add the `litmus` gem to a project's `Gemfile`.

So the setting hierarchy becomes:

* (Highest Priority) Per-project setting as defined in the (`<Project>/.sync.yml`)
* Settings from other templates (????)
* (Lowest Priority) Default settings as defined in a Template (`<Templates Repo>/<Template>/template.json`)

##### Shared Settings

In fact we can see two main scenarios (which are really just "two sides of the same coin"):

* One template needs to make changes in many other templates. For example;

  The Litmus template needs to modify the
  - Gemfile template (To add gems)
  - Appveyor template (To add a task)
  - Spec_helper_acceptance template (To add all the required boilerplate code)
  - ... and so on

* One template can be influenced by many other templates.  For example;

  The Gemfile template can change its settings based on
  - Does it need the litmus gem?
  - Does it need any puppet-lint plugin gems?
  - Does it need to add the onceover gem?
  - ... and so on

One of the less desirable traits of the V1 templates was that any template could modify the setting in any other template, without any validation or discoverability. Therefore templates should define what settings could be modified by other templates. However this only addresses the validity point, but doesn't help discoverability.

To be discoverable, the dependencies between templates need to be abstracted from each other.  What the examples above are describe are really behaviours, not implementation details. Instead it is proposed that templates use a [Publish-Subscribe](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern) pattern to publish (or advertise) shared settings, and then other templates can subscribe (or consume) these shared settings and then modify their templates appropriately.

Using the example Litmus, Gemfile, Appveyor and Travis templates.

``` text
                   Shared Setting
    Publish     +------------------+                       Subscribe
       +------> | use_litmus: true | +--------+---------------+---------------+
       |        +------------------+          |               |               |
       |                                      v               v               v
+------+-----+                         +------------+  +-------------+  +------------+
|   litmus   |                         |  gemfile   |  | appveyor-ci |  |  travis-ci |
|  template  |                         |  template  |  |  template   |  |  template  |
+------------+                         +------------+  +-------------+  +------------+
```

1) The `litmus` template publishes a shared setting called `use_litmus` (with a value of true)

2) The `gemfile` template subscribes to this setting, and modifies it's internal settings to add the litmus gem to the `Gemfile` file.

3) The `appveyor-ci` template subscribes to this setting, and modifies it's internal settings to add the litmus tasks to the `appveyor.yml` file.

4) The `travis-ci` template subscribes to this setting, and modifies it's internal settings to add the litmus tasks to the `.travis.yml` file.

Note - The name of the setting is used to convey intent, not a particular implementation. In the example above, it conveys the intent that other templates should use litmus. Instead of, say, `add_litmus_gem` which only makes sense for the gemfile template, but not appveyor.

Note - The template will define the type of object the setting can contain. In the example above the object type would be `boolean`. Another example could be: A `puppet-lint` template could publish an `available_puppet-lint_plugins` shared setting with a value of `["puppet-lint-trailing_newline-check", "puppet-lint-roles_and_profiles-check"]`.  This would have an object type of `array[string]`.

Note - Templates would be able to subscribe to more than one setting.  For example the `gemfile` template would subscribe to the `use_litmus` and `available_puppet-lint_plugins` settings and add the required gems to the templated `Gemfile`.

### Template Engine Lifecycle and Template hook files

Most simple templates will only require a setting and an ERB file for rendering however there are cases where more advanced logic is required to be used.  Either because putting that logic _into_ an ERB file results in a horrible mess which is hard to maintain, or it's just not possible to express the logic in ERB. The V2 Template Engine will allow Template Authors to execute Ruby files at various parts of the templating life cycle using hooks.  These files will be located in the template directory and have specific names, reflecting their state in the lifecycle.

#### Template Engine Lifecycle

Note - Where you read "for each template", the resolution order is determined by the per-project settings file (`.sync.yml`).

1) Load default settings for each template.

2) Publish the shared settings for each template, including their default value

3) Parse the per-project settings file and override any template defaults

4) Resolve the shared settings for each template

5) Resolve the list of files to render each template

6) Render the files for each template

#### Available template lifecycle hooks

| Name | Filename | Description |
| ---- | -------- | ------------|
| After default settings loaded | `after_default_settings.rb` | Triggers after the default settings have been loaded. This hook could be used to modify the default settings based on other settings within the template. |
| After shared settings published | `after_shared_settings.rb` | Triggers after the shared settings have been read and published, including their default values. This hook could be used to modify the shared default settings based on other settings within the template |
| After pre-project settings loaded | `after_project_settings.rb` | Triggers after the per-project settings have been read and applied. This hook could be used to modify other template settings based on a projects overrides |
| After the list of files has been resolved | `after_file_resolution.rb` | Triggers after the list of files to render is resolved. This hook could be used to remove files from the list, based on complex rules. |
| Before file render | `before_file_render.rb` | Triggers before a file is rendered. This is last hook that can be used to dynamically change template settings. This hook could be use to inject a timestamp into a file or a complex comment. |

#### Ruby API for template hooks

> TODO: Not sure quite yet, was trying to get the basic workflow right first.

 I Imagine it would be a case of a single known method name which would take a single argument (the current template "state") and then output the modified state.

Template state would look like:

``` ruby
class Template
  attr_reader :name            # The name of the template
  attr_reader :path            # On disk path to the template files
  attr_reader :state           # [TemplateState] The current state of the template
end

class TemplateState
  attr_reader :template        # [Template] The template this is the state for
  attr_reader :settings        # A ruby hash of the settings
  attr_reader :files_to_render # An array of strings. Relative path of files to render
end
```

And a lifecycle hook file may look like:

``` ruby
#
# after_project_settings.rb
#
def after_project_settings(template_state)
  if template_state.template.name == 'foo'
    template_state.settings['bar'] = 'baz'
  else
    template_state.settings['bar'] = 'Nope!'
  end

  template_state
end
```

### File Contents

#### `<name>/template.json`

| JSON Element | Description |
| ------------ | ----------- |
| name (required) | A short descriptive name of the template |
| description | A long (even multiline) description of the template. Default is the name of the template |
| type | What type of item this is a template for. Currently only `module` is supported, but in time `control_repo` and others may be added. Default is `module` |
| default_settings | A YAML hash of the default settings for the template. Default is empty hash |
| always_apply | Always apply this template. If not specified in the template list, it will be applied last. Default is `false` |
| tags | An array of string tags for this template. Always includes the directory name of the module. Default is an empty array |

Example for the PDK Ignore template.

This template manages the `.pdkignore` file.  It subscribes to the `use_litmus` setting which will then add `/inventory.yml` to its paths

``` json
{
  "name": "PDK Ignore",
  "description": "The PDK Ignore template manages the .pdkignore file for Puppet Modules",
  "type": "module",
  "tags": [
    "ignore",
    "default",
    "pdkignore",
  ],
  "always_apply": true,
  "setting_subscriptions": [
    "use_litmus"
  ],
  "default_settings": {
    "paths": [
      "/appveyor.yml",
      "/.fixtures.yml",
      "/Gemfile",
      "/.gitattributes",
      "/.gitignore",
      "/.gitlab-ci.yml",
      "/.pdkignore",
      "/Rakefile",
      "/rakelib/",
      "/.rspec",
      "/.rubocop.yml",
      "/.travis.yml",
      "/.yardopts",
      "/spec/",
      "/.vscode/"
    ]
  }
}
```

``` json
{
  "$schema": "http://json-schema.org/draft-06/schema#",
  "$id": "http://puppet.com/schema/does_not_exist.json",
  "type": "object",
  "title": "The PDK Ignore Template Schema",
  "properties": {
    "use_litmus": {
      "$id": "#/properties/use_litmus",
      "title": "Shared setting to assert that Litmus is being used",
      "description": "Shared setting to assert that Litmus is being used",
      "type": "boolean"
    },
    "paths": {
      "$id": "#/properties/paths",
      "title": "Paths property",
      "description": "Array of file paths to also ignore by the PDK, for example, when building a module",
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  },
  "definitions": {}
}
```

#### `<name>/template_schema.json`

> TODO: I should do this!

#### Example templates

##### A template for a default module file (PDK Ignore)

> TODO

##### A template publishing a shared setting

> TODO

##### An opt-in template for CI configuration

> TODO

##### A template only for new object

> TODO

### Changes to `.sync.yml`

Renaming `.sync.yml` is considered out of scope for this RFC.  There is a large body of work already using this file to store per-project settings and renaming it would really be an RFC in of itself.

Each module may contain a `.sync.yml` file which contains the module specific settings when rendering the templates. For the new templates, the .sync.yml will have additional settings, which will also be backwards compatible with the V1 templating engine.

* Root `pdk_template` element

  The new `pdk_template` element will hold all of the data for templating engine. Due to being backwards compatible the verbose name of `pdk_template` is used instead of the generic name `template`, so that it would probably not conflict with any known files.  For example, Puppet modules have a `templates` directory.

  * `version` element (Integer) (**Required**)

  Which version of the templating engine this module uses. If the template specifies a version that the templating engine does not support it is expected the engine will raise a terminating error.

  Note that the type here is an integer. Although we could use a semver (Semantic Versioning) based string here, that would make parsing difficult.

* `template_sources` element (Array of String)

  A list of places to find Template Repositories. Order is important. If the same template (specifically the same template directory name) is specified in two sources, then the top-most source will be used ("First one wins")

  Support source types:
  * Filesystem based repository

    A directory on disk can be specified as a Template Repository.

  * Git based repository

    A git repository (For example Github, GitLab or in internal git repo)

  * `default`

    This special source type will use whatever the Template Engine considers the default.  In the case of the PDK, this would be the cached `pdk-templates` repo that is packaged as part of the PDK. Other tools using the Template Engine may specify a different location.

  If no template sources are specified `default` is used.

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
  template_sources:
    -
      type: git
      location: 'https://github.com/user/custom-templates.git'
    - default
  templates:
    - appveyor_ci
    - travis_ci
    - rubocop
    - litmus_tests

gemfile:
  # Gemfile template customisations

rubocop:
  # Rubocop template customisations

# ... etc
```

#### Filesystem based template sources

Example:

``` yaml
---
pdk_template:
  template_sources:
    -
      type: filesystem
      location: 'C:/templates/custom'
    #  Unix style path
    # -
    #   type: filesystem
    #   location: '/templates/custom'
```

| YAML Element | Description |
| ------------ | ----------- |
| type         | Must be `filesystem` |
| location     | The path the repository directory |

#### Git based template sources

``` yaml
---
pdk_template:
  template_sources:
    -
      type: git
      location: 'https://github.com/user/custom-templates.git'
      ref: master
```

| YAML Element | Description |
| ------------ | ----------- |
| type         | Must be `git` |
| location     | The git remote to clone |
| ref          | (Optional) The git reference to checkout. Default is what the git remote deems the default branch |

### Partially overriding default templates

> TODO. Should this be possible or encouraged?
>
> The idea here is to ONLY modify the ERB files so people can "tweak" default templates. This will encourage people to use the default templates more, instead of forking.

### Resolution order

The resolution order used in the V2 templates is the top-most item in the list will be used.

> TODO: What happens with conflicting settings files.  Order is important, first one wins.
> For `always_apply` modules they are last, but in alphabetical order (Needs some kind of deterministic order)

## Unresolved Questions

> TODO:

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


---

DELETE THIS


#### Why mix YAML and JSON Schema?

> Is it confusing to have both YAML and JSON in the same directory?

Initially it would seem strange to have both languages however YAML files are designed to be more human readable (and support comments).  Whereas the use of JSON is for the JSON Schema which is machine readable.  In this case we are using two different (but similar) languages because they have different strengths.

Also, there are many libraries in many different programming languages which can read, and then validate, JSON schemas.  This would mean that editing and validation would not be restricted to only the Ruby language, unlike using the Puppet Type language.