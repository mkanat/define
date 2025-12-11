# Define Style Guide

## Naming

* Considerations are always named with UpperCamelCase.
    * If you need to use an acronym, do it like this: HttpUrl, not
      like this: HTTPURL.
* Variables (names for things) are named with lowerCamelCase. There's
  no particular reason for this choice. We just had to make a choice,
  and this is the one we made. Perhaps it's slightly faster to type
  than snake_case based on how keyboards are laid out, but that's not
  really important.

## Line Length

* Comments should be limited to 72 characters per line of text. I've
  read some research, many years ago, that it's easier to scan text
  when it's less wide, and 72 characters is apparently the sweet spot
  for that.

## Newlines

* Always have a newline at the end of a code file. Otherwise, diffs
  look like you modified the last line whenever you add more code
  at the end of the file.