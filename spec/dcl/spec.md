# The Define Configuration Language Specification

## Introduction

The Define Configuration Language (DCL) is a strict subset of the
[Protocol Buffers Text Format Language](https://protobuf.dev/reference/protobuf/textformat-spec/)
(textproto). DCL is used for configuration files in the `.define` directory of
Define projects, with the file extension `.defcl`.

This specification defines the syntax and restrictions of DCL. Any valid DCL
file must be parseable by a textproto parser, but DCL rejects many constructs
that are valid in textproto in order to enforce stricter rules and improve
consistency.

### Relationship to Textproto

DCL is based on textproto, but with the following key differences:

- DCL is more restrictive: many valid textproto constructs are errors in DCL
- DCL enforces stricter formatting rules for consistency
- DCL requires schema validation: unknown field names are errors
- DCL enforces that all top-level fields must be of type Message.

Any valid DCL file is also a valid textproto file, and can be parsed by standard
textproto parsers. However, a textproto parser will accept many files that DCL
rejects.

## Strictness

DCL is intended to be a very strict language. Any syntax or behavior not
specified in this spec is an error.

The language has no "undefined behavior." If a parser encounters a situation not
described in this spec, it must provide an error and refuse to parse the file.

Because DCL is derived from the textproto format, parts of this spec explicitly
note that some textproto syntax is not supported. However, that is just advisory
text---what matters are the statements of what we _do_ parse.

## File Format

DCL files use the `.defcl` filename extension. They are UTF-8 encoded with no
BOM.

DCL files must end with a newline character.

## Lexical Elements

The lexical elements described below are based on textproto, but with specific
restrictions. Lexical elements must match the input text exactly as described.

### Characters

```ebnf
char    = ? Any non-NUL unicode character ? ;
newline = ? ASCII #10 (line feed) ? ;

lowercase_letter = "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m"
                 | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z" ;

uppercase_letter = "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M"
                 | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" ;

dec = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;

hex = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
    | "A" | "B" | "C" | "D" | "E" | "F"
    | "a" | "b" | "c" | "d" | "e" | "f" ;
```

### Whitespace and Comments

DCL restricts whitespace to only space characters and newlines. Tabs, carriage
returns, and other whitespace characters are not allowed except in comments.

```ebnf
COMMENT    = "#", { char - newline }, [ newline ] ;
WHITESPACE = " " | newline ;
```

Comments are shell-style line comments using `#`. Everything from `#` to the end
of the line is treated as a comment.

### Field Names

Field names in DCL are restricted to lowercase ASCII letters, digits, and
underscores only.

```ebnf
FIELD_NAME = lowercase_letter, { lowercase_letter | dec | "_" } ;
```

Examples of valid field names:

- `universe_name`
- `project_id`
- `config_value_1`

Examples of invalid field names:

- `UniverseName` (contains uppercase)
- `universe-name` (contains hyphen)
- `universe.name` (contains period)

### Boolean Literals

Boolean values in DCL accept only the strings `"true"` and `"false"`,
case-sensitive. Integer representations (0, 1) and other string representations
are not allowed.

```ebnf
BOOLEAN = "true" | "false" ;
```

Valid:

```
enabled: true
disabled: false
```

Invalid:

```
enabled: True
enabled: TRUE
enabled: 1
enabled: 0
enabled: t
enabled: f
```

### Numeric Literals

DCL has strict rules for numeric literals:

1. No space is allowed between a sign and the number
2. The `+` sign is not allowed (only `-` for negative numbers)
3. Floating point numbers must be exactly `INT.INT` format (no leading or
   trailing decimal points, no scientific notation, no type suffixes)

```ebnf
dec_lit   = "0"
          | ( dec - "0" ), { dec } ;
INTEGER = [ "-" ], dec_lit ;
FLOAT = [ "-" ], dec_lit, ".", dec, { dec } ;
```

Valid numeric literals:

- `10`
- `-5`
- `3.14`
- `-2.0`

Invalid numeric literals:

- `+10` (no `+` sign allowed)
- `- 5` (space between sign and number)
- `.5` (must have integer part)
- `10.` (must have fractional part)
- `10f` or `10F` (no type suffixes)
- `1e5` (no scientific notation)
- `1.5e-2` (no scientific notation)

### String Literals

DCL only allows double-quoted strings. Single-quoted strings are not allowed.

```ebnf
STRING = '"', { char - ( '"' | newline | "\" ) | escape_sequence }, '"' ;
```

escape_sequence = "\\", ( '"' | "\\" | "n" | "t" | "r" | "x", hex, hex | "u",
hex, hex, hex, hex ) ;

````

Valid string literals:

- `"hello"`
- `"hello world"`
- `"say \"hello\""`

Invalid string literals:

- `'hello'` (single quotes not allowed)

## Syntax Elements

### Top-Level Syntax

A DCL file consists of one or more top-level messages. Each top-level message
has a field name followed by a colon and a message value.

```ebnf
file = { WHITESPACE }, FIELD_NAME, ":", message_value, { WHITESPACE } ;
```

Note that `message_value` is defined below.

Valid:

```
project: {
    universe_name: "example"
}
```

Multiple top-level messages are allowed:

```
project: {
    universe_name: "example"
}
settings: {
    debug_mode: false
}
```

### Field Syntax

In DCL, field names must be followed by a colon. The syntax for fields is:

```ebnf
field = FIELD_NAME, ":", [ WHITESPACE ], value ;
````

Note that `value` is defined below.

Valid:

```
universe_name: "example"
```

Invalid:

```
universe_name "example"
```

### Values

A value in DCL can be a string literal, numeric literal, boolean literal, enum
value, message value, or repeated value:

```ebnf
value = STRING
     | INTEGER
     | FLOAT
     | BOOLEAN
     | enum_value
     | message_value
     | repeated_value ;
```

### Enum Values

Enum values may only be specified using the name from the enum definition.
Integer enum values are not allowed. Enum value names must start with an
uppercase letter and may only contain uppercase letters, digits, and
underscores.

```ebnf
enum_value = uppercase_letter, { uppercase_letter | dec | "_" } ;
```

Note that `enum_value` uses `uppercase_letter` and `dec` from the lexical
elements, but must be validated against the schema to ensure it is a valid enum
name for the field's type.

Valid (assuming `Status` enum has `ACTIVE` and `INACTIVE` values):

```
status: ACTIVE
status: INACTIVE
status: STATUS_ACTIVE
```

Invalid:

```
status: 0
status: 1
status: active
status: Active
```

### Message Values

Message fields in DCL must always use curly braces `{}`, never angle brackets
`<>`.

```ebnf
message_value = "{", [ field_list ], "}" ;

field_list = field, { WHITESPACE, field } ;
```

Valid:

```
project: {
    universe_name: "example"
}
```

Invalid:

```
project: <
    universe_name: "example"
>
```

### Repeated Field Syntax

Repeated fields must always use the list syntax with square brackets `[]`. This
applies to both repeated message values and repeated scalar literals (strings,
numbers, booleans, enums).

```ebnf
repeated_value = "[", [ value_list ], "]" ;

value_list = value, { ",", [ WHITESPACE ], value } ;
```

Note that `value` is defined in the Value Types section below.

Valid (repeated message values):

```
dependencies: [
    { universe: "mv:example.com:lib1" },
    { universe: "mv:example.com:lib2" }
]
```

Valid (repeated literals):

```
tags: [ "tag1", "tag2", "tag3" ]
```

Invalid (repeated message fields without brackets):

```
dependencies: { universe: "mv:example.com:lib1" }
dependencies: { universe: "mv:example.com:lib2" }
```

Invalid (repeated scalar without brackets):

```
tags: "tag1"
tags: "tag2"
tags: "tag3"
```

## Schema Restrictions

Because DCL is intended to be parsed by a textproto parser, it is expected that
its schema will be defined via protocol buffers. However, we place some
restrictions on that schema.

### Top-Level Structure

Literal values at the top level of a DCL file are not allowed. The top-level
message may only contain message fields.

### Required Fields

The schema must not contain any `required` fields. All fields in the schema must
be `optional` or `repeated`.

Valid (`.proto` file):

```proto
message Project {
  optional string universe_name = 1;
  repeated string tags = 2;
}
```

Invalid (`.proto` file):

```proto
message Project {
  required string universe_name = 1;  // required fields are not allowed
}
```

### Enum Values

All enum types in the schema must define a value named `UNKNOWN` with numeric
value `0`. This value represents an unknown or unset enum state.

Valid (`.proto` file):

```proto
enum Status {
  UNKNOWN = 0;
  ACTIVE = 1;
  INACTIVE = 2;
}
```

Invalid (`.proto` file):

```proto
enum Status {
  ACTIVE = 1;      // missing UNKNOWN = 0
  INACTIVE = 2;
}
```

Invalid (`.proto` file):

```proto
enum Status {
  UNKNOWN = 1;    // UNKNOWN must have value 0
  ACTIVE = 2;
}
```

### Prohibited Field Types

The following field types are not allowed in DCL:

- `bytes`
- `Any` (`google.protobuf.Any`)
- Extension annotations (using `[package.field]` syntax) are not allowed
- Proto2 `group` fields are not allowed

## Parser Behavior

### Unknown Fields

When parsing a DCL file, unknown field names (fields not present in the schema)
are errors. The parser must validate that all field names exist in the schema
and reject the file if any unknown fields are encountered.

## Example of a Valid DCL File

```
project: {
    universe_name: "mv:example.com:my_project"
    author: "Max Developer"
    dependencies: [
        {
            universe: "mv:alice.com:math_utils"
        },
        {
            universe: "mv:bob.com:networking"
        }
    ]
    settings: {
        debug_mode: false
        log_level: 3
        timeout_seconds: 30.5
    }
}
```
