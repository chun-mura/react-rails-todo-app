require 'rails_helper'

RSpec.describe User, type: :model do
  subject { create(:user) }

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_presence_of(:password) }
  end

  describe 'associations' do
    it { should have_many(:todos) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end
end
