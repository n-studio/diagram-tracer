require "test_helper"

class TestClass
  def trace
    DiagramTracer.trace(self, method: :method1, type: :sequence)
  end

  def trace_block
    DiagramTracer.trace(type: :sequence) do
      self.method1
    end
  end

  def method1
    OtherTestClass.method2(parent: self)
  end

  def method3(arg1, arg2, arg3)
    42
  end
end

class OtherTestClass
  def self.method2(parent:)
    parent.method3(1, 2, 3)
  end
end

class DiagramTracerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::DiagramTracer::VERSION
  end

  def test_tracer_with_object_and_method
    diagram = TestClass.new.trace
    expected_diagram = <<~eos
      @startuml
      "TestClass" -> "OtherTestClass": "#method1()"
      "OtherTestClass" -> "TestClass": ".method2(parent)"
      "TestClass" -> "42": "#method3(arg1, arg2, arg3)"
      @enduml
    eos

    assert_equal expected_diagram, diagram
  end

  def test_tracer_with_block
    diagram = TestClass.new.trace_block
    expected_diagram = <<~eos
      @startuml
      "TestClass" -> "OtherTestClass": "#method1()"
      "OtherTestClass" -> "TestClass": ".method2(parent)"
      "TestClass" -> "42": "#method3(arg1, arg2, arg3)"
      @enduml
    eos

    assert_equal expected_diagram, diagram
  end
end
