require 'active_model'
require 'active_support/core_ext/class/attribute'
require 'significance'

class Money
  class_attribute :known_currencies, :exchange_rates, :default_currency
  self.known_currencies = %w(usd dkk).map(&:intern)
  self.exchange_rates = { usd_to_dkk: 6, dkk_to_usd: 1.0 / 6 }
  self.default_currency = :usd

  include Comparable
  include ActiveModel::Validations

  attr_reader :amount, :currency

  validates :amount, numericality: { greater_than_or_equal_to: 0 },
                     presence: true
  validate { Money.knows?(currency) or errors.add(:currency, :unsupported) }

  class << self
    def to_proc
      -> args { args.is_a?(Money) ? args : new(*[args].flatten.take(2)) }
    end

    def knows?(currency)
      known_currencies.include?(currency)
    end
    alias_method :known?, :knows?

    def convert(input)
      case input
        when Hash    then new(*input.significant.values_at(:amount, :currency))
        when Array   then new(*input.take(2))
        when Numeric then new(input)
      end
    end
  end

  ##
  # amount, current, options
  def initialize(amount, *args)
    return amount.dup   if amount.is_a?(Money)
    opts = args.extract_options!
    currency = args.shift
    @amount,  @currency = amount, (currency || default_currency)
    run_validations!    if opts[:validate]
    self
  end

  def amount=(val)
    amount.nil? or
         raise ArgumentError, 'Amount has already been set on this Money object'
    errors.clear unless errors.empty?
    @amount = val
  end

  def exchange_to(other_currency)
    return self if other_currency == currency
    Money.new(exchange_amount_to(other_currency), other_currency)
  end

  def unset?
    amount.nil?
  end

  def ==(other)
    unset? ? other.unset? : comparables_with(other).inject(:==)
  end

  def <=>(other)
    comparables_with(other).inject(:<=>)
  end

  def succ
    Money.new(f_amount + 1, currency)
  end

  protected
  def f_amount
    amount.to_f
  end

  private
  def exchange_rate_to(other_currency)
    exchange_rates[:"#{currency}_to_#{other_currency}"]
  end

  def exchange_amount_to(other_currency)
    f_amount * exchange_rate_to(other_currency)
  end

  def comparables_with(other)
    (currency == other.currency ? [self, other] :
                          [comparable_for(other), other.exchange_to(currency)]).
                                 map { |money| money.f_amount }#.map(&:f_amount)
  end

  def comparable_for(other)
    (@comparable ||= {})[other.currency] ||=
                           dup.exchange_to(other.currency).exchange_to(currency)
  end
end
