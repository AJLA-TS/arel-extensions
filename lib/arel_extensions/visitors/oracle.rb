module ArelExtensions
  module Visitors
    Arel::Visitors::Oracle.class_eval do
      Arel::Visitors::Oracle::DATE_MAPPING = {'d' => 'DAY', 'm' => 'MONTH', 'w' => 'WEEK', 'y' => 'YEAR', 'wd' => 'D'}

      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << '('
        o.expressions.each_with_index { |arg, i|
          collector = visit o.convert_to_string_node(arg), collector
          collector << ' || ' unless i == o.expressions.length - 1
        }
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_IMatches o, collector
        collector = visit o.left.lower, collector
        collector << ' LIKE '
        collector = visit o.right.lower(o.right), collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_IDoesNotMatch o, collector
        collector = visit o.left.lower, collector
        collector << ' NOT LIKE '
        collector = visit o.right.lower(o.right), collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_GroupConcat o, collector
        collector << "(LISTAGG("
        collector = visit o.left, collector
        if o.right
          collector << Arel::Visitors::Oracle::COMMA
          collector = visit o.right, collector
        end
        collector << ") WITHIN GROUP )"
        collector
      end

      def visit_ArelExtensions_Nodes_Coalesce o, collector
        collector << "COALESCE("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << '('
        collector = visit o.left, collector
        collector << " - "
        collector = visit o.right, collector
        collector << ')'
        collector
      end


      def visit_ArelExtensions_Nodes_Duration o, collector
        if o.left == 'wd'
          collector << "TO_CHAR("
          collector = visit o.right, collector
          collector << Arel::Visitors::Oracle::COMMA
          collector << Arel::Nodes.build_quoted('D')
        else
          collector << "EXTRACT(#{Arel::Visitors::Oracle::DATE_MAPPING[o.left]} FROM "
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Length o, collector
        collector << "LENGTH("
        collector = visit o.expr, collector
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector = visit o.left, collector
        collector << ' IS NULL'
        collector
      end

  def visit_ArelExtensions_Nodes_Rand o, collector
    collector << "dbms_random.value("
    if(o.left != nil && o.right != nil)
      collector = visit o.left, collector
      collector << Arel::Visitors::Oracle::COMMA
      collector = visit o.right, collector
    end
    collector << ")"
    collector
  end

    def visit_Arel_Nodes_Regexp o, collector
      collector << " REGEXP_LIKE("
      collector = visit o.left, collector
      collector << Arel::Visitors::Oracle::COMMA
      collector = visit o.right, collector
      collector << ')'
      collector
    end


    def visit_Arel_Nodes_NotRegexp o, collector
      collector << " NOT REGEXP_LIKE("
      collector = visit o.left, collector
      collector << Arel::Visitors::Oracle::COMMA
      collector = visit o.right, collector
      collector << ')'
      collector
    end

    def visit_ArelExtensions_Nodes_Soundex o, collector
      collector << "SOUNDEX("
      collector = visit o.expr, collector
      collector << ")"
      collector
    end

      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "INSTR("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

    def visit_ArelExtensions_Nodes_Trim o , collector
      collector << 'TRIM(' # BOTH
      collector = visit o.right, collector
      collector << ' FROM '
      collector = visit o.left, collector
      collector << ")"
      collector
    end

    def visit_ArelExtensions_Nodes_Ltrim o , collector
      collector << 'TRIM(LEADING '
      collector = visit o.right, collector
      collector << ' FROM '
      collector = visit o.left, collector
      collector << ")"
      collector
    end

    def visit_ArelExtensions_Nodes_Rtrim o , collector
      collector << 'TRIM(TRAILING '
      collector = visit o.right, collector
      collector << ' FROM '
      collector = visit o.left, collector
      collector << ")"
      collector
    end

      def visit_ArelExtensions_Nodes_Format o, collector
        case o.col_type
        when :date, :datetime
          collector << "TO_CHAR("
          collector = visit o.left, collector
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          collector = visit o.right, collector
          collector << ")"
        when :integer, :float, :decimal
          collector << "FORMAT("
          collector = visit o.left, collector
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          collector = visit o.right, collector
          collector << ")"
        else
          collector = visit o.left, collector
        end
        collector
      end

      def visit_ArelExtensions_InsertManager_BulkValues o, collector
        table = collector.value.sub(/\AINSERT INTO/, '')
        into = " INTO#{table}"
        collector = Arel::Collectors::SQLString.new
        collector << "INSERT ALL\n"
  #      row_nb = o.left.length
        o.left.each_with_index do |row, idx|
          collector << "#{into} VALUES ("
          v = Arel::Nodes::Values.new(row, o.cols)
          len = v.expressions.length - 1
          v.expressions.zip(v.columns).each_with_index { |(value, attr), i|
              case value
              when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                collector = visit value, collector
              else
                collector << quote(value, attr && column_for(attr)).to_s
              end
              collector << Arel::Visitors::Oracle::COMMA unless i == len
          }
          collector << ')'
        end
        collector << ' SELECT 1 FROM dual'
        collector
      end
    end
  end
end