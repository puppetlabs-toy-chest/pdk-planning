[![Build status](https://ci.appveyor.com/api/projects/status/v7w84n21w9yjspq7/branch/master?svg=true)](https://ci.appveyor.com/project/puppetlabs/pdk-planning/branch/master)

# pdk-planning

A repository of roadmaps, feature proposals, and other planning resources for the [Puppet Development Kit].

## Contents

- [Project Goals]
- [Roadmap]
- [RFCs]

## Project Goals

- Grow the Puppet community by making it easier for users to develop, test, and share high-quality Puppet modules and
  other relevant content
- Provide a prescriptive path for writing and testing Puppet code
- Offer a single, coherent, and beautiful user interface to the best Puppet development tools
- Enable anyone to have a robust and native Puppet development environment as quickly and easily as possible

## Roadmap

[Current Roadmap](ROADMAP.md)

## RFCs

Many changes, including bug fixes and documentation improvements can be implemented and reviewed via the normal GitHub
pull request workflow.

Some changes though are "substantial", and we ask that these be put through a bit of a design process and produce a
consensus among the [PDK maintainers].  We also want to ensure that new features and other major functional changes are
in alignment with the PDK [Project Goals] and [Roadmap].  It is in everyone's best interests to have that discussion
*before* starting active implementation work on a feature.

The "RFC" (request for comments) process is intended to provide a consistent and controlled path for new features to
enter the project.

### When you need to follow this process

You need to follow this process if you intend to make "substantial" changes to PDK, its associated [templates], or
[packaging configuration].  What constitutes a "substantial" change is evolving based on community norms, but *may*
include the following:

  - Introduction of a new subcommand, subcommand action, option, or flag
  - Anything that could result in a non-trivial and user-visible change to the expected behavior of an existing feature

Some changes do not require an RFC, for example:

  - Rephrasing, reorganizing, or refactoring
  - Bug fixes or functional changes to an existing feature when the current behavior is clearly incorrect or
    unintentional (particularly when the existing behavior is not reasonably useful to anyone)
  - Modification of unstructured (i.e. not JSON, JUnit, etc.) output, or other minor UX improvements
  - Additions that strictly improve objective, numerical quality criteria (i.e. performance or resource-usage
    improvements)

If you submit a pull request to implement a new feature without going through the RFC process, it may be closed with a
polite request to submit an RFC first.

### Gathering feedback before submitting

It's often helpful to get feedback on your concept before diving into the level of design detail required for an RFC.
**You may open an issue on this repo to start a high-level discussion**, with the goal of eventually formulating an RFC
pull request with the specific implementation design.

### PDK RFC Process

In short, to get a major feature added to PDK, one must first get an RFC describing the feature merged into this repo as
a markdown file. At that point the RFC is 'active' and may be implemented with the goal of eventual inclusion into PDK.

  * Fork the pdk-planning repo http://github.com/puppetlabs/pdk-planning
  * Copy `0000-rfc-template.md` to `RFCs/0000-my-feature.md` (where 'my-feature' is descriptive, don't assign an RFC
    number yet).
  * Fill in the RFC. Put care into the details: **RFCs that do not present convincing motivation, demonstrate
    understanding of the impact of the design, or are disingenuous about the drawbacks or alternatives are likely to
    require substantial re-work before they can be fully considered**.
  * Commit your changes to your fork and submit a pull request. As a pull request the RFC will receive design feedback
    from [PDK maintainers] and other interested parties. As the author, you should be prepared to participate in the
    discussion and make revisions in response.
  * Build consensus and integrate feedback. RFCs that have broad support are much more likely to make progress than
    those that don't receive any comments. If you know other users who may be interested in your proposal, encourage them
    to participate in the discussion.
  * Eventually, the [PDK maintainers] will decide whether the RFC is a viable candidate for inclusion in PDK.
  * RFCs that are candidates for inclusion in PDK will enter a "final comment period" lasting 7 days. The beginning of
    this period will be signaled with a comment and tag on the RFC's pull request.
  * During the "final comment period", an RFC may be modified based upon feedback from the [PDK maintainers] and
    community. Significant modifications may trigger an extension to the final comment period.
  * In some cases, an RFC may be rejected by the [PDK maintainers] after public discussion has settled and comments have
    been made summarizing the rationale for rejection. If this happens, a PDK maintainer will close the RFC's pull
    request.
  * If all goes well, the RFC will be accepted at the close of its final comment period. In that case, a PDK
    maintainer will merge the RFC's pull request and the RFC will become 'active'.

### The RFC life-cycle

Once an RFC becomes active then any interested author may implement it and submit the feature as a pull request to the
PDK repo. Keep in mind that an RFC becoming 'active' is not a rubber stamp, and in particular still does not mean the
feature will ultimately be merged; it does mean that the [PDK maintainers] have agreed to it in principle and are
amenable to merging a high-quality implementation.

Furthermore, the fact that a given RFC has been accepted and is 'active' implies nothing about what priority is assigned
to its implementation, nor whether anybody is actively working on it.

Modifications to active RFC's can be done in followup pull requests. We strive to ensure that each RFC is written in a
manner that will reflect the final design of the feature; but the nature of the process means that we cannot expect
every merged RFC to accomplish that perfectly; therefore we try to keep each RFC document somewhat in sync with the
feature as it is implemented, tracking such changes via followup pull requests to the document.

### Implementing an RFC

The author of an RFC is not obligated to implement it. Of course, the RFC author (like any other potential contributor)
is welcome to post an implementation for review after the RFC has been accepted.

If you are interested in working on the implementation for an 'active' RFC, but cannot determine if someone else is
already working on it, feel free to ask (e.g. by leaving a comment on the associated issue).

### Credits

**PDK's RFC process was heavily inspired by the [Ember.js RFC process] and [Rust RFC process]**

[Roadmap]: #roadmap
[Project Goals]: #project-goals
[RFCs]: #rfcs
[Puppet Development Kit]: https://github.com/puppetlabs/pdk
[templates]: https://github.com/puppetlabs/pdk-templates
[packaging configuration]: https://github.com/puppetlabs/pdk-vanagon
[PDK maintainers]: mailto:pdk-maintainers@puppet.com
[Ember.js RFC process]: https://github.com/emberjs/rfcs
[Rust RFC process]: https://github.com/rust-lang/rfcs
