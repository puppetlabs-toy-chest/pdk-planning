# Add `pdk console` subcommand

## Summary

This RFC is for adding a new command called `console` that would invoke the 
puppet debugger [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop_) when executed.  This allows the puppet developer to easily test out language constructs and answer questions users might have about puppet code without jumping to external resources or running puppet apply.   The console commamd would be invoked with or without a module scope and would be similar to having ruby's IRB, python's REPL, Node's REPL, ChefDK REPL, 'insert language' REPL within easy reach. 


## Background & Assumptions

The PDK brings in multiple versions of Ruby and it is not clear how the puppet debugger or any other gem not part of the PDK should be installed.  Currently the debugger can be installed at the module level within the Gemfile or at a more "global level" so it can be invoked without the module.  However, the PDK doesn't really expose a way to install global gems unless you know Ruby well.  So a user would have to run `/opt/puppetlabs/pdk/private/ruby/2.4.5/bin/gem install puppet-debugger` to install the debugger at the PDK global level.

Then run `/opt/puppetlabs/pdk/private/ruby/2.4.5/bin/puppet debugger` to invoke it.

A user could then modify their PATH environment variable to include `/opt/puppetlabs/pdk/private/ruby/2.4.5/bin/` which would make it easier but not optimal for the user.

Additionally, there is still the question of which Ruby version do we use?  

The other way of invoking the debugger is through the bundle exec passthrough.  ie. `pdk bundle exec puppet debugger`.  This means the user will need to add the puppet-debugger gem to their .sync file and run `pdk update`.  Once this is complete the user will be able to run the debugger within the context of the their module.  Personally, I hate typing long commands so this seems aching for a new pdk command.

## Motivation & Goals

It really comes down to pure laziness. The debugger is the first thing I install after the pdk.  It should be included in the PDK and to keep all other PDK users from having to install what I think is a very neccessary development tool. 

There also needs to be an easy way to invoke the debugger.  Without the PDK, invoking the debugger command was simple.  `puppet debugger`.  However, if the PDK is involved this is not possible anymore. The PDK is just a broker to run other commands that are santioned.  

Another point here is that the debugger was not built by puppet so many users are not aware of its existance because it is not publizied by puppet. Including this tool in the PDK should ensure that a greater audience has exposure to it.

I would also wager that many questions that are often asked in the forum or slack channel would be self answered 
via the debugger. So is it important that we put this tool in the hands of the developer with greatest ease.

The motivation behind this is to make it dead simple how to start the debugger no matter which context is used. 

## Proposed Implementation Design
We are going to use a more generic command name called `console` that will start a puppet debugger session.  This is similar to how other tooling works like rails.

The PDK console command can be invoke in two contexts.  
  
  1. Without a module
  2. Within a module

### Without a module
The `pdk console` command is invoked outside the module and the debugger will assume any settings specified 
in the puppet config file or passed in as an argument.  `pdk debugger --basemodulepath=~/dev/modules --log_level=debug`. 
Since there is no module context, the user has access to modules only specified via the modulepaths defined in the puppet settings.   A user can also specify hiera settings here as well with `--hiera_config=/dev/control_repo/hiera.yaml` in order to test lookup behavior.  

In this example a user wants to know if 'true' is a Boolean.  They are not inside a module and only want to answer this simple question without referring to documention or other users. 

```
$ pdk console -e "'true' == true" --run-once
Ruby Version: 2.5.1
Puppet Version: 6.7.2
Puppet Debugger Version: 0.12.3
Created by: NWOps <corey@nwops.io>
Type "commands" for a list of debugger commands
or "help" to show the help screen.


1:>> 'true' == true
 => false
```

### Within a module
The other way of invoking the console will be in the context of a module.  However, because the user is inside a module, it will be scoped down to only the module's dependencies inside that module.  This is important because it gives the user a clean sandbox respective of their current dependencies and hiera data. 

Example workflow

1. `cd apache_module`
2. `pdk console`

