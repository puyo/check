gem 'rspec'
require 'rspec'
require 'rspec-expectations'
require 'rspec/autorun'
require 'pp'

RSpec.configure do |config|
  config.color = true
  config.formatter = 'doc'
  config.expect_with :rspec do |c|
    c.syntax = :should
  end
end

module Check
  class Scope
    include ::RSpec::Matchers

    attr_reader :vars, :all_vars, :rspec_group

    def initialize(vars, parent: nil, &block)
      @vars = vars
      @parent = parent
      @block = block
      copy_parent_vars
      setup_rspec_group
      setup_vars
    end

    def with(vars, &block)
      scope = Scope.new(vars, parent: self, &block)
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
      example = Example.new(@all_vars, parent: self, &block)
      subject = instance_eval(&@all_vars[:call])
      example.add_to_rspec_group(subject, 'result', nil, @rspec_group)
    end

    def call(desc=nil, &block)
      example = Example.new(@all_vars, parent: self, &block)
      s = self
      c = @all_vars[:call]
      x = proc { s.instance_eval(&c) }
      example.add_to_rspec_group(x, 'call', desc, @rspec_group)
    end

    def evaluate
      instance_eval(&@block)
    end

    private

    def setup_rspec_group
      if @parent
        @rspec_group = @parent.rspec_group.describe description, **rspec_group_args
      else
        @rspec_group = RSpec.describe description, **rspec_group_args
      end
    end

    def rspec_group_args
      @vars.select{|k,v| k != :description }
    end

    def description
      @vars[:description] || description_from_vars
    end

    def description_from_vars
      "with #{@vars.select{|k,v| !v.is_a?(Proc) }.inspect}"
    end

    def copy_parent_vars
      if @parent
        @all_vars = @parent.all_vars.merge(vars)
      else
        @all_vars = vars
      end
    end

    def setup_vars
      @all_vars.each do |name, value|
        if not special_methods.include?(name)
          define_singleton_method(name) { value }
        end
      end
      @vars.each do |name, value|
        @rspec_group.let(name) { value }
      end
    end

    def special_methods
      [:description, :call, :result, :with]
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
    scope = Scope.new(vars, &block)
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

Check.with sum: Sum.new do
  with call: proc { sum.calc(a, b, c) }, description: 'sum.calc(a, b, c)' do

    with a: 1, b: 2, c: 3 do
      result { should eq 6 }
      call { should change(sum, :times_summed).by(1) }

      it 'should add 1 to times_summed' do
        call.should change(sum, :times_summed).by(1)
      end
    end

    with a: 2, b: 4, c: 5 do
      result { should eq 11 }
    end

  end
end
