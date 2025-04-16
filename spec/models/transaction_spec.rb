require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe "validations" do
    it { should belong_to(:user) }
    it { should belong_to(:asset) }
    it { should validate_presence_of(:transaction_type) }
    it { should validate_presence_of(:quantity) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
    it { should validate_inclusion_of(:transaction_type).in_array(Transaction::TYPES.values) }
  end

  describe "callbacks" do
    describe "after_create" do
      let(:user) { create(:user) }
      let(:asset) { create(:asset, user: user, quantity: 10, purchase_price: 100) }

      context "with existing transactions" do
        before do
          # Create a previous transaction for the asset so it's not the first one
          create(:transaction, user: user, asset: asset, transaction_type: "buy", quantity: 1, price: 100)
        end

        it "updates asset quantity for buy transaction" do
          transaction = build(:transaction, user: user, asset: asset, transaction_type: "buy", quantity: 5, price: 120)
          
          expect {
            transaction.save
          }.to change { asset.reload.quantity }.from(10).to(15)
        end

        it "updates asset quantity for sell transaction" do
          transaction = build(:transaction, user: user, asset: asset, transaction_type: "sell", quantity: 5, price: 120)
          
          expect {
            transaction.save
          }.to change { asset.reload.quantity }.from(10).to(5)
        end

        it "raises an error when selling more than available" do
          transaction = build(:transaction, user: user, asset: asset, transaction_type: "sell", quantity: 15, price: 120)
          
          # We need to setup the transaction to actually trigger the quantity check
          expect {
            # Save with bang to ensure the exception is raised
            transaction.save!
          }.to raise_error(ActiveRecord::RecordInvalid, /Insufficient asset quantity/)
        end
      end

      context "with first transaction" do
        it "doesn't update asset for the first transaction" do
          # Create a new asset with no transactions
          new_asset = create(:asset, user: user, quantity: 0, purchase_price: 0)
          
          transaction = build(:transaction, user: user, asset: new_asset, transaction_type: "buy", quantity: 5, price: 120)
          
          # The key here is NOT mocking is_first_transaction?
          # Let the real method determine if it's the first transaction
          expect {
            transaction.save
          }.not_to change { new_asset.reload.quantity }
        end
      end
    end
  end

  describe "#calculate_new_average_price" do
    let(:user) { create(:user) }
    
    context "with buy transactions" do
      it "calculates weighted average for buy transactions" do
        # Create a new asset with known values
        asset = create(:asset, user: user, quantity: 10, purchase_price: 100)
        
        # Use explicit typecasting to ensure decimal precision
        transaction = Transaction.new(
          user: user,
          asset: asset,
          transaction_type: "buy",
          quantity: 5.0,
          price: 200.0
        )
        
        # Instead of expecting a specific value, verify the formula is correct
        # Formula: (10 * 100 + 5 * 200) / 15 = (1000 + 1000) / 15 = 2000 / 15 = ~133.33
        expected_value = (asset.quantity * asset.purchase_price + transaction.quantity * transaction.price) / 
                        (asset.quantity + transaction.quantity)
                            
        # Now compare with what the actual method returns
        calculated_price = transaction.send(:calculate_new_average_price)
        expect(calculated_price).to eq(expected_value)
      end
    end
    
    context "with sell transactions" do
      it "returns the transaction price for sell transactions" do
        # Create a new asset with known values
        asset = create(:asset, user: user, quantity: 10, purchase_price: 100)
        
        transaction = Transaction.new(
          user: user,
          asset: asset,
          transaction_type: "sell",
          quantity: 5,
          price: 200
        )
        
        # For sell transactions, we expect the price to be returned, not the asset purchase price
        expect(transaction.send(:calculate_new_average_price)).to eq(200)
      end
    end
    
    context "with zero asset quantity" do
      it "returns the transaction price" do
        # Create a new asset with zero quantity
        asset = create(:asset, user: user, quantity: 0, purchase_price: 0)
        
        transaction = Transaction.new(
          user: user,
          asset: asset,
          transaction_type: "buy",
          quantity: 5,
          price: 200
        )
        
        expect(transaction.send(:calculate_new_average_price)).to eq(200)
      end
    end
  end
end
