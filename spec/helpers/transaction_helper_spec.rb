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
require "spec_helper"

describe TransactionHelper do
  describe "#display_optional_warning" do
    it "should return nil when 'pickup' wasn't selected" do
      helper.stub(:resource).and_return(FactoryGirl.build(:transaction, article: FactoryGirl.create(:article, :with_all_transports, :with_all_payments)))
      helper.display_optional_warning('type1', 'paypal').should be_nil
    end

    it "should return nil when 'pickup' and 'cash' were selected" do
      helper.stub(:resource).and_return(FactoryGirl.build(:transaction, article: FactoryGirl.create(:article, :with_all_transports, :with_all_payments)))
      helper.display_optional_warning('pickup', 'cash').should be_nil
    end

    it "should return nil when 'cash' isn't selectable" do
      helper.stub(:resource).and_return(FactoryGirl.build(:transaction, article: FactoryGirl.create(:article, payment_cash: false, payment_invoice: true)))
      helper.display_optional_warning('pickup', 'bank_transfer').should be_nil
    end

    it "should return something when 'pickup' was selected but 'cash' wasn't (but is a possibility)" do
      helper.stub(:resource).and_return(FactoryGirl.build(:transaction, article: FactoryGirl.create(:article, :with_all_transports, :with_all_payments)))
      helper.display_optional_warning('pickup', 'bank_transfer').should be_a String
    end
  end

  describe "#display_price_list_item" do
    it "should display transport per number on MultipleFixedPriceTransactions" do
     helper.stub(:resource).and_return(FactoryGirl.build(:multiple_transaction, article: FactoryGirl.create(:article, :with_all_transports, :with_all_payments)))
     helper.display_price_list_item(:transport,:type1).should be_a String

    end
  end

end
