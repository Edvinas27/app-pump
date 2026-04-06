# frozen_string_literal: true

class JsonWebToken
  ALGORITHM = "HS256"

  def self.encode(payload = {}, exp: 7.days.from_now, **extra_payload)
    payload = payload.to_h.merge(extra_payload)
    payload[:exp] = exp.to_i

    JWT.encode(payload, secret_key, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })
    decoded.first.with_indifferent_access
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def self.secret_key
    Rails.application.secret_key_base
  end
end
