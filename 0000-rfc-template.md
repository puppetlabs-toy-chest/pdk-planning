# (RFC title goes here)

## Summary

> One paragraph explanation of the feature.

## Background & Assumptions

> What is the context that someone needs to understand the goals of this proposal? This information should be objective
> facts (i.e. not subjective opinions) about the current state of things.

## Motivation & Goals

> Why should we make this change? What problems are we trying to solve? The goals listed here should be not be overly
> entangled with the proposed implementation so that they can be used to compare alternate proposals.

## Proposed Implementation Design

> This is the bulk of the RFC.

> Explain the design in enough detail for somebody familiar with the project to understand and for a third-party to be
> able to write an implementation. This should get into specifics and consider corner-cases.

> How to describe a CLI command:

```
$ pdk subcommand action <required_argument> [<optional_argument>] [--optional-flag]
```

> Include examples of how the feature would be used! An example example:

```
# Example of using a specific launch pad
$ pdk launch rocket falcon9 --launch-pad=40
pdk (INFO): Initialized launch of 'falcon9' rocket from launch pad '40'
pdk (INFO): Final countdown...
pdk (INFO): Lift off!
Successfully launched 'falcon9' rocket from launch pad '40'!
```

## Unresolved Questions

> Optional, but suggested for first drafts. What parts of the design are still TBD?

## Future Considerations

> How might this feature be expanded in the future? Could new proposed actions apply to additional types of content? Is
> the user interaction model extensible?

## Drawbacks

> Why should we *not* do this? There are tradeoffs to choosing any path, please attempt to identify them here.

## Alternatives

> What other designs have been considered? What is the impact of doing nothing?

> This section could also include prior art, that is, how other projects have solved this problem differently.

