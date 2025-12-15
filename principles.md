# Principles for Define

These are general rules we try to follow that help guide our decisions about language design. If something is instead an unbreakable rule that must always be true, it goes into [requirements.md] instead.

## Define Should Read Intuively

Lines of code in define should feel something like English sentences. They don't need to actually be gramatical English sentences, but they should feel somewhat intuitive to a reader who is not deeply familiar with programming.

To be clear, define is a programming language and it does require expertise to really understand what it's doing. We aren't aiming to dumb down the language so that non-programmers can write programs in it. That's not the purpose of the language. This principle of readable lines is just a design principle that we use to think about how we structure keywords and the language's grammar.

## There Is One Right Way

As much as possible, we should strive for there to be only one correct way to write the language, even down to the style.

Total standardization enables a lot of very powerful abilities with a programming language, because you can much more easily reason about how the code is structured, have simpler compilers, easier automated refactoring, etc.

## Previous Languages Do Not Justify Decisions

There are a lot of great lessons we can and should take from previous programming languages. We should not throw away decades of lessons we have learned in programming language design. However, one of the goals of define is to create an ideal programming language regardless of how any other programming language has worked in the past. So, although we can be _informed_ by past programming languages, saying "this is how other programming languages have worked" or "this is what programmers will be familiar with from other programming languages" is not a sufficient justification _by itself_ for any language design decision.

We realize that this might make define less popular, because it's different from how other languages work. It's already so different from how other languages work that I don't think that's we're adding significantly more barriers by making different decisions than past languages have made.

## Verbosity Is Okay

Typing is not the hard part of programming. Define is intentionally very verbose as a language, for a few reasons:

* It helps us guarantee forward compatibility. It is unlikely the string "has a Number named start" will conflict with future syntax we want to create, compared to the syntax "Number start." (That syntax would greatly limit our future choices for how we modify the language.)
* It makes intent clearer to readers.
* It makes the language naturally interpretable by an AI coding assistant.
