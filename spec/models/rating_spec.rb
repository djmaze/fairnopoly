require 'spec_helper'

describe Rating do
   describe "model attributes" do
    it { should respond_to :rating }
    it { should respond_to :rated_user_id }
    it { should respond_to :text }
    it { should respond_to :transaction_id }
  end

  describe "associations" do
    it { should belong_to :transaction }
    it { should belong_to :rated_user  }
  end

  describe "enumerization" do
    it { should enumerize(:rating).in(:positive, :neutral, :negative) }
  end
end