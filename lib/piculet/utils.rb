module Piculet
  class Utils
    class << self
      def diff(obj1, obj2, options = {})
        diffy = Diffy::Diff.new(
          obj1.pretty_inspect,
          obj2.pretty_inspect,
          :diff => '-u'
        )

        out = diffy.to_s(options[:color] ? :color : :text).gsub(/\s+\z/m, '')
        out.gsub!(/^/, options[:indent]) if options[:indent]
        out
      end
    end # of class methods
  end
end
