require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'active_support/core_ext/proc'

describe Money do
  subject(:klass) { Money }

  default_currency = :usd
  cur1, cur2, *_      =   supported_currencies = [default_currency, :dkk]
  xcur1, *_           = unsupported_currencies = [:unk]
  inf   = 1.0/0
  ninf  = -inf
  positive_values     = [0.1, 1.0/6, 1, 100.00005]
  negative_values     = [-0.1, -1.0/6, -1, -100.00005]
  zero_values         = [0, 0.0]
  numeric_values      = [*positive_values, *zero_values, *negative_values]
  infinite_values     = [inf, ninf]
  valid_values        = [*positive_values, *zero_values, inf]
  invalid_values      = [*negative_values, ninf, nil]
  comparable_values   = [*numeric_values, *infinite_values]
  incomparable_values = [nil]
  test_values         = valid_values + invalid_values

  let(:value1) { example.metadata[:value1] }
  let(:value2) { example.metadata[:value2] }
  let(:currency1) { example.metadata[:currency1] }
  let(:currency2) { example.metadata[:currency2] }
  let(:money1) { described_class.new(value1, *currency1) }
  let(:money2) { described_class.new(value2, *currency2) }

  describe '.new', method: :new do
    let(:args) { [] }
    subject(:money) { described_class.new(*args) }

    context 'with: (no arguments)' do
      it { expect { money }.to raise_error ArgumentError }
    end

    test_values.each do |value|

      context "with: #{value.inspect}" do
        let(:args) { [value] }

        it { should be_an_instance_of described_class }
        its(:amount) { should == value }
        its(:currency) { should eq default_currency }

        context "as USD" do
          let(:args) { [value, :usd] }

          it { should be_an_instance_of described_class }
          its(:amount) { should == value }
          its(:currency) { should eq :usd }
        end

        context "as DKK (non-default)" do
          let(:args) { [value, :dkk] }

          it { should be_an_instance_of described_class }
          its(:amount) { should == value }
          its(:currency) { should eq :dkk }
        end

        context "as unknown currency" do
          let(:args) { [value, :unk] }

          it { should be_an_instance_of described_class }
          its(:amount) { should == value }
          its(:currency) { should eq :unk }
          it { should_not be_valid }
          # its(:errors) { should_not be_empty }
          # specify { money.errors[:currency].should_not be_empty }
          # it { should have_error :unsupported }
        end
      end
    end
  end

  describe '.to_proc', method: :to_proc do
    subject(:result) { described_class.send(method) }

    it { should be_a Proc }
    its(:arity) { should == 1 }

    it "should convert each test value to an instance of #{described_class}" do
      test_values.each { |v| result.call(v).should be_a described_class }
    end
  end

  describe '.knows?/.known?' do

    it { should be_known :usd }
    it { should be_known :dkk }
    it { should_not be_known :eu }
  end

  describe '.convert', method: :convert do
    courier = Proc.new { |m, x| described_class.method(m).call(x) }.curry
    subject(:result) { courier[method, input] }
    let(:input) {}

    hsh0 = { amount: nil, currency: :usd }
    input_hashes = [{ amount: 10, currency: :dkk }, { amount: 10 },
                    { currency: :dkk }, {}]

    context 'with Hash:' do

      input_hashes.each do |hsh|
        expecteds = hsh0.merge(hsh)

        context do
          metadata[:example_group][:description_args].unshift hsh.inspect
          let(:input) { hsh }

          it { expect(&example.example_group.subject.bind(self)).not_to raise_error
               should be_an_instance_of described_class }
          its(:amount) { should == expecteds[:amount] }
          its(:currency) { should eql expecteds[:currency] }
        end
      end
    end

    context 'with Array:' do

      input_hashes.each do |hsh|
        expecteds = hsh0.merge(hsh)

        context do
          ary = hsh.values_at(:amount, :currency)
          metadata[:example_group][:description_args].unshift ary.inspect
          let(:input) { ary }

          it { expect(&example.example_group.subject.bind(self)).to_not raise_error
               should be_an_instance_of described_class }
          its(:amount) { should == expecteds[:amount] }
          its(:currency) { should eql expecteds[:currency] }
        end
      end
    end

    context 'with Numeric' do

      [10, 0].each do |i|
        context do
          metadata[:example_group][:description_args].unshift i.inspect
          let(:input) { i }

          it { expect(&example.example_group.subject.bind(self)).to_not raise_error
               should be_an_instance_of described_class }
          its(:amount) { should == i }
          its(:currency) { should eql hsh0[:currency] }
        end
      end
    end

    context 'with invalid argument:' do

      context '(no argument)' do
        specify { expect { described_class.send(method) }.to raise_error }
      end

      context 'nil' do
        let(:input) { nil }

        it { expect(&example.example_group.subject.bind(self)).to_not raise_error
             should be_nil }
      end
    end
  end

  describe '#amount=' do

    context 'with amount already set' do
      subject(:money) { described_class.new(271) }

      specify { expect { expect { subject.amount = 666 }.to raise_error }.to_not change(subject, :amount) }
    end

    context 'with amount not already set' do
      subject(:money) { described_class.new(nil) }

      specify { expect { expect { subject.amount = 666 }.to_not raise_error }.to change(subject, :amount).to(666) }
    end
  end

  describe '#exchange_to' do
    let(:original)  { described_class.new(6) }
    let(:exchanged) { original.exchange_to(:dkk) }

    subject { original }

    describe 'the exchanged object' do
      subject { exchanged }

      it { should_not be original }
      it { should == original }
      its(:amount) { should == 36 }

      specify 'comparisons are as expected' do
        expect(original <=> exchanged).to eq(0)
        expect(exchanged <=> original).to eq(0)
      end
    end
  end

  describe '#unset?' do
    subject(:money) { described_class.new(value) }

    context 'with an amount set to nil' do
      let(:value) { nil }
      its(:unset?) { should be_true }
    end

    context 'with an amount set to nonnil' do
      let(:value) { 20 }
      its(:unset?) { should be_false }
    end
  end

  describe '#==' do

    context 'with both objects having an unset value' do
      specify { expect(money1 == money2).to be_true }
    end

    context 'with just one object having an unset value' do
      let(:nonnil) { 5 }

      it 'returns false for any such pairing' do
        expect(money1 == Money.new(nonnil)).to be_false
        expect(Money.new(nonnil) == money2).to be_false
      end
    end

    context 'with both objects having a set value' do

      context 'that are the same' do

        it 'returns true for value1 being same as value2', value1: 10, value2: 10 do
          expect(money1 == money2).to be_true
          expect(money2 == money1).to be_true
        end

        it 'returns true for value1 being numerically the same as value2', value1: 10, value2: 10.0 do
          expect(money1 == money2).to be_true
          expect(money2 == money1).to be_true
        end
      end

      context 'that are different' do

        it 'returns false for value1 < value2', value1: 5, value2: 10 do
          expect(money1 == money2).to be_false
          expect(money2 == money1).to be_false
        end

        it 'returns false for value2 < value1', value1: 10, value2: 5 do
          expect(money1 == money2).to be_false
          expect(money2 == money1).to be_false
        end
      end
    end
  end

  describe '#<=>' do

    it 'handles receiver being smaller than argument', value1: 3, value2: 6 do
      expect(money1 <=> money2).to eq(-1)
    end

    it 'handles receiver being larger than argument', value1: 7, value2: 4 do
      expect(money1 <=> money2).to eq(1)
    end

    it 'handles receiver being same as argument', value1: 2, value2: 2 do
      expect(money1 <=> money2).to eq(0)
    end

    it 'handles nil amount values as 0', value1: 3, value2: nil do
      expect(money1 <=> money2).to eq(1)
      expect(money2 <=> money1).to eq(-1)
      expect(money2 <=> money2).to eq(0)
    end

    context 'with different currencies', currency1: :usd, currency2: :dkk do

      it 'handles receiver being smaller than argument', value1: 1, value2: 7 do
        expect(money1 <=> money2).to eq(-1)
      end

      it 'handles receiver being larger than argument', value1: 1, value2: 5 do
        expect(money1 <=> money2).to eq(1)
      end

      it 'handles receiver being same as argument', value1: 1, value2: 6 do
        expect(money1 <=> money2).to eq(0)
      end
    end
  end

  describe '#succ' do

    test_values.each do |value|
      next if value.nil?

      context "on: Money.new(#{value})" do
        subject(:money) { described_class.new(value) }

        specify { expect { money.succ }.to_not raise_error }
        specify { (money.amount + 1).should == money.succ.amount }
      end
    end
  end
end
