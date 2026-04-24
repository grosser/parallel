# frozen_string_literal: true
require 'spec_helper'
require 'json'

describe Parallel::Serializer do
  describe Parallel::Serializer::Hmac do
    let(:serializer) { described_class.new }

    def with_pipe
      read, write = IO.pipe
      yield read, write
    ensure
      read.close unless read.closed?
      write.close unless write.closed?
    end

    def pipe_round_trip(serializer, data)
      with_pipe do |read, write|
        serializer.dump(data, write)
        write.close
        return serializer.load(read)
      end
    end

    it "round-trips a simple value" do
      pipe_round_trip(serializer, "hello").should == "hello"
    end

    it "round-trips a complex value" do
      data = { a: [1, 2, 3], b: { c: "x" }, d: Set.new([1, 2]) }
      pipe_round_trip(serializer, data).should == data
    end

    it "round-trips multiple messages" do
      with_pipe do |read, write|
        [1, "two", [3, 4], { five: 5 }].each { |m| serializer.dump(m, write) }
        write.close
        [1, "two", [3, 4], { five: 5 }].each do |expected|
          serializer.load(read).should == expected
        end
        read.eof?.should == true
      end
    end

    it "rejects payloads signed with a different secret" do
      with_pipe do |read, write|
        described_class.new.dump("HACKERMAN", write)
        write.close
        -> { serializer.load(read) }.should raise_error(SecurityError, /HMAC mismatch/)
      end
    end

    it "rejects payloads with a tampered body" do
      frame = with_pipe do |read, write|
        serializer.dump("untampered", write)
        write.close
        read.read
      end
      tampered = frame.dup
      tampered[-1] = (tampered[-1].ord ^ 0x01).chr

      with_pipe do |read, write|
        write.write(tampered)
        write.close
        -> { serializer.load(read) }.should raise_error(SecurityError, /HMAC mismatch/)
      end
    end

    it "raises SecurityError on a truncated frame" do
      frame = with_pipe do |read, write|
        serializer.dump("whatever", write)
        write.close
        read.read
      end

      with_pipe do |read, write|
        write.write(frame[0, frame.bytesize - 5]) # drop last 5 bytes of payload
        write.close
        -> { serializer.load(read) }.should raise_error(SecurityError, /truncated frame/)
      end
    end

    it "raises EOFError on a cleanly closed empty pipe (worker death, not tampering)" do
      with_pipe do |read, write|
        write.close
        -> { serializer.load(read) }.should raise_error(EOFError)
      end
    end

    it "works end-to-end" do
      items = (1..20).to_a
      result = Parallel.map(items, in_processes: 3, serializer: serializer) { |i| i * 10 }
      result.should == items.map { |i| i * 10 }
    end

    it "propagates worker exceptions across the HMAC frame" do
      lambda {
        Parallel.map([1, 2, 3], in_processes: 2, serializer: serializer) { |i| raise "boom-#{i}" } # rubocop:disable Lint/UnreachableLoop
      }.should raise_error(RuntimeError, /boom-\d/)
    end

    it "round-trips large payloads (bigger than a pipe buffer)" do
      size = 200_000 # > typical 64KiB pipe buffer
      big = "x" * size
      result = Parallel.map([1, 2, 3], in_processes: 2, serializer: serializer) { |i| [i, big] }
      result.map { |i, s| [i, s == big] }.should == [[1, true], [2, true], [3, true]]
    end

    it "supports a custom inner serializer" do
      pipe_round_trip(described_class.new(inner: JSON), [1, :a, 3]).should == [1, "a", 3]
    end
  end
end
