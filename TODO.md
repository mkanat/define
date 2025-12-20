# TODOs for Define

Eventually we will have a bug tracker, but while I am iterating on the language
I'm just going to note down thoughts here about stuff that we should do in the
future.

- Create an auto-formatter.
- Need some form of namespacing. Maybe that's what a ViewPoint is.
- Events system

# Need some sort of registry and system to prevent naming conflicts.

- Versioning?
- Dependent properties.
- Detect dead "exposes" statements.

## Invariants and Checks

- Make sure that invariants understand what variables they depend on, so they
  know if they need to run or not.
- Figure out how much invariants can be enforced at compile time, and how we
  would redesign the language to enable that.
- When an invariant fails, make sure to spit out an error message that's super
  clear, without the developer having to enable that.
- We will need some way to validate individual variables and know exactly what's
  in them so the compiler can verify behavior.
