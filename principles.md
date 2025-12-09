# Principles for Define

These are general rules we try to follow that help guide our decisions about language design. If something is instead an unbreakable rule that must always be true, it goes into [requirements.md] instead.

## Define Should Read Intuively

Lines of code in define should feel something like English sentences. They don't need to actually be gramatical English sentences, but they should feel somewhat intuitive to a reader who is not deeply familiar with programming.

To be clear, define is a programming language and it does require expertise to really understand what it's doing. We aren't aiming to dumb down the language so that non-programmers can write programs in it. That's not the purpose of the language. This principle of readable lines is just a design principle that we use to think about how we structure keywords and the language's grammar.

## There Is One Right Way

As much as possible, we should strive for there to be only one correct way to write the language, even down to the style.

Total standardization enables a lot of very powerful abilities with a programming language, because you can much more easily reason about how the code is structured, have simpler compilers, easier automated refactoring, etc.