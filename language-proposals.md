# How to Write a Language Proposal

All language proposals must contain the following.

## The Problem You Are Trying to Solve

Tell us what the problem is that you are trying to solve. We accept only problems that have been actually experienced by somebody, not theoretical problems that might happen. You must include an example program that shows that problem.

## A Real Program

An actual program written using the proposal. It does not have to execute. Our first and foremost goal is to create a great programming language, so show that your proposal creates a great programming language by showing an actual program written with it. Even better if you can show what that program looked like before your proposal and what it will look like after.

Note: Even if you just want to report a _problem_ about the language's design, . If you're not proposing a solution, though, that's more of just an Issue than a Language Proposal, though.

## Why This is the Right Solution

Tell us why this is the right solution to the problem you've proposed. Remember the key points in our [philosophy](philosophy.md), as that will heavily determine if we agree with your reasoning or not.

## A Description of Forward Compatibility

How will we be able to change our mind about this language feature in the future, easily? Ideally, include an example showing how we would deterministically refactor a program written with your proposal into an alternative syntax in the future. Attempt to logically demonstrate that there are no counterexamples---that after we implement your proposal, it would be impossible for a program to exist that we cannot refactor deterministically into a different syntax.

## Refactoring Existing Systems

Include an example showing how we will deterministically refactor all existing define programs to use your feature, if it requires changing some existing syntax.