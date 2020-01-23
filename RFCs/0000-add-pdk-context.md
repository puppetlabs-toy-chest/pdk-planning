# Add the concept of a context in PDK

## Summary

Currently the PDK only operates on Puppet modules. While you can "trick" the PDK into working on Control Repos and Bolt Projects, this is far from optimal.
In order to facilitate adding support for Control Repositories, and in the future unknown other things, the PDK should be aware of where, or what, it's operating on.
That is, the PDK should be aware of the context that is being run in.

## Background & Assumptions

This is purely a private implementation detail in the PDK and for the most part PDK users will not see any change in behaviour.
In the future this feature could be used to change PDK behaviour, for example:

Let's say that the PDK can create new Roles and Profiles as part of a Control Repo.  This does not make sense if the PDK is running in the context of a module, therefore if a user runs `pdk new --help` the commands for `pdk new role` and `pdk new profile` would not appear in a Module context.

## Motivation & Goals

This change is required to allow the PDK to grow and service more needs, far beyond that of a Puppet Module.

## Proposed Implementation Design

### Use an Object Factory pattern

`PDK::Context.create(context_path)` will create a `PDK::Context` object based on it's internal logic.

`PDK.context` will contain a memoized context that can, and should be used, throughout a PDK session.

### `PDK::Context` object

| Method | Description |
|--------| ------------|
| name   | The name of the context e.g. `:module` or `:control_repo` |
| root_path | The root path of the context. Typically in Modules this was detected where the metadata.json was |
| context_path | The path of where this context is invoked from. Typically this is the current working directory |
| pdk_compatible? | Whether this context is compatible with the PDK. It assumed it is compatible by default |
| parent_context | A `PDK::Context` object that this context is a member of.  This caters for situations like a Module in a Control Repo. A naive implementation could simply call `PDK::Context.create(File.dirname(root_path))` |

The combination of `root_path` and `context_path` allows arbitrary contexts to be built for testing purposes and will probably not be used outside of that scenario.

Subclasses

| Context | Description |
|--------| ------------|
| `PDK::Context::None` | Represents a PDK Context where it's not in anything, for example a random directory before running `pdk new module` |
| `PDK::Context::Module` | Represents a context of being in a Puppet Module. |
| `PDK::Context::ControlRepo` (Future) | Represents a context of being in a Puppet Directory Based Control Repository |


### Modify all CLI, Validators, Generators etc. to use a context

Currently a lot of the Validators etc. duplicate code etc. by calling `PDK::Util.in_module_root?` and the like.  These Classes/Modules need to be modified to take a PDK::Context parameter

## Unresolved Questions

Should this be using object inheritance or perhaps a plain-old Hash is enough?  Personally I prefer typed objects.

## Future Considerations

Future uses would include adding new contexts or making it easier to add context detection

## Drawbacks

More complex however this is offset by the ability to make testing/mocking easier

## Alternatives

None.
