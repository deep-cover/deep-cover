require 'pry'
module DeepCover
  class Rewriter < Parser::Rewriter
    def self.patch(method_types)
      method_types.each do |method, types|
        types.each do |type|
          call_super = "super" if Parser::Rewriter.method_defined? :"on_#{type}"
          class_eval <<-"end_eval", __FILE__, __LINE__
            def on_#{type}(node)
              #{method}(node)
              #{call_super}
            end
          end_eval
        end
      end
    end

    def cover_entry(node)
      @source_rewriter.insert_before_multi node.loc.expression, " ($_cov[#{node.buffer.nb}][#{node.nb*2}]+=1;"
      @source_rewriter.insert_after_multi node.loc.expression, ").tap{$_cov[#{node.buffer.nb}][#{node.nb*2+1}]+=1}"
    end

    patch(
      cover_entry: %i[int str or send def if true false],
    )
  end
end
