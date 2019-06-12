# Add `pdk new transport` Subcommand

## Summary

Add a new `pdk new transport` subcommand to create a ready-to-code Resource API transport, schema and test skeleton, similar to `pdk new provider`.

## Background & Assumptions

- The Resource API (and through bundling Puppet 6.4+ and bolt 1.14+) support _transports_ as a means to manage remote resources and execute tasks for systems that do not follow the conventional UNIX/Windows model of on-system execution.

- Building resources and tasks for this kind of system requires extra coding to facilitate the communication with those systems.

- A transport schema (like a type) describes the information required to communicate with a remote target.

- A transport (like a provider) implements the communication with the remote target.

- See https://github.com/puppetlabs/puppet-specifications/blob/master/language/resource-api/README.md#transports for the full specification.

## Motivation & Goals

- PDK should provide an easy way for module authors to build advanced content.

- PDK should encourage module authors to adopt good development practices, such as maintaining unit test coverage of their code.

## Proposed Implementation Design

Implement a new pdk subcommand, `pdk new transport <transport_name>` which will render a set of templates from `object_templates/transport_*` using the provided transport name.

This will build on the `pdk new provider` work for multi-file templates, and will contain the following templates:

- `transport.erb`: the main file containing the implementation
- `transport_spec.erb`: an example unit test covering the implementation skeleton
- `transport_schema.erb`: an example schema containing default attributes recommended by us: `host`, `port`, `user`, `password`.

## Unresolved Questions

- like `pdk new provider` the transport templates will require the `puppet-resource_api` gem available and `mocks_with: rspec` to be set. Are we far along the route to make those two settings the default? At least for new modules?

## Future Considerations

- If we solve the issue above, we also can fix up `pdk new provider` to use the same mechanism, and remove the `[experimental]` tag.

## Drawbacks

- committing to a template raises the bar for support and backwards compatibility.

## Alternatives

- Expect developers to copy/paste code examples from the docs
