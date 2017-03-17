# Check

An imperative unit testing style built on top of rspec.

# Code:

```ruby
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
```

# Output:

```
Check
  context sum: #<Sum:0x007f959c240750 @times_summed=0>
    code sum.calc(a, b, c)
      should add 10, 20, 30 to 60 (verbose and flexible version)
      context a: 1, b: 2, c: 3
        result
          should eq 6
        call
          should change #times_summed by 1
      context a: 2, b: 4, c: 5
        result
          should eq 11

Finished in 0.0034 seconds (files took 0.09671 seconds to load)
4 examples, 0 failures
```
