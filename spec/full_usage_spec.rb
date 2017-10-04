require "spec_helper"

RSpec.describe 'DeepCover usage' do
  it 'run `ruby spec/full_usage/simple/simple.rb` successfully' do
    reader, writer = IO.pipe
    options = {4 => writer.fileno, in: File::NULL, out: File::NULL, err: File::NULL}

    pid = spawn('ruby', 'spec/full_usage/simple/simple.rb', '4', options)
    writer.close
    problems = reader.read
    Process.wait(pid)
    exit_code = $?.exitstatus
    reader.close

    if problems.empty?
      fail "Test program should have returned something but didn't"
    elsif problems != "Done\n"
      fail "Received unexpected message from test program:\n#{problems}"
    end
    exit_code.should be 0
  end
end
