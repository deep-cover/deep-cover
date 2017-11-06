require "rails_helper"

RSpec.describe User do
  it 'can be created' do
    u = User.new(name: 'hi')

    expect(u.save!).to be(true)
  end
  it 'foos' do
    u = User.new(name: 'hi')

    expect(u.foo).to be(42)
  end
  it 'bazzes' do
    u = User.new(name: 'hi')

    expect(u.baz).to be(42)
  end
end
