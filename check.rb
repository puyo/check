gem 'rspec'
require 'rspec/core'
require 'rspec/expectations'
require 'rspec/autorun'
require 'pp'

RSpec.configure do |config|
  config.color = true
  config.formatter = 'doc'
  config.expect_with :rspec do |c|
    c.syntax = :should
  end
end

class NicePrintHash < Hash
  def initialize(hash, &block)
    for k, v in hash
      self[k] = v
    end
    super(&block)
  end

  def to_s
    result = []
    for k, v in self
      result << "#{k}: #{v.inspect}"
    end
    result.join(', ')
  end
end

class LiteralString < String
  def initialize(str)
    super(str)
  end

  def inspect
    self
  end
end

module Check
  class Scope
    include ::RSpec::Matchers

    attr_reader :local_vars, :code_vars, :all_vars, :all_code_vars, :rspec_group

    def initialize(local_vars: nil, code_vars: nil, parent: nil, doc: nil, &block)
      #p vars: local_vars, code: code_vars
      @local_vars = NicePrintHash.new(local_vars || {})
      @code_vars = NicePrintHash.new(code_vars || {})
      @parent = parent
      @block = block
      @doc = doc
      copy_parent_vars
      setup_rspec_group
      setup_vars
      setup_code_vars
    end

    def context(args, &block)
      scope = Scope.new(local_vars: args, parent: self, &block)
      scope.evaluate
    end

    def code(code_proc, &block)
      scope = Scope.new(code_vars: {call: code_proc}, parent: self, &block)
      scope.evaluate
    end

    def it(*args, &block)
      s = self
      c = @all_vars[:call]
      x = proc { s.instance_eval(&c) }
      @rspec_group.it(*args) do
        s.instance_eval(&block)
      end
    end

    def result(&block)
      example = Example.new(local_vars: {}, parent: self, &block)
      subject = call_instance.call
      example.add_to_rspec_group(subject, 'result', nil, @rspec_group)
    end

    def call(desc=nil, &block)
      if block
        call_context(desc, &block)
      else
        call_instance
      end
    end

    def evaluate
      instance_eval(&@block)
    end

    private

    def call_context(desc, &block)
      example = Example.new(local_vars: @all_vars, parent: self, &block)
      example.add_to_rspec_group(call_instance, 'call', desc, @rspec_group)
    end

    def call_instance
      scope = self
      code = scope.all_code_vars[:call]
      proc { scope.instance_exec(&code) }
    end

    def setup_rspec_group
      if @parent
        @rspec_group = @parent.rspec_group.describe description, **rspec_group_args
      else
        @rspec_group = RSpec.describe description, **rspec_group_args
      end
    end

    def rspec_group_args
      local_vars.select{|k,v| k != :doc }
    end

    def description
      return @doc if !@doc.nil?
      if local_vars.any?
        "context #{local_vars}"
      else
        if call = code_vars[:call]
          path, line = call.source_location
          line_of_code = File.read(path).lines[line - 1]
          if m = line_of_code.match(/->\s*{\s*(.*?)\s*}\s*do/)
            line_of_code = LiteralString.new(m.captures.first)
          end
          "code #{line_of_code}"
        else
          "#{code_vars}"
        end
      end
    end

    def description_from_vars
      "with #{local_vars.select{|k,v| !v.is_a?(Proc) }.inspect}"
    end

    def copy_parent_vars
      if @parent
        @all_vars = @parent.all_vars.merge(local_vars)
        @all_code_vars = @parent.all_code_vars.merge(code_vars)
      else
        @all_vars = local_vars
        @all_code_vars = code_vars
      end
    end

    def setup_vars
      all_vars.each do |name, value|
        if not special_methods.include?(name)
          define_singleton_method(name) { value }
        end
      end
      local_vars.each do |name, value|
        if not special_methods.include?(name)
          @rspec_group.let(name) { value }
        end
      end
    end

    def setup_code_vars
      all_code_vars.each do |name, value|
        if not special_methods.include?(name)
          define_singleton_method(name) { eval(value) }
        end
      end
      code_vars.each do |name, value|
        if not special_methods.include?(name)
          @rspec_group.let(name) { eval(value) }
        end
      end
    end

    def special_methods
      [:call]
    end
  end

  class Example < Scope
    def add_to_rspec_group(sub, subject_name, desc, group)
      block = @block
      group.describe(subject_name) do
        subject { sub }
        it(desc, &block)
      end
    end
  end

  def self.with(vars, &block)
    scope = Scope.new(local_vars: vars, &block)
    scope.evaluate
  end

  def self.namespace(&block)
    scope = Scope.new(doc: 'Check', &block)
    scope.evaluate
  end

  def with(*args, &block)
    self.class.with(*args, &block)
  end

end

# -----

class Sum
  attr :times_summed

  def initialize
    @times_summed = 0
  end

  def calc(a, b, c)
    @times_summed += 1
    a + b + c
  end
end

Check.namespace do
  context sum: Sum.new do
    code -> { sum.calc(a, b, c) } do

      context a: 1, b: 2, c: 3 do
        result { should eq 6 }
        call { should change(sum, :times_summed).by(1) }
      end

      context a: 2, b: 4, c: 5 do
        result { should eq 11 }
      end

      it 'should add 10, 20, 30 to 60 (verbose and flexible version)' do
        sum.calc(10, 20, 30).should eq 60
      end
    end
  end
end

# Output:
#
# Check
#   context sum: #<Sum:0x007f959c240750 @times_summed=0>
#     code sum.calc(a, b, c)
#       should add 10, 20, 30 to 60 (verbose and flexible version)
#       context a: 1, b: 2, c: 3
#         result
#           should eq 6
#         call
#           should change #times_summed by 1
#       context a: 2, b: 4, c: 5
#         result
#           should eq 11
#
# Finished in 0.0034 seconds (files took 0.09671 seconds to load)
# 4 examples, 0 failures
