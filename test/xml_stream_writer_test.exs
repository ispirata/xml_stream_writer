#
# This file is part of xml_stream_writer.
#
# Copyright 2020 Ispirata Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

defmodule XMLStreamWriterTest do
  use ExUnit.Case
  doctest XMLStreamWriter

  test "greets the world in XML" do
    {:ok, s1, state} = XMLStreamWriter.new_document()
    {:ok, s2, state} = XMLStreamWriter.start_document(state)
    {:ok, s3, state} = XMLStreamWriter.start_element(state, "test", [])
    {:ok, s4, state} = XMLStreamWriter.characters(state, "Hello World")
    {:ok, s5, _state} = XMLStreamWriter.end_element(state)

    expected = ~s(<?xml version="1.0" encoding="UTF-8"?><test>Hello World</test>)
    assert :erlang.iolist_to_binary([s1, s2, s3, s4, s5]) == expected
  end

  test "tag with attributes" do
    {:ok, _, state} = XMLStreamWriter.new_document()
    {:ok, res, _state} = XMLStreamWriter.start_element(state, "attributes", a: "1", b: "2")

    assert :erlang.iolist_to_binary(res) == ~s(<attributes a="1" b="2">)
  end

  test "empty element" do
    {:ok, _, state} = XMLStreamWriter.new_document()
    {:ok, res, _state} = XMLStreamWriter.empty_element(state, "empty", test: "42")

    assert :erlang.iolist_to_binary(res) == ~s(<empty test="42"/>)
  end

  test "xml with nested tags and attributes" do
    {:ok, s1, state} = XMLStreamWriter.new_document()

    {:ok, s2, state} = XMLStreamWriter.start_element(state, "html", [])

    {:ok, s3, state} = XMLStreamWriter.start_element(state, "head", [])
    {:ok, s4, state} = XMLStreamWriter.start_element(state, "title", [])
    {:ok, s5, state} = XMLStreamWriter.characters(state, "XMLStreamWriter")
    {:ok, s6, state} = XMLStreamWriter.end_element(state)
    {:ok, s7, state} = XMLStreamWriter.end_element(state)

    {:ok, s8, state} = XMLStreamWriter.start_element(state, "body", [])
    {:ok, s9, state} = XMLStreamWriter.start_element(state, "p", [])
    {:ok, s10, state} = XMLStreamWriter.start_element(state, "a", href: "https://www.w3.org/XML/")
    {:ok, s11, state} = XMLStreamWriter.characters(state, "XML")
    {:ok, s12, state} = XMLStreamWriter.end_element(state)
    {:ok, s13, state} = XMLStreamWriter.characters(state, " example")
    {:ok, s14, state} = XMLStreamWriter.empty_element(state, "br", [])
    {:ok, s15, state} = XMLStreamWriter.characters(state, "in Elixir.")
    {:ok, s16, state} = XMLStreamWriter.end_element(state)
    {:ok, s17, state} = XMLStreamWriter.end_element(state)

    {:ok, s18, _state} = XMLStreamWriter.end_element(state)

    expected =
      ~s(<html><head><title>XMLStreamWriter</title></head>) <>
        ~s(<body><p><a href="https://www.w3.org/XML/">XML</a> example<br/>in Elixir.</p>) <>
        ~s(</body></html>)

    doc = [s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18]

    assert :erlang.iolist_to_binary(doc) == expected
  end

  test "escape > and <" do
    {:ok, s0, state} = XMLStreamWriter.new_document()
    {:ok, s1, state} = XMLStreamWriter.start_element(state, "escape", [])
    {:ok, s2, state} = XMLStreamWriter.characters(state, "> and < must be escaped.")
    {:ok, s3, _state} = XMLStreamWriter.end_element(state)

    expected = "<escape>&gt; and &lt; must be escaped.</escape>"

    doc = [s0, s1, s2, s3]

    assert :erlang.iolist_to_binary(doc) == expected
  end

  test ~s(escape " in attributes) do
    {:ok, s0, state} = XMLStreamWriter.new_document()
    {:ok, s1, state} = XMLStreamWriter.start_element(state, "escape", attribute: ~s(escape " me))
    {:ok, s2, state} = XMLStreamWriter.characters(state, ~s(here " is fine.))
    {:ok, s3, _state} = XMLStreamWriter.end_element(state)

    expected = ~s(<escape attribute='escape " me'>here " is fine.</escape>)

    doc = [s0, s1, s2, s3]

    assert :erlang.iolist_to_binary(doc) == expected
  end

  test "escape > and < in attributes" do
    {:ok, s0, state} = XMLStreamWriter.new_document()
    {:ok, s1, state} = XMLStreamWriter.start_element(state, "escape", attribute: "<test>")
    {:ok, s2, state} = XMLStreamWriter.characters(state, "Test")
    {:ok, s3, _state} = XMLStreamWriter.end_element(state)

    expected = ~s(<escape attribute="&lt;test&gt;">Test</escape>)

    doc = [s0, s1, s2, s3]

    assert :erlang.iolist_to_binary(doc) == expected
  end

  test ~s(everything is escaped when <, >, ", ' are used) do
    {:ok, s0, state} = XMLStreamWriter.new_document()
    {:ok, s1, state} = XMLStreamWriter.start_element(state, "escape", attribute: ~s("<'test">'))
    {:ok, s2, state} = XMLStreamWriter.characters(state, "42")
    {:ok, s3, _state} = XMLStreamWriter.end_element(state)

    expected = ~s(<escape attribute="&quot;&lt;&apos;test&quot;&gt;&apos;">42</escape>)

    doc = [s0, s1, s2, s3]

    assert :erlang.iolist_to_binary(doc) == expected
  end

  test ~s(everything is escaped when <, >, ", ', & are used) do
    {:ok, s0, state} = XMLStreamWriter.new_document()
    {:ok, s1, state} = XMLStreamWriter.start_element(state, "escape", attribute: ~s("<'te&st">'))
    {:ok, s2, state} = XMLStreamWriter.characters(state, "42")
    {:ok, s3, _state} = XMLStreamWriter.end_element(state)

    expected = ~s(<escape attribute="&quot;&lt;&apos;te&amp;st&quot;&gt;&apos;">42</escape>)

    doc = [s0, s1, s2, s3]

    assert :erlang.iolist_to_binary(doc) == expected
  end

  test ~s(use ' when <, > and " are used, but not ') do
    {:ok, s0, state} = XMLStreamWriter.new_document()
    {:ok, s1, state} = XMLStreamWriter.start_element(state, "escape", attribute: ~s("<test>"))
    {:ok, s2, state} = XMLStreamWriter.characters(state, "42")
    {:ok, s3, _state} = XMLStreamWriter.end_element(state)

    expected = ~s(<escape attribute='"&lt;test&gt;"'>42</escape>)

    doc = [s0, s1, s2, s3]

    assert :erlang.iolist_to_binary(doc) == expected
  end

  test ~s(use " when <, >, & and ' are used, but not ") do
    {:ok, s0, state} = XMLStreamWriter.new_document()
    {:ok, s1, state} = XMLStreamWriter.start_element(state, "escape", attribute: ~s('<te&st>'))
    {:ok, s2, state} = XMLStreamWriter.characters(state, "42")
    {:ok, s3, _state} = XMLStreamWriter.end_element(state)

    expected = ~s(<escape attribute="'&lt;te&amp;st&gt;'">42</escape>)

    doc = [s0, s1, s2, s3]

    assert :erlang.iolist_to_binary(doc) == expected
  end

  test "comment" do
    {:ok, s1, state} = XMLStreamWriter.new_document()
    {:ok, s2, state} = XMLStreamWriter.start_comment(state)
    {:ok, s3, state} = XMLStreamWriter.no_markup_characters(state, ~s( a comment! <, >, ", ', & ))
    {:ok, s4, _state} = XMLStreamWriter.end_comment(state)

    expected = ~s(<!-- a comment! <, >, ", ', & -->)
    assert :erlang.iolist_to_binary([s1, s2, s3, s4]) == expected
  end

  test "comment fail when characters are escaped" do
    {:ok, s1, state} = XMLStreamWriter.new_document()
    {:ok, s2, state} = XMLStreamWriter.start_comment(state)
    {:ok, s3, state} = XMLStreamWriter.characters(state, ~s( a comment! <, >, ", ', & ))
    {:ok, s4, _state} = XMLStreamWriter.end_comment(state)

    expected = ~s(<!-- a comment! <, >, ", ', & -->)
    refute :erlang.iolist_to_binary([s1, s2, s3, s4]) == expected
  end

  test "cdata" do
    cdata =
      ~s(<html><head><title>XMLStreamWriter</title></head>) <>
        ~s(<body><a href="https://www.w3.org/XML/"><!--comment &-->XML</a>) <>
        ~s(</body></html>)

    {:ok, s1, state} = XMLStreamWriter.new_document()
    {:ok, s2, state} = XMLStreamWriter.start_cdata(state)
    {:ok, s3, state} = XMLStreamWriter.no_markup_characters(state, cdata)
    {:ok, s4, _state} = XMLStreamWriter.end_cdata(state)

    expected = "<![CDATA[" <> cdata <> "]]>"
    assert :erlang.iolist_to_binary([s1, s2, s3, s4]) == expected
  end

  test "cdata fail when characters are escaped" do
    cdata =
      ~s(<html><head><title>XMLStreamWriter</title></head>) <>
        ~s(<body><a href="https://www.w3.org/XML/"><!--comment &-->XML</a>) <>
        ~s(</body></html>)

    {:ok, s1, state} = XMLStreamWriter.new_document()
    {:ok, s2, state} = XMLStreamWriter.start_cdata(state)
    {:ok, s3, state} = XMLStreamWriter.characters(state, cdata)
    {:ok, s4, _state} = XMLStreamWriter.end_cdata(state)

    expected = "<![CDATA[" <> cdata <> "]]>"
    refute :erlang.iolist_to_binary([s1, s2, s3, s4]) == expected
  end

  test "xml with nested tags, attributes, comments and cdata" do
    {:ok, s1, state} = XMLStreamWriter.new_document()

    {:ok, s2, state} = XMLStreamWriter.start_cdata(state)

    {:ok, s3, state} =
      XMLStreamWriter.no_markup_characters(state, ~s(<hello ' "> &world </<>hello>))

    {:ok, s4, state} = XMLStreamWriter.end_cdata(state)

    {:ok, s5, state} = XMLStreamWriter.start_element(state, "html", [])

    {:ok, s6, state} = XMLStreamWriter.start_element(state, "head", [])
    {:ok, s7, state} = XMLStreamWriter.start_element(state, "title", [])
    {:ok, s8, state} = XMLStreamWriter.characters(state, "XMLStreamWriter")
    {:ok, s9, state} = XMLStreamWriter.end_element(state)
    {:ok, s10, state} = XMLStreamWriter.end_element(state)

    {:ok, s11, state} = XMLStreamWriter.start_element(state, "body", [])
    {:ok, s12, state} = XMLStreamWriter.start_element(state, "a", href: "https://www.w3.org/XML/")

    {:ok, s13, state} = XMLStreamWriter.start_comment(state)
    {:ok, s14, state} = XMLStreamWriter.no_markup_characters(state, ~s(comment &<>'"))
    {:ok, s15, state} = XMLStreamWriter.end_comment(state)

    {:ok, s16, state} = XMLStreamWriter.characters(state, "XML")
    {:ok, s17, state} = XMLStreamWriter.end_element(state)
    {:ok, s18, state} = XMLStreamWriter.end_element(state)

    {:ok, s19, _state} = XMLStreamWriter.end_element(state)

    expected =
      ~s(<![CDATA[<hello ' "> &world </<>hello>]]>) <>
        ~s(<html><head><title>XMLStreamWriter</title></head>) <>
        ~s(<body><a href="https://www.w3.org/XML/"><!--comment &<>'"-->XML</a>) <>
        ~s(</body></html>)

    doc = [s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19]

    assert :erlang.iolist_to_binary(doc) == expected
  end
end
