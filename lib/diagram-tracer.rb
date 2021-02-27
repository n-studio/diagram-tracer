require "diagram_tracer/version"

module DiagramTracer
  class Error < StandardError; end

  module_function

  def trace(object = nil, method: nil, type: :sequence)
    rows = []
    result = nil
    trace = TracePoint.new(:call) do |tp|
      begin
        next if tp.path =~ /\/lib\/ruby\// || tp.path =~ /\.pryrc/
        rows << [tp.path, tp.defined_class, tp.method_id, tp.self.method(tp.method_id).parameters.map(&:last)]
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
    diagram = "@startuml\n"

    # Draw connections
    rows.each_cons(2) do |paired_rows|
      diagram << "\"#{paired_rows[0][1]}\" -> \"#{paired_rows[1][1]}\": \"#{paired_rows[0][2]}(#{paired_rows[0][3].join(', ')})\"\n"
    end
    diagram << "\"#{rows.last[1]}\" -> \"#{result}\": \"#{rows.last[2]}(#{rows.last[3].join(', ')})\"\n"
    diagram << "@enduml\n"
  end
end