Because we can check if we are in a module via `PDK::Util.in_module_root?` we can make some assumptions and automate a few settings for the user. The settings we can assume are:

1. basemodulepath=./spec/fixtures/modules:./modules
2. environmentpath=./spec/fixtures/modules:./modules
3. modulepath=./spec/fixtures/modules:./modules

*NOTE* We are setting all these paths because want the user to work in a strict sandbox.  Some of these paths like environmentpath don't make sense and are only used to poison the settings found in Puppet.settings.  We may decide later to allow the user to override these defaults.

*NOTE* This would mean that a `rake spec_prep` would have to be run to download any modules.  

*NOTE* For multi-tier lookups the user would need to supply the hiera_config file location setting.  By default the hiera_config setting will use what is found in Puppet.settings. 

The command invoke within a module is still the same.

```
$ pdk console -e "'true' == true" --run-once
Ruby Version: 2.5.1
Puppet Version: 6.7.2
Puppet Debugger Version: 0.12.3
Created by: NWOps <corey@nwops.io>
Type "commands" for a list of debugger commands
or "help" to show the help screen.


1:>> 'true' == true
 => false
```

### Additional Config Options
Many users have used the debugger without understanding what options can be passed in. This is because the debugger is a puppet application.  It inherits all the config options that puppet accepts. So while the puppet debugger does have some options itself most are inherited and passed through to puppet (Same as puppet apply).  See the following options [listed here](https://puppet.com/docs/puppet/5.5/configuration.html). 

With this is mind we will want to respect these options when using the `pdk console` command.  We will need to forward these options to the command so the user can override anything they desire.  By default, the debugger will just read the settings via the config file using `Puppet.settings`. 

### Special Arguments
There are two config options that are specific to PDK that make the debugger's involvement special.  Without the PDK the debugger cannot switch ruby or puppet versions easily.  The PDK makes this simple using the 
`--puppet-version=5.5.12` or `--pe-version=2018.1` arguments.  These arguments will allow the user to use the debugger to see how the language changed between versions. 

`pdk console --puppet-version=5.5.12 -e 'true' =~ Boolean'`

`pdk console --puppet-version=6.7.0 -e "'true' =~ Boolean"`

This would tell the user if the code has changed behavior in the newer version.  

### Add to puppet-module meta gems
The puppet-debugger should also be added to the puppet-module meta gems so it can be invoke within the module. 

## Unresolved Questions

What is the best way to forward arguments to a subcommand if they are only to be forwarded to puppet?  

Example:  `--basemodulepath` is not a puppet debugger argument but is instead a puppet argument. 

So when a user runs `pdk console --basemodulepath=~/modules` it would essentially run `/pdk_bin_path/puppet debugger --basemodulepath=~/modules`

Currently PDK will fail because --basemodulepath is not a pdk console option.  This can be avoided via `skip_option_parsing` method but we still want to parse the `--puppet-version`, `--pe-version`, and `--puppet-dev` arguments. 

There may need to be a `ignore_bad_arguments` method or something to still have the option parsing without errors. 

## Future Considerations

It might also be a good idea to pass in a `--debugger-version=X.X.X` option to auto install the lastest if not present. 

Add the [puppet-debug](https://forge.puppet.com/nwops/debug) module to the fixtures by default. See the [following article](http://logicminds.github.io/blog/2017-04-25-break-into-your-puppet-code/) for some use cases about inserting a break statement  (similar to binding.pry).


## Drawbacks
The debugger is a community developed gem and will have updates every so often. These updates may break the `pdk console` command or include dependencies that conflict in some way. Testing will need to be added to the PDK to account for future updates.  However, this is no different than any other gem included with the pdk. 

## Alternatives

The alternative is to list the debugger as a dependency in the `puppet-module-posix- and puppet-module-windows-` gems and the user can invoke
via `pdk bundle exec puppet debugger --basemodulepath=./spec/fixtures/modules --hiera_config=./hiera.yaml`

Although this will need to be done regardless when the debugger is invoked from within a module. 

But as you can see you will only type this once before making an alias. 