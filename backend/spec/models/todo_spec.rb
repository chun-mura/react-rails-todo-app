require 'rails_helper'

RSpec.describe Todo, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:todo)).to be_valid
    end
  end

  describe 'default values' do
    it 'sets completed to false by default' do
      todo = create(:todo)
      expect(todo.completed).to be false
    end
  end
end
