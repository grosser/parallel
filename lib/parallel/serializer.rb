# frozen_string_literal: true
require 'openssl'
require 'securerandom'

module Parallel
  # Pluggable wire serializers. Each must respond to `dump(data, io)` /
  # `load(io)` (used directly by Worker) and `dump(data)` / `load(string)`
  # (used by wrappers like Hmac).
  module Serializer
    # Raw Marshal. Fast but trusts anything written to the pipe — a same-UID
    # attacker that reopens /proc/<pid>/fd/<n> can inject Marshal gadgets (RCE).
    Marshal = ::Marshal

    # Wraps any inner serializer with a length-prefixed HMAC-SHA256 frame keyed
    # on a per-worker secret generated before fork. Forged frames from a
    # pipe-injector fail verification.
    class Hmac
      LENGTH_FORMAT = 'N' # 32-bit big-endian unsigned int
      LENGTH_BYTES = 4
      MAC_BYTES = 32 # SHA256

      def initialize(inner: Marshal, secret: SecureRandom.bytes(32))
        @inner = inner
        @secret = secret
      end

      def dump(data, io)
        payload = @inner.dump(data)
        mac = OpenSSL::HMAC.digest('SHA256', @secret, payload)
        io.write([payload.bytesize].pack(LENGTH_FORMAT), mac, payload)
      end

      def load(io)
        # nil at frame boundary = clean EOF (worker died / pipe closed between messages)
        header = io.read(LENGTH_BYTES) || raise(EOFError) # eof stops worker
        raise SecurityError, "truncated frame header" if header.bytesize != LENGTH_BYTES

        length = header.unpack1(LENGTH_FORMAT)
        mac = io.read(MAC_BYTES)
        raise SecurityError, "truncated frame mac" if mac.nil? || mac.bytesize != MAC_BYTES

        payload = io.read(length)
        raise SecurityError, "truncated frame payload" if payload.nil? || payload.bytesize != length

        expected = OpenSSL::HMAC.digest('SHA256', @secret, payload)
        raise SecurityError, "HMAC mismatch on worker pipe" unless OpenSSL.fixed_length_secure_compare(mac, expected)

        @inner.load(payload)
      end
    end
  end
end
