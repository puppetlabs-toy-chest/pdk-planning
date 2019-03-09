# PDK user experience simplification

## Summary

PDK takes into account that Puppet developers are fluent on Ruby ecosystems.
There is an overhead for a non-Ruby developer in order to learn and understand RVM, Ruby, Bundler, Rake, PDK, dependency
management using metadata.json and fixtures. 
On my experience, this situation caused PDK to be considered superfluous and the quality of Puppet modules to decrease heavily over time.

With the headline "the shortest path to better modules" in mind, I would like to propose a simplification of the user 
experience with PDK, while still using the same ecosystem under the hood.

## Background & Assumptions

I was thinking of implementing a new project with what I suggest here, but I hope PDK is interested on using my ideas, 
so I can stay on the same page of the Puppet community. I would be happy to help coding it.

My current situation is:
- 50+ Java developers and Operation people evolving Puppet code
- Each person touches Puppet code no more than 5 times per year(It is very hard to retain knowledge)
- 80.000+ lines of Puppet code(.pp, .rb, .erb)
- Small/no control on pull requests
- No versioning and no dependency control. HEAD of the repo wins for all applications.
- All modules on the same repository
- Puppet 3.8.x
- Mercurial

For the simplest module, in order to use PDK a person has to understand:
- RVM to deal with Ruby versions - or install Ruby directly
- PDK itself
- Bundler to deal with PDK dependencies. 
- Metadata.json to deal with modules dependencies.
- A bunch of files that PDK creates inside the module(rubocop, travis, spec etc)

## Motivation & Goals

In order to help simpler projects, I propose to use implicit standards over explicit configuration, 
and reduce the 20+ generated files to only 2 or 3. By doing that, reduce confusion and friction on PDK adoption.
Some of problem that I would like to remove are:
- PDK installation requires privileges elevation.
- User may be confused by the fact that Bundler is used for the dependencies of PDK and not for the dependencies of the 
module that he/she is writing.
- If the user does not known the ecosystem, he/she will keep the CI files (.travis.yml, .gitlab-ci.yml and 
appveyor.yml) without being used, polluting the project.
- Even if a person removed the unused files, every time `pdk update` is run, once more the files have to be removed.
- If any file handled by PDK is changed, for instance `Rakefile` or `.rubocop.yml`, running `pdk update` will override 
the changes. So if customization is done, there will be hardship on upgrade.

## Proposed Implementation Design

Bellow I am listing all the changes that are on my mind. They can later be separated in multiple RFCs.

1. PDK wrapper file - `pdkw` - on the root of the module, following same standard from gradlew or mvnw
1. Single build configuration file - `build.pdk` - on the root of the module, containing:
   1. Project name, description and version
   1. Production and Test dependencies
   1. Optional URL and credentials to local puppet-forge
1. Other files necessary are generated under folder **build** - or **target** - when building the project, on any step where the file is necessary
   1. Gemfile and .rubocop.yml are generated on `validate` step
   1. .fixtures.yml and .rspec are generated on `test` step
   1. metadata.json is generated on `package` step
   1. and so on...
1. Steps are linked together. Running `./pdkw package` also runs `validate` and `test`
1. Steps should use incremental execution. E.g. files that were validated before and didn't change, should not be validated again on the next run.
1. The user must add **build** folder to .gitignore, but PDK does not take care of that. Think of many modules under the 
same repository or of people using Mercurial.
1. CI files(.travis.yml etc) are not generated on `pdk new module`. Generation is available as another command.

The user experience happens as follows.

First the user downloads the script `pdkw`.
Then the user runs `./pdkw new module` and respond the questions that PDK already asks.
The following structure is generated.

```
my_module
│   build.pdk
│   pdkw
└───manifests
    |   init.pp
```

`pdkw` contains enough information to be able to use PDK in a certain version.
`build.pdk` uses a declarative syntax containing project name, author, version, license, OS support.
`init.pp` contains an empty class.

The user adds some logic to `init.pp`, adds the address of the local puppet-forge to `build.pdk` and runs
`./pdk publish`. This will execute `validate`, `test`, `package` and finally `publish`.
By this time, the folder **build** will be generated and the project will have roughly the following content.

```
my_module
│   build.pdk
│   pdkw
└───manifests
|   |   init.pp
└───build
    └───generated
    |      rubocop.yml
    |      Gemfile
    |      Gemfile.lock
    |      Rakefile
    └───package
    |   |   metadata.json
    |   └───manifests
    |           init.pp
    └───distribution
             author-my_module-0.1.tar.gz
```

The main point here is that the project still contains 3 files. The build details are moved out of the user's sight.

## Future Considerations

This was inspired by the work of Maven and Gradle.

## Drawbacks

This is a major mindset shift and probably will require a lot of work.

It may demotivate developers to use other tools from Ruby ecosystem but outside PDK chosen ones.

## Alternatives

I tried giving training to my teammates, so the confusion would go away.
This didn't work, mainly because Puppet modules tend to stabilize and people rarely touch the code again.
Ultimately, what was learned disappears due to lack of use.