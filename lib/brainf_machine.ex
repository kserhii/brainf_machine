defmodule BrainfMachine.Structure do
  @moduledoc """
  Brain F**k Machine Structure

  ##  Fields

    - prog: list with commands as bytes (e.g. [?>, ?+])
    - mem: list with actual values in memeory (head of the list is used for operations)
    - prev_mem: list with previous values in memory (used to move memory backward)
    - input: string (bytes) with input values
    - output: string (bytes) with output values

  ## Memory structure

    [ prev_mem ][(hd) mem ]
                  ^
                  |____ memory head

    Operations:

      > : [ prev_mem (hd)] [ mem ]
      < : [ prev_mem ] [(hd) mem ]

  """
  defstruct prog: [], mem: [], prev_mem: [], input: "", output: ""
end

defmodule BrainfMachine do
  @moduledoc """
  BrainF**k program interpreter

  ## Example

      iex> eval("++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.")
      "Hello World!\\n"


  | Command | C code          | Description                                     |
  |---------|-----------------|-------------------------------------------------|
  | >       | ++ptr           | increment the data pointer                      |
  |---------|-----------------|-------------------------------------------------|
  | <       | --ptr           | decrement the data pointer                      |
  |---------|-----------------|-------------------------------------------------|
  | +       | ++*ptr          | increment the byte at the data pointer          |
  |---------|-----------------|-------------------------------------------------|
  | -       | --*ptr          | decrement the byte at the data pointer          |
  |---------|-----------------|-------------------------------------------------|
  | .       | putchar(*ptr)   | output the byte at the data pointer             |
  |---------|-----------------|-------------------------------------------------|
  | ,       | *ptr=getchar()  | accept one byte of input, storing its value     |
  |         |                 | in the byte at the data pointer                 |
  |---------|-----------------|-------------------------------------------------|
  | [       | while (*ptr) {  | if the byte at the data pointer is zero,        |
  |         |                 | then instead of moving the instruction pointer  |
  |         |                 | forward to the next command, jump it forward    |
  |         |                 | to the command after the matching ] command     |
  |---------|-----------------|-------------------------------------------------|
  | ]       | }               | if the byte at the data pointer is nonzero,     |
  |         |                 | then instead of moving the instruction pointer  |
  |         |                 | forward to the next command, jump it back       |
  |         |                 | to the command after the matching [ command     |

  (C) https://en.wikipedia.org/wiki/Brainfuck

  """
  alias BrainfMachine.Structure, as: BFM

  @mem_alloc_size 100

  defp inc(255), do: 0

  defp inc(byte), do: byte + 1

  defp dec(0), do: 255

  defp dec(byte), do: byte - 1

  # Allocate more RAM memory
  defp process(bfm = %BFM{mem: []}) do
    process(%{bfm | mem: List.duplicate(0, @mem_alloc_size)})
  end

  # Put one byte from the memory head to the output
  defp process(bfm = %BFM{prog: [?. | prog], mem: [mem_val | _], output: output}) do
    process(%{bfm | prog: prog, output: output <> <<mem_val>>})
  end

  # Error: input buffer is empty
  defp process(%BFM{prog: [?, | _], input: ""}) do
    raise "Can not read value from the input because input buffer is empty."
  end

  # Put one byte from the input to the memory head
  defp process(bfm = %BFM{prog: [?, | prog], mem: [_ | mem], input: <<in_val, input::binary>>}) do
    process(%{bfm | prog: prog, mem: [in_val | mem], input: input})
  end

  # Increment memory head
  defp process(bfm = %BFM{prog: [?+ | prog], mem: [mem_val | mem]}) do
    process(%{bfm | prog: prog, mem: [inc(mem_val) | mem]})
  end

  # Decrement memory head
  defp process(bfm = %BFM{prog: [?- | prog], mem: [mem_val | mem]}) do
    process(%{bfm | prog: prog, mem: [dec(mem_val) | mem]})
  end

  # Move memory forward
  defp process(bfm = %BFM{prog: [?> | prog], mem: [mem_val | mem], prev_mem: prev_mem}) do
    process(%{bfm | prog: prog, mem: mem, prev_mem: [mem_val | prev_mem]})
  end

  # Error: backward memory move if there is no memory to move
  defp process(%BFM{prog: [?< | _], prev_mem: []}) do
    raise "Can not move memory backward because there is no memeory to move."
  end

  # Move memory backward
  defp process(bfm = %BFM{prog: [?< | prog], mem: mem, prev_mem: [mem_val | prev_mem]}) do
    process(%{bfm | prog: prog, mem: [mem_val | mem], prev_mem: prev_mem})
  end

  # Start loop block and memory head is 0
  defp process(bfm = %BFM{prog: [sub_prog | prog], mem: [0 | _]}) when is_list(sub_prog) do
    process(%{bfm | prog: prog})
  end

  # Start loop block and memory head is not 0
  defp process(bfm = %BFM{prog: [sub_prog | prog]}) when is_list(sub_prog) do
    bfm = process(%{bfm | prog: sub_prog})
    process(%{bfm | prog: [sub_prog | prog]})
  end

  # Error: undefined command
  defp process(%BFM{prog: [cmd | _]}) do
    raise "Undefined command \"#{cmd}\". Available commands are: .,+-><[]"
  end

  # Return BFM struct when program is done
  defp process(bfm = %BFM{prog: []}) do
    bfm
  end

  # Convert program string to nested lists of byte commands
  # Example: ".[+[-]>]<[,]>" -> [?., [?+, [?-], ?>], ?<, [?,], ?>]
  defp prog_tree(prog, acc \\ [])

  defp prog_tree(<<>>, acc) do
    Enum.reverse(acc)
  end

  defp prog_tree(<<?[, prog::binary>>, acc) do
    {sub_prog, sub_acc} = prog_subtree(prog, [])
    prog_tree(sub_prog, [sub_acc | acc])
  end

  defp prog_tree(<<?], _::binary>>, _) do
    raise "Unexpected close loop command. Please check the program."
  end

  defp prog_tree(<<cmd, prog::binary>>, acc) do
    prog_tree(prog, [cmd | acc])
  end

  defp prog_subtree(<<>>, _) do
    raise "Unexpected end of the loop. Please check the program."
  end

  defp prog_subtree(<<?[, prog::binary>>, acc) do
    {sub_prog, sub_acc} = prog_subtree(prog, [])
    prog_subtree(sub_prog, [sub_acc | acc])
  end

  defp prog_subtree(<<?], prog::binary>>, acc) do
    {prog, Enum.reverse(acc)}
  end

  defp prog_subtree(<<cmd, prog::binary>>, acc) do
    prog_subtree(prog, [cmd | acc])
  end

  @doc """
  Evaluate BrainF**k program.

  ## Parameters
    - program: String with BrainF**k program code to evaluate.
    - input: Optional string (bytes) that can be used as input values.

  ## Returns
      Output buffer as string.

  ## Examples

      iex> eval(",>,>,+.<++.<+++.", "abc")
      "ddd"

      iex> eval(",>,[<+>-]<.", <<7, 8>>)
      <<15>>

  """
  def eval(program, input \\ "") do
    %BFM{prog: prog_tree(program), input: input}
    |> process
    |> Map.get(:output)
  end
end
