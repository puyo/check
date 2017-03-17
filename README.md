# Check

An declarative unit testing style built on top of rspec for the purpose of
reducing the overhead of test:code ratios.

## Code being tested

```ruby

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
```

11 lines of code.

## RSpec

```ruby
require 'rspec'

RSpec.describe Sum do
  let(:sum) { Sum.new }

  describe '#calc' do
    subject(:call) { sum.calc(a, b, c) }

    context 'with a 1, b 2, c 3' do
      let(:a) { 1 }
      let(:b) { 2 }
      let(:c) { 3 }

      it { is_expected.to eq 6 }

      it 'should change times_summed by 1' do
        expect { call.to change(sum, :times_summed).by(1) }
      end
    end

    context 'with a 2, b 4, c 5' do
      let(:a) { 2 }
      let(:b) { 4 }
      let(:c) { 5 }

      it { is_expected.to eq 11 }
    end
  end
end
```

26 lines of code not including the require.

### Output

Running with `rspec -f d rspec-example.rb`

```
Sum
  #calc
    with a 1, b 2, c 3
      should eq 6
      should change times_summed by 1
    with a 2, b 4, c 5
      should eq 11

Finished in 0.00138 seconds (files took 0.08702 seconds to load)
3 examples, 0 failures
```

## Check

```ruby
require 'check'

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
    end
  end
end
```

14 lines of code not including the require.

### Output

```
Check
  context sum: #<Sum:0x007fe381332130 @times_summed=0>
    code sum.calc(a, b, c)
      context a: 1, b: 2, c: 3
        result
          should eq 6
        call
          should change #times_summed by 1
      context a: 2, b: 4, c: 5
        result
          should eq 11

Finished in 0.00375 seconds (files took 0.10488 seconds to load)
3 examples, 0 failures
```

## Comparison

It's a very brief example but it includes a query, a command, and a side effect
to cover all the situations you have to test.

**RSpec**

26:11, test:code = 2.36

**Check**

14:11, test:code = 1.27

Extrapolating to a 10,000 lines of code project:

- Lines of rspec code: 23600
- Lines of check code: 12700
- Lines of code saved: 10900 (more than the lines of code under test)

**Conclusion**

Save yourself hundreds of lines of test code.

**Massive Caveat**

The example is tiny and this hasn't been used on a large project. It's really
just a theory.
