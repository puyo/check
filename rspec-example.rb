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

# Check.namespace do
#   context sum: Sum.new do
#     code -> { sum.calc(a, b, c) } do

#       context a: 1, b: 2, c: 3 do
#         result { should eq 6 }
#         call { should change(sum, :times_summed).by(1) }
#       end

#       context a: 2, b: 4, c: 5 do
#         result { should eq 11 }
#       end

#       it 'should add 10, 20, 30 to 60 (verbose and flexible version)' do
#         sum.calc(10, 20, 30).should eq 60
#       end
#     end
#   end
# end
