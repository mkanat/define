# Language Proposals

All language proposals must contain the following.

## A Real Program

An actual program written using the proposal. It does not have to execute. Our first and foremost goal is to create a great programming language, so show that your proposal creates a great programming language by showing an actual program written with it. Even better if you can show what that program looked like before your proposal and what it will look like after.

Even if you just want to report a _problem_ about the language's design, you must include an example program that shows that problem.

## A Description of Forward Compatibility

How will we be able to change our mind about this language feature in the future, easily? Ideally, include an example showing how we would deterministically refactor a program written with your proposal into an alternative syntax in the future. Attempt to logically demonstrate that there are no counterexamples---that aftetr we implement your proposal, it would be impossible for a program to exist that we cannot refactor deterministically into a different syntax.

## Refactoring Existing Systems

Include an example showing how we will deterministically refactor all existing define programs to use your feature, if it requires changing some existing syntax.