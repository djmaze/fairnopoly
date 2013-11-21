#
#
# == License:
# Fairnopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Fairnopoly.
#
# Fairnopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairnopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly.  If not, see <http://www.gnu.org/licenses/>.
#
require 'spec_helper'

describe Transaction do
  describe "attributes" do
    it { should respond_to 'selected_transport' }
    it { should respond_to 'selected_payment' }
    it { should respond_to 'tos_accepted' }
    it { should respond_to 'message' }
  end

  describe "associations" do
    it { should belong_to :article }
    it { should belong_to :buyer  }
  end

  describe "model attributes" do
    it { should respond_to :type }
    it { should respond_to :selected_transport }
    it { should respond_to :selected_payment }
    it { should respond_to :tos_accepted }
  end

  describe "enumerization" do
    it { should enumerize(:selected_transport).in(:pickup, :type1, :type2) }
    it { should enumerize(:selected_payment).in(:bank_transfer, :cash, :paypal, :cash_on_delivery, :invoice) }
  end

  describe "methods" do
    let(:transaction) { FactoryGirl.create :super_transaction }

    describe "that are public" do

      describe "#edit_params_valid?" do
        def valid_params
          {
            "selected_transport" => "pickup",
            "selected_payment" => "cash",
            "forename" => "Foo",
            "surname" => "Bar",
            "street" => "Baz Str. 1",
            "city" => "Fuz",
            "zip" => "12345",
            "country" => "Deutschland"
          }
        end

        it "should return true with valid params" do
          r = transaction.edit_params_valid? "transaction" => valid_params
          r.should be_true
        end

        it "should return false with invalid transport" do
          r = transaction.edit_params_valid? "transaction" => valid_params.merge({"selected_transport" => "type1"})
          r.should be_false
        end

        it "should return false with invalid payment" do
          r = transaction.edit_params_valid? "transaction" => valid_params.merge({"selected_payment" => "paypal"})
          r.should be_false
        end
      end

      describe "#selected_transports" do
        it "should call the private #selected method" do
          transaction.should_receive(:selected).with("transport")
          transaction.selected_transports
        end
      end

      describe "#selected_payments" do
        it "should call the private #selected method" do
          transaction.should_receive(:selected).with("payment")
          transaction.selected_payments
        end
      end

      describe "#selected?" do
        it "should return true when the seller selected a specific transport/payment type" do
          transaction.selected?('transport', 'pickup').should be_true
        end

        it "should return false when the seller didn't select spcified type" do
          transaction.selected?('payment', 'paypal').should be_false
        end
      end
    end

    describe "that are protected" do
      it "should generally not allow quantity_available" do
        expect { transaction.quantity_available }.to raise_error(NoMethodError)
      end
      it "should generally not allow quantity_bought" do
        expect { transaction.quantity_bought }.to raise_error(NoMethodError)
      end
    end

    describe "that are private" do
      describe "#selected" do
        it "should get the article's selectable attributes" do
          transaction.article.should_receive(:selectable).with("transport").and_return(["pickup"])
          transaction.selected_transports
        end

        it "should return an Array with selected attributes and their localizations" do
          transaction.selected_transports.should eq [[I18n.t("enumerize.transaction.selected_transport.pickup"), "pickup"],
                                                      [I18n.t("enumerize.transaction.selected_transport.type1"),"type1"],
                                                      [I18n.t("enumerize.transaction.selected_transport.type2"),"type2"]]
        end
      end
    end
  end
end

describe MultipleFixedPriceTransaction do
  let(:mfpt) { MultipleFixedPriceTransaction.new }

  it "should have a valid factory" do
    expect {
      FactoryGirl.create :multiple_transaction
    }.to change(Transaction, :count).by 1
    t = Transaction.last
    t.type.should eq "MultipleFixedPriceTransaction"
    t.article.should be_an Article
    t.article_quantity.should > 1
  end

  it "should be generated with an article that has a quantity of more than one" do
    expect {
      FactoryGirl.create :article, quantity: 2
    }.to change(Transaction, :count).by 1
    Article.last.transaction.should be_a MultipleFixedPriceTransaction
  end

  describe "attributes" do
    it { should respond_to 'quantity_available' }
  end

  describe "methods" do
    describe "#buy_multiple_transaction" do

      context "when quantity_bought is greater than the available quantity" do
        it "should add an error" do
          mfpt.quantity_available = 2
          mfpt.quantity_bought = 3
          mfpt.send(:buy_multiple_transaction)
          mfpt.errors[:quantity_bought].should_not be_nil
        end
      end

      context "when quantity_bought is lower than (or equal to) the available quantity" do
        before do
          mfpt.quantity_available = 3
          mfpt.quantity_bought = 2
          mfpt.buyer = User.new id: 1
          mfpt.article = Article.new
        end

        it "should create a new PartialFixedPriceTransaction with the correct data" do
          PartialFixedPriceTransaction.any_instance.stub(:buy)
          PartialFixedPriceTransaction.any_instance.should_receive(:save!).and_return(true)
          #...
          mfpt.send(:buy_multiple_transaction)
        end

        it "should trigger the buy event on the new PartialFixedPriceTransaction" do
          mfpt.save
          PartialFixedPriceTransaction.any_instance.stub(:save!)
          mfpt.stub(:save!)
          PartialFixedPriceTransaction.any_instance.should_receive(:buy).and_return(true)
          mfpt.send(:buy_multiple_transaction)
        end
      end
    end

    # describe "#quantity_param_valid?" do
    #   it "should return true by default" do
    #     mfpt.send(:quantity_param_valid?, {'transaction' => {'quantity_bought' => nil}}).should be_true
    #   end

    #   it "should add an error and return false when quantity_bought is larger than quantity_available" do
    #     mfpt.quantity_available = 9
    #     mfpt.send(:quantity_param_valid?, {'transaction' => {'quantity_bought' => '10'}}).should be_false
    #     mfpt.errors.full_messages.should include('Quantity bought '+I18n.t('transaction.errors.too_many_bought', available: 9))
    #   end
    # end
  end
end

describe SingleFixedPriceTransaction do
  let(:fpt) { SingleFixedPriceTransaction.new }

  it "should have a valid factory" do
    expect {
      FactoryGirl.create :single_transaction
    }.to change(Transaction, :count).by 1
    t = Transaction.last
    t.type.should eq "SingleFixedPriceTransaction"
    t.article.should be_an Article
    t.article_quantity.should eq 1
  end

  it "should be generated with an article that has a quantity one" do
    expect {
      FactoryGirl.create :article
    }.to change(Transaction, :count).by 1
    Article.last.transaction.should be_a SingleFixedPriceTransaction
  end

  describe "attributes" do
    it { should respond_to 'quantity_bought' }
    it "should read quantity_bought, and it should always be one" do
      fpt.send(:quantity_bought=, 3)
      fpt.send(:quantity_bought).should eq 1
    end
  end

  describe "methods" do
    describe "#total_price" do
      it "should forward the call to article" do
        fpt.article = Article.new
        fpt.article.should_receive(:total_price)
        fpt.total_price
      end
    end
  end

  # describe "validations" do
  #   subject { FactoryGirl.create :single_transaction }
  #   it { should validate_numericality_of 'quantity_bought' }
  # end
end
