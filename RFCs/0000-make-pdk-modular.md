# Make PDK Modular

## Summary

One of the greatest features a product can have is the ability for the customer to integrate their own workflows or automations into the product without oversight. The PDK should have a modular system and allow the user to create the plugins of their dreams. 

## Background & Assumptions

The PDK would be turned into a modular system thereby allowing users to create features
for private or public use. Without this type of modular system Puppet, Inc is responsbile
for 100% of the changes going into PDK. 

* This puts strain on Puppet 

* Users are frustrated because their ideas cannot be implemented or added quick enough

* The amount of time it takes an idea to make it to PDK core can often take months due to release cycles

## Motivation & Goals

* Allow companies to create custom private workflows and other automations.
* Allow users to create public plugins for everyone to use and share. 
* Reduces strain on Puppet as the community can create plugins more quickly
  for certain tasks. 

## Proposed Implementation Design
Below are some of the key requirements to create a modular system for the PDK

* A plugin_loader class will search installed gems and internal pdk folders for files 
  contained in lib/pdk/plugins or for gems that start with "pdk-"
* A plugin base class will define what the plugin must implement to work correctly
* PDK will call a `plugin.execute` method of the plugin to kick off chain of events
* PDK will provide a context object to the plugin which gives the plugin certain actions to call instead of allowing entire access to the PDK.
  * limits scope of private code
  * makes it easier to see what code can/should be used 
* All subcommands should be a plugin, even help
* All plugins should be lazy loaded
* Any commands of a plugin, including the subcommands should be lazy loaded
* All plugins should be classified as two types
  1. internal
  2. external
* Internal plugins cannot be redefined by external plugins
* External plugins can requrie external dependencies
* External plugins are distrubted as gems 
* External plugins must be named pdk-* so they can be easily idientified. (* is the name)
* External plugins can bind to a paticular version of PDK gem if required
* A plugin must contain a version (gemspec)
* A plugin must contain a description (gemspec)
* PDK must never require an external plugin
* PDK can package external plugins if deemed worthy
* All plugins will be auto discovered 
* Plugins can require other plugins
* Plugins should not implement another CLI system
* Plugins should specifiy a category in which they belong in which is used for  plugin info
  * workflow
  * generator
  * test
  * validation
  * ci
  * helper
  * release

### Templates
* When a plugin requires a template, it shall provide a default template inside the gem
* A plugin will also search the pdk-templates repo first before defaulting to its own internal template.


### Plugin command plugin
* A new plugin command will assist with installing/removing/searching external plugins.
    * pass through and filter for `gem` command.
    * the gem comamnd can also be used for those in the know
    * the plugin command is actually a plugin too :)


    ```
    pdk plugin install pdk-module-workflows
    pdk plugin info pdk-module-workflows
    pdk plugin remove pdk-module-workflows
    ```

### PDK provides a plugin test harness 
The PDK will contain a test harness that will make umit testing plugins simple.  This test harness
will test that the plugin abides by the rules set above, and will also exercise mandatory methods that are to be implemented by the plugin. 
  * Test for existance of template
  * Test for existance of correct naming scheme
  * Test for existance of correct versioning scheme
  * Test for proper template handling if one is available in pdk-templates
  * Tests all class methods that are required to be implemented (TBD)
    * execute
    * description
    * version
  * Plugin must meet a certain benchmark qualification?  (execution time)  
  * Plugin must not access the internet or network?


### Real world modular examples
There are several puppet related tools that exist that provide a modular system that we can take ideas from.

  * puppet-lint
  * puppet-debugger
  * vmpooler
  * test kitchen
  * vagrant
  * retrospec


### Pluginator Example
There is even a gem called `pluginator` that facilates a modular system.
This adds a new dependency but also prevents us from having to roll our own plugin finder system.
Find all the plugins in the lib/plugins/pdk directory across all gems.

```
require 'pluginator'
plugins = Pluginator.find('pdk')
```

### Custom plugin finder example 
We can create our own plugin finder system.  We should improve upon the vmpooler example but also note that it has some specific use cases as well. 

See the [vmpooler gem](https://github.com/puppetlabs/vmpooler)

Have a look at the [providers](https://github.com/puppetlabs/vmpooler/blob/master/lib/vmpooler/providers.rb) file and [PROVIDER_API](https://github.com/puppetlabs/vmpooler/blob/master/PROVIDER_API.md) file.


## Unresolved Questions

* Does CRI allow us to create a modular system easily?
* Should the plugin be able to access the internet or network?
* Not sure if dependency issues will arise with puppet-module-posix* gems

## Future Considerations

* Feature good PDK plugins on an official Puppet site
* Create a bounty system to pay people to create cool plugins
* Turn module rake tasks into plugins  (ie. blacksmith) 
  * Rake loads everything at once.  (So slow!!!)
* Some plugins may become so useful they should be added as an internal plugin

## Drawbacks

* Depending on the implementation, the pdk startup time could be impacted.

## Alternatives
N/A