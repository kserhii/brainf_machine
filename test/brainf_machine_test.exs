defmodule CodewarsTest.BrainfMachine do
  use ExUnit.Case

  import BrainfMachine, [:eval]

  test "empty program" do
    assert eval("") == ""
  end

  test "output (.)" do
    assert eval(".") == <<0>>
  end

  test "input (,)" do
    assert eval(",.", "5") == "5"
  end

  test "error: input buffer is empty" do
    assert_raise RuntimeError, ~r/Can not read value from the input .*/, fn -> eval(",.", "") end
  end

  test "I/O correct sequence read" do
    assert eval(",.>,.>,.", "123") == "123"
  end

  test "memory increase (+)" do
    assert eval("+++.") == <<3>>
  end

  test "memory increase overflow" do
    assert eval(",+.", <<255>>) == <<0>>
  end

  test "memory decrease (-)" do
    assert eval(",---.", <<5>>) == <<2>>
  end

  test "memory decrease overflow" do
    assert eval(",-.", <<0>>) == <<255>>
  end

  test "move memory forward (>)" do
    assert eval(",>+++.", "z") == <<3>>
  end

  test "move memory backward (<)" do
    assert eval(",>+++<.", "z") == "z"
  end

  test "error: move memory backward - no way" do
    assert_raise RuntimeError, ~r/Can not move memory backward .*/, fn -> eval(",<<<.", "S") end
  end

  test "input/output" do
    assert eval(",>,>,+.<++.<+++.", "abc") == "ddd"
  end

  test "if check ([ ])" do
    assert eval("[+++].") == <<0>>
    assert eval("+[>+++<-]>.") == <<3>>
    assert eval(">[,.,.]++++.", "no") == <<4>>
    assert eval("+[,.,.,.>]", "yes") == "yes"
    assert eval(",[+.>]<+", "y") == "z"
  end

  test "loop check ([ ])" do
    assert eval("+++[>]<.") == <<3>>
    assert eval(",[>++<-]>.", <<4>>) == <<8>>
    assert eval(",>,[<+>-]<.", <<7, 8>>) == <<15>>
    assert eval(",>[-]>[-]<<[->+>+<<]>.>.", "J") == "JJ"
    assert eval("++++++++++[>++++++<-]>+++++.") == "A"
    assert eval(",>,<[>[->+>+<<]>>[-<<+>>]<<<-]>>.", <<6, 7>>) == <<42>>
  end

  test "error: undefined command" do
    assert_raise RuntimeError, ~r/Undefined command .*/, fn -> assert eval("++AbCd123.&") end
  end

  test "loop parsing" do
    assert_raise RuntimeError, fn -> eval(">>[+++++") end
    assert_raise RuntimeError, fn -> eval(">>]+++++") end
    assert_raise RuntimeError, fn -> eval(">>+++++]") end
    assert_raise RuntimeError, fn -> eval(">>+++++[") end
    assert_raise RuntimeError, fn -> eval("++[>+[-]--.") end
    assert_raise RuntimeError, fn -> eval("++[>+[-]-]]-.") end

    assert eval("[+++++]") == ""
    assert eval("[[-]]") == ""
    assert eval(">>[+++++]") == ""
  end

  test "programs" do
    assert eval(
             "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."
           ) == "Hello World!\n"

    assert eval(
             "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
           ) == "Hello World!\n"
  end

  test "echo until byte 255 is encoutered" do
    assert eval(",+[-.,+]", "Good luck" <> <<255>>) == "Good luck"
  end

  test "echo until byte 0 is encoutered" do
    assert eval(",[.[-],]", "brain_luck" <> <<0>>) == "brain_luck"
  end
end
