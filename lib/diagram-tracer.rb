require "diagram_tracer/version"

module DiagramTracer
  class Error < StandardError; end

  module_function

  TAB = "    ".freeze

  def trace(object = nil, method: nil, type: :sequence)
    rows = []
    result = nil
    trace = TracePoint.new(:call) do |tp|
      begin
        rows << [tp.lineno, tp.defined_class, tp.method_id, tp.self.method(tp.method_id).parameters.map(&:last)]
      rescue NameError
      end
    end
    trace.enable do
      if object && method
        result = object.send(method)
      else
        result = yield
      end
    end
    convert_to_graph(rows, result, type)
  end

  def convert_to_graph(rows, result, type)
    send("convert_to_#{type}".to_sym, rows, result)
  rescue NoMethodError
    raise Error.new("Unknown type '#{type}'")
  end

  def convert_to_sequence(rows, result)
    diagram = "sequenceDiagram\n"

    # List participants
    rows.each do |row|
      diagram << TAB + "participant #{row[1]}\n"
    end
    diagram << TAB + "participant '#{result}'\n"
    # Draw connections
    rows.each_cons(2) do |paired_rows|
      diagram << TAB + "#{paired_rows[0][1]}->>#{paired_rows[1][1]}: #{paired_rows[0][2]}(#{paired_rows[0][3].join(', ')})\n"
    end
    diagram << TAB + "#{rows.last[1]}->>'#{result}': #{rows.last[2]}(#{rows.last[3].join(', ')})\n"
  end
end
