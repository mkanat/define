# Cursor Rules for Define Project

We are working together to make a programming language based on epistemology.
See [spec.md] for the language specification.

## Python Execution

- Always use `uv` to run Python applications and scripts.
- Use `uv run` to execute Python code.
- Use `uv sync` to install dependencies.

## Code Formatting

- Formatting is done with `uv run ruff format`
- Format all code after making a change.

## Linting

- Linting must be done with both `uv run pyright` and `uv run ruff check`.
- Always run both linters after making a change:
  - `uv run pyright` for type checking
  - `uv run ruff check` for code quality checks
- Fix all linting errors that are reported.

## Imports

- Prefer importing modules instead of classes:. Example:
  `from compiler import ast` and then reference `ast.ASTNode` in the code.
- Never import or use `typing.TYPE_CHECKING`.

## Docstrings

- Avoid docstrings on test methods.
- Avoid putting "Returns" clauses in docstrings on simple accessors where the
  return value is obvious from the function signature.

## Tests

- Avoid adding debug messages to assert calls.
