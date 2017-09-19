require "spec_helper"


RSpec.describe 'bin/cov' do
  it 'run `bin/cov if 0` successfully' do
    command_success = system({"DISABLE_PRY" => "1"}, "bin/cov if 0", in: File::NULL, out: File::NULL, err: File::NULL)
    command_success.should be true
  end
end
