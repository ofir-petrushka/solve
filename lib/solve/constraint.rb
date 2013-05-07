module Solve
  # @author Jamie Winsor <reset@riotgames.com>
  # @author Thibaud Guillaume-Gentil <thibaud@thibaud.me>
  class Constraint
    class << self
      # Split a constraint string into an Array of two elements. The first
      # element being the operator and second being the version string.
      #
      # If the given string does not contain a constraint operator then (=)
      # will be used.
      #
      # If the given string does not contain a valid version string then
      # nil will be returned.
      #
      # @param [#to_s] constraint
      #
      # @example splitting a string with a constraint operator and valid version string
      #   Constraint.split(">= 1.0.0") => [ ">=", "1.0.0" ]
      #
      # @example splitting a string without a constraint operator
      #   Constraint.split("0.0.0") => [ "=", "1.0.0" ]
      #
      # @example splitting a string without a valid version string
      #   Constraint.split("hello") => nil
      #
      # @return [Array, nil]
      def split(constraint)
        if constraint =~ /^[0-9]/
          operator = "="
          version  = constraint
        else
          _, operator, version = REGEXP.match(constraint).to_a
        end

        if operator.nil?
          raise Errors::InvalidConstraintFormat.new(constraint)
        end

        split_version = case version.to_s
        when /^(\d+)\.(\d+)\.(\d+)(-([0-9a-z\-\.]+))?(\+([0-9a-z\-\.]+))?$/i
          [ $1.to_i, $2.to_i, $3.to_i, $5, $7 ]
        when /^(\d+)\.(\d+)\.(\d+)?$/
          [ $1.to_i, $2.to_i, $3.to_i, nil, nil ]
        when /^(\d+)\.(\d+)?$/
          [ $1.to_i, $2.to_i, nil, nil, nil ]
        when /^(\d+)$/
          [ $1.to_i, nil, nil, nil, nil ]
        else
          raise Errors::InvalidConstraintFormat.new(constraint)
        end

        [ operator, split_version ].flatten
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_equal(constraint, target_version)
        target_version == constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_gt(constraint, target_version)
        target_version > constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_lt(constraint, target_version)
        target_version < constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_gte(constraint, target_version)
        target_version >= constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_lte(constraint, target_version)
        target_version <= constraint.version
      end

      # @param [Solve::Constraint] constraint
      # @param [Solve::Version] target_version
      #
      # @return [Boolean]
      def compare_aprox(constraint, target_version)
        min = constraint.version
        max = if constraint.patch.nil?
          Version.new([min.major + 1, 0, 0, 0])
        elsif constraint.build
          identifiers = constraint.version.identifiers(:build)
          replace     = identifiers.last.to_i.to_s == identifiers.last.to_s ? "-" : nil
          Version.new([min.major, min.minor, min.patch, min.pre_release, identifiers.fill(replace, -1).join('.')])
        elsif constraint.pre_release
          identifiers = constraint.version.identifiers(:pre_release)
          replace     = identifiers.last.to_i.to_s == identifiers.last.to_s ? "-" : nil
          Version.new([min.major, min.minor, min.patch, identifiers.fill(replace, -1).join('.')])
        else
          Version.new([min.major, min.minor + 1, 0, 0])
        end
        min <= target_version && target_version < max
      end
    end

    OPERATORS = {
      "~>" => method(:compare_aprox),
      ">=" => method(:compare_gte),
      "<=" => method(:compare_lte),
      "=" => method(:compare_equal),
      "~" => method(:compare_aprox),
      ">" => method(:compare_gt),
      "<" => method(:compare_lt)
    }.freeze

    REGEXP = /^(#{OPERATORS.keys.join('|')})\s?(.+)$/

    attr_reader :operator
    attr_reader :major
    attr_reader :minor
    attr_reader :patch
    attr_reader :pre_release
    attr_reader :build

    # @param [#to_s] constraint (">= 0.0.0")
    def initialize(constraint = nil)
      if constraint.nil? || constraint.empty?
        constraint = ">= 0.0.0"
      end

      @operator, @major, @minor, @patch, @pre_release, @build = self.class.split(constraint)
      @compare_fun = OPERATORS.fetch(self.operator)
    end

    # Return the Solve::Version representation of the major, minor, and patch
    # attributes of this instance
    #
    # @return [Solve::Version]
    def version
      @version ||= Version.new(
        [
          self.major,
          self.minor,
          self.patch,
          self.pre_release,
          self.build
        ]
      )
    end

    # Returns true or false if the given version would be satisfied by
    # the version constraint.
    #
    # @param [#to_s] target_version
    #
    # @return [Boolean]
    def satisfies?(target_version)
      target_version = Version.new(target_version.to_s)

      if target_version.pre_release? && !version.pre_release?
        return false
      end

      @compare_fun.call(self, target_version)
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        self.operator == other.operator &&
        self.version == other.version
    end
    alias_method :eql?, :==

    def to_s
      str = "#{operator} #{major}.#{minor}"
      str += ".#{patch}" if patch
      str += "-#{pre_release}" if pre_release
      str += "+#{build}" if build
      str
    end
  end
end
