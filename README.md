# BrainF**k program interpreter

![Codewars bage](https://www.codewars.com/users/KSerhii/badges/large)

### Description

Interpreter for BrainF**k programming language written in [Elixir](https://elixir-lang.org/).
This code has been written as a solution for one of the [CodeWars challenge](https://www.codewars.com/kata/526156943dfe7ce06200063e).

### BrainF**k commands description

| Command | C code          | Description                                     |
|---------|-----------------|-------------------------------------------------|
| >       | ++ptr           | increment the data pointer                      |
| <       | --ptr           | decrement the data pointer                      |
| +       | ++*ptr          | increment the byte at the data pointer          |
| -       | --*ptr          | decrement the byte at the data pointer          |
| .       | putchar(*ptr)   | output the byte at the data pointer             |
| ,       | *ptr=getchar()  | accept one byte of input, storing its value in the byte at the data pointer |
| [       | while (*ptr) {  | if the byte at the data pointer is zero, then instead of moving the instruction pointer forward to the next command, jump it forward to the command after the matching ] command |
| ]       | }               | if the byte at the data pointer is nonzero, then instead of moving the instruction pointer forward to the next command, jump it back to the command after the matching [ command |

(C) https://en.wikipedia.org/wiki/Brainfuck


### How to run
To run the BrainF**k program use the function

    BrainfMachine.eval(program, , input \\ "")


__Parameters__

- *program*: String with BrainF**k program code to evaluate.
- *input*: Optional string (bytes) that can be used as input values.

__Returns__

- Output buffer as string.


### Examples

    iex> BrainfMachine.eval(",>,>,+.<++.<+++.", "abc")
    "ddd"
    
    iex> BrainfMachine.eval(",>,[<+>-]<.", <<7, 8>>)
    <<15>>
    
    iex> BrainfMachine.eval("++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.")
    "Hello World!\n"


### Tests

Project has tests::

    mix test

