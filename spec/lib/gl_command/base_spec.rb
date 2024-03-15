# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/nonprofit_classes'

RSpec.describe GlCommand::Base do
  describe 'NormalizeEin' do
    let(:ein) { '81-0693451' }

    describe 'returns' do
      it 'provides returns' do
        expect(NormalizeEin.returns).to eq([:ein])
      end
    end

    describe 'arguments' do
      it 'provides arguments' do
        expect(NormalizeEin.arguments).to eq([:ein])
      end
    end

    describe 'call' do
      it 'returns the expected result' do
        result = NormalizeEin.call(ein: '001111111')
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.ein).to eq '00-1111111'
        expect(result).not_to be_raise_errors
      end

      it 'has a verified double with expected classes', skip: "Haven't figured out verified doubles yet" do
        normalize_ein_double = instance_double(NormalizeEin::Context, ein: '00-1111111')
        expect(normalize_ein_double).to be_successful
      end
    end

    describe 'ArgumentError' do
      it "doesn't raise" do
        result = NormalizeEin.call(not_ein: ein)
        expect(result).not_to be_successful
        expect(result.error.class).to match(ArgumentError)
      end

      context 'with raise_errors: true' do
        it 'errors if called without keyword' do
          expect { NormalizeEin.call(ein, raise_errors: true) }.to raise_error(ArgumentError)
        end

        it 'errors if called with a different keyword' do
          expect { NormalizeEin.call(not_ein: ein, raise_errors: true) }.to raise_error(ArgumentError)
        end
      end

      context 'with call!' do
        it 'errors if called without keyword' do
          expect { NormalizeEin.call!(ein) }.to raise_error(ArgumentError)
        end

        it 'errors if called with a different keyword' do
          expect { NormalizeEin.call!(not_ein: ein) }.to raise_error(ArgumentError)
        end
      end
    end

    describe 'context' do
      let(:context) { GlCommand::Context.new(NormalizeEin) }
      let(:target_methods) do
        %i[arguments assign ein ein= error error= fail! failure? raise_errors? returns success? successful? to_h]
      end

      it 'is successful and does not raises errors by default' do
        expect(context).not_to be_raise_error
        expect(context).to be_successful
      end

      it 'has the instance methods' do
        context_instance_methods = (context.methods - Object.instance_methods).sort
        expect(context_instance_methods).to eq target_methods
      end

      context 'when passed raise_errors' do
        let(:context) { GlCommand::Context.new(NormalizeEin, raise_errors: true) }

        it 'is successful and raises errors' do
          expect(context).to be_raise_error
          expect(context).to be_successful
        end
      end

      describe 'inspect' do
        let(:target) { '<GlCommand::Context \'NormalizeEin\' success: true, error: nil, data: {:ein=>nil}>' }

        it 'renders inspect as expected' do
          expect(context.inspect).to eq target
        end
      end
    end
  end

  describe 'CreateNonprofit' do
    let(:ein) { '81-0693451' }

    describe 'call' do
      it 'returns the expected result' do
        result = CreateNonprofit.call(ein: ein)
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.nonprofit.ein).to eq ein
        expect(result).not_to be_raise_errors
      end
    end

    describe 'context' do
      let(:context) { GlCommand::Context.new(CreateNonprofit) }
      let(:target_methods) do
        %i[arguments assign ein error error= fail! failure? nonprofit nonprofit= raise_errors? returns success? successful? to_h]
      end

      it 'is successful and does not raises errors by default' do
        expect(context).not_to be_raise_error
        expect(context).to be_successful
      end

      it 'has the instance methods' do
        context_instance_methods = (context.methods - Object.instance_methods).sort
        expect(context_instance_methods).to eq target_methods
      end

      context 'when passed raise_errors' do
        let(:context) { GlCommand::Context.new(CreateNonprofit, raise_errors: true) }

        it 'is successful and raises errors' do
          expect(context).to be_raise_error
          expect(context).to be_successful
        end
      end

      describe 'inspect' do
        let(:target) { '<GlCommand::Context \'CreateNonprofit\' success: true, error: nil, data: {:ein=>nil, :nonprofit=>nil}>' }

        it 'renders inspect as expected' do
          expect(context.inspect).to eq target
        end
      end
    end
  end

  describe 'command with positional_parameter' do
    class TestCommand < GlCommand::Base
      def call(something, another_thing:); end
    end

    it 'raises a legible error' do
      expect do
        TestCommand.call('fff', another_thing: 'herere')
      end.to raise_error(/only.*keyword/i)
    end
  end

  describe 'rollback' do
    class SquareRoot < GlCommand::Base
      returns :number, :root

      def call(number:)
        context.root = Math.sqrt(number)
      end

      private

      def rollback
        context.root = context.number
      end
    end

    describe 'call' do
      let(:number) { 4 }

      it 'squares the number' do
        result = SquareRoot.call(number:)
        expect(result.number).to eq 4 # parameter is automatically assigned to the context
        expect(result.root).to eq 2
        expect(result).to be_successful
      end
    end

    describe 'rollback' do
      it 'runs rollback if there is a failure' do
        result = SquareRoot.call(number: -4)
        expect(result).to be_failure
        expect(result.error).to be_present
        expect(result.root).to eq result.number # Because of rollback
      end

      context 'call!' do
        it 'runs rollback' do
          # TODO: this test doesn't actually test anything
          expect do
            SquareRoot.call!(number: -4)
          end.to raise_error(/Numerical argument is out of domain/)
        end
      end
    end
  end
end
