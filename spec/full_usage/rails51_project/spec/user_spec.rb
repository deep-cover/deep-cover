require "rails_helper"


RSpec.describe User do
  it 'can be created' do
    u = User.new(name: 'hi')

    expect(u.save!).to be(true)
  end
end
