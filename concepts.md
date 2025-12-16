# The Conceptual Basis of Define

This document describes the concepts that Define is based around. It is senior to the [spec](spec.md)---it guides how we design the spec.

## A Program is a Universe

A universe is defined as "a whole system of created things."

A computer is a _universe simulator_.

A program is a universe that exists and is operating on that simulator.

The code of the program describes that universe.

A programming language exists to define universes.

## The Basic Components of a Universe

Warning: we are about to get very abstract, but I will try to make it more concrete shortly after that.

Our concepts of a universe are based around [The Factors](https://www.scientologyreligion.org/background-and-beliefs/the-factors.html) because they are the only form of epistemology I am familiar with that is sufficient to fully describe all universes, their creation, and how they operate. However, our description here is a description of the concepts that exist in Define, and should not be taken as an interpretation of The Factors, but rather just a description of how we think about universes in Define. I just wanted to credit the source that inspired these ideas.

A universe is composed of essentially two things: view points and dimension points.

A **dimension point** is a creation.

A **view point** is a creator and knower of dimension points. It is capable of creating dimension points, knowing dimension points exist (perceiving them), differentiating dimension points from each other (knowing that they are separate or different from each other), considering that dimension points have certain qualities, knowing the qualities of dimension points, and destroying their own dimension points (actually, ceasing to continuously create that dimension point).

Dimension points have whatever qualities the view point considers it to have at the moment. It has a defined relationship to other dimension points (defined by some view point).

A concrete example of this in real life is that you are reading this text right now. You are a viewpoint, and the machine you are reading this text on is a dimension point. You can change the machine's position (one of its qualities). You could turn it on or off (another quality). You can tell the difference between this machine and another machine (you have the ability to differentiate between dimension points).

Note that a view point can know (perceive) dimension points created by other view points. You probably didn't create the machine you're reading this on, but you know it exists.

This helps us clarify what a universe is: it's all the dimension points that a view point considers could possibly interact with each other. You can experience a difference between two universes right now. If you look at the machine you are reading this on, you can imagine the machine changing in some way. However, your imagination (a different universe) did not cause a change to occur in the physical universe, because your imagination and the physical universe were not _capable_ of interacting.

Okay, so this helps us understand what "a universe" is and its fundamental components. But how does this help us design a programming language? Well, there are some additional concepts we need. (We'll get there, I promise!)

## Qualities

I mentioned above that a view point can consider a dimension point to have certain qualities. Right now in the physical universe you can look around you and see all sorts of objects that have different qualities: color,shape, weight, etc. They also have qualities that only you or some small group know about: owned by you, liked by you, planned to be thrown away, etc.

Some of the things around you might also be machines: objects that _do_ something when interacted with. A sink is a machine: I turn the faucet and water comes out. I didn't go manually pull the water from its source and make it come here. I just took one small action and some other action occurred. So "this performs some action when interacted with" is also a quality that a dimension point can have.

_Side note_: If you want to get very technical, what's really happening is you're saying, "this dimension point's qualities will change in this way when I consider they should" and then that consideration can be anything: "I think so," or "I shoot this other dimension point at it," or "these other dimension points change in this way." Then you make _that_ (the idea that the dimension point reacts a certain way) a permament quality of the dimension point. But that might feel a little too abstract, here.

### Qualities in Programming

This is almost the entire basis of a computer program. A computer program is mostly a description of qualities that dimension points have, including a description of how they behave when certain other things happen.

For example, let's say I write out the following in a traditional programming language:

```Python
x = 2
y = 5
z = x + y
```

We have said that dimension point `x` now has the quality of being the number 2, dimension point `y` now has the quality of being the number 5, and after we do addition, `z` has the quality of being the number 7. But what is "addition?" Well, in the universe of that program, numbers have a quality called "addition" where if you give the number (`2` in this case) a special dimension point (the `+` symbol) then it will combine with a second dimension point (`5`) following particular rules.

There are actually multiple ways we could define that quality, by the way. We could also say that it's the `+` dimension point that has the quality, not the numbers. We could say "all dimension points in this universe follow certain rules" or "all dimension points in this part of the code follow certain rules."

## Space

A view point needs some universal mechanism to differentiate all dimension points from each other. In the physical universe, this mechnism is _space_. You say "dimension point 1 has this location, and dimension point 2 has a different location." The view point can move around the dimension points, and the view point can move itself in relation to the dimension points.

Think of eight points that make up a cube. Those eight points have a very particular relationship to each other ---that's why we see a cube. You could move those points around to change how the cube looks to you. You could move those points further away from you or closer to you. You could move yourself so you're looking at different parts of the cube. The cube takes up space, and there's space between you and the cube. You can tell that each corner of the cube is a different point; they're not all the same point. That's space.

Two dimension points cannot occupy the same space. That's the _definition_ of a dimension point: its location.

### Space in Programming

When a computer runs a computer program, it actually puts different objects into different _physical locations_. It locates them somewhere in memory, inside of the CPU, etc. Space _is_ the mechanism a computer is using to keep things separate.

However, the code of a computer program is only a description of a potential universe. It's basically a description of the qualities that certain dimension points would have if they existed, including actions those dimension points would take in various circumstances. It is, in essence, a set of ideas about qualities a universe _would_ have if that universe existed.

Code consists only of a set of symbols in order (including symbols like the space character that displays as empty space on our monitor). These symbols are the only tool we have to describe anything in code. We need some way to:

1. Describe that dimension points are different from each other.
2. Describe qualities that dimension points can have (and be able to differentiate which quality is which)

We accomplish points 1 and 2 with **names**. Names are how we create space in our programs: we give dimension points names. We give names to various qualities that dimension points can have, and then we assign those to dimension points. Thus, in our programs, the rule has to be:

**No two dimension points may have the same name.**

### A Note About Reflection

Many programming languages have a concept of "reflection" where you can, while running the program, ask questions about the program itself. For example, imagine you have Python code that looks like this:

```Python
class Adder:
    def add(x, y):
        return x + y

def understand_foo():
    my_adder = Adder()
    print(myAdder.__class__)
```

That creates a dimension point called `my_adder` that is an `Adder`. Then it prints out the word "Adder." This is reflection---we somehow looked at the program code and took some action about it (in this case, just getting the name of a class).

But here's the thing: the only real dimension point created in that program is `my_adder`. `Adder` does not actually exist in the universe of the program; it's just a quality that a dimension point can have. So what's happening here, conceptually?

Well, conceptually, what reflection is doing is operating in _another universe_. It basically makes a whole new universe that is a model of _the code_. It's taking the code and creating a whole other universe---one that isn't the program that's running. Instead, it's a universe that models out how _code_ looks and relates to other pieces of code.

In that universe (the universe of "reflection," the model of the code) we create dimension points that represent qualities. For example, what Python is really doing when you call `myAdder.__class__` looks something like this:

```Python
myClassName = object_class_name[myAdder]
```

Where `object_class_name` is a special, internal dictionary that Python maintains that maps objects to the name of their class. That special internal dictionary is, in essence, part of a _different universe_ than the universe of your program.

This fools programmers into believing that qualities have concrete existence in the universe of their programs, because they can do things like "tell me the name of this class" inside of their code. However, and this is very important, conceptually:

**Qualities do not have real existence. Only dimension points exist.**

Qualities only manifest when they are assigned to a dimension point that actually exists.

This is why programmers get themselves into endless trouble when they use or rely on reflection in their programs: they get confused about the difference between the two universes (the universe of their program and the universe of reflection). They make the behavior of the reflection universe affect the behavior of the program's universe (or worse, vice-versa, where they make logic in the program's universe change the fundamental structure of the program). This becomes very hard to reason about and tends to cause all sorts of trouble.

## Describing Qualities and Dimension Points

There are a few more problems we have to solve with just symbols:

1. How do we describe qualities?
2. How do we indicate what dimension points exist (how do we create them)?
3. How do we assign a quality to a dimension point?

This is what **syntax** is for in programming languages. Let's look at some examples to help understand this.

### Describing Qualities

Here's a description of a positive integer in an imaginary programming language:

```bash
quality NegativeInteger {
  it starts with Minus.
  it then has many Digit.
}
```

We see three names in that code: `PositiveInteger` (the name of the quality), `Minus` (presumably a name for the character `-`), and `Digit` (a quality representing a single number from 0 to 9).

Everything else is syntax:

* `quality` says "we are about to define a quality."
* `{` says "we are about to describe the quality we just named"
* `it starts with` indicates we require that the dimension point starts with this character.
* `.` indicates "we are done with describing that aspect of this quality"
* `it then has many` indicates that we expect many characters of a particular typee.
* `.` again indicates we are done with that statement.
* `}` indicates we are done describing that quality.

### Creating Dimension Points

Another imaginary programming language:

```
create negative_number
```

`create` is syntax, and `my_dimension_point` is a name.

## Assigning Qualities to Dimension Points

Yet another made-up language:

```
negative_number has the quality NegativeInteger
```

`negative_number` is a name of the dimension point we created, `has the quality` is syntax, and `NegativeInteger` is the name of the quality we defined above.