# frozen_string_literal: true

require "openssl"
require "fileutils"
require "securerandom"

# In-test X.509 material for the mutual-TLS crossing tests (spec
# 8xa.t.nh0). These are THROWAWAY TEST CERTIFICATES minted in-process —
# never deployment credentials; production material is provisioned by
# lab-config (gad.8) alone.
module TlsFixtures
  CA = Struct.new(:cert, :key).freeze
  Identity = Struct.new(:cert, :key, :chain).freeze

  module_function

  # Unique subject per CA: OpenSSL selects issuer certs by subject, so
  # two same-subject CAs in one process poison each other's trust paths.
  def mint_ca(cn: "ace-hitl test CA #{SecureRandom.hex(8)}")
    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    subject = OpenSSL::X509::Name.parse_rfc2253("CN=#{cn}")
    cert.subject = subject
    cert.issuer = subject
    cert.not_before = Time.now - 60
    cert.not_after = Time.now + 3600
    cert.public_key = key.public_key
    cert.serial = 1
    cert.version = 2
    builder = factory_for(cert, cert)
    cert.add_extension(builder.create_extension("basicConstraints", "CA:TRUE", true))
    cert.add_extension(builder.create_extension("keyUsage", "keyCertSign,cRLSign", true))
    cert.sign(key, OpenSSL::Digest.new("SHA256"))
    CA.new(cert, key)
  end

  # uri_sans: array of URI SAN strings (the certificate identity);
  # dns_names: DNS SANs for the host-tailnet identity;
  # eku: "serverAuth", "clientAuth" or nil; expired: shift the window.
  def mint_identity(ca:, uri_sans: [], dns_names: [], eku: nil, not_after: 3600, not_before: -60,
    serial: nil)
    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    subject = OpenSSL::X509::Name.parse_rfc2253("CN=#{uri_sans.first || dns_names.first || "ace-hitl test"}")
    cert.subject = subject
    cert.issuer = ca.cert.subject
    cert.not_before = Time.now + not_before
    cert.not_after = Time.now + not_after
    cert.public_key = key.public_key
    cert.serial = serial || rand(2..2_147_483_647)
    cert.version = 2
    builder = factory_for(cert, ca.cert)
    cert.add_extension(builder.create_extension("basicConstraints", "CA:FALSE", true))
    cert.add_extension(builder.create_extension("keyUsage", "digitalSignature,keyEncipherment", true))
    cert.add_extension(builder.create_extension("subjectAltName",
      (uri_sans.map { |s| "URI:#{s}" } + dns_names.map { |d| "DNS:#{d}" }).join(","))) if uri_sans.any? || dns_names.any?
    cert.add_extension(builder.create_extension("extendedKeyUsage", eku)) if eku
    cert.sign(ca.key, OpenSSL::Digest.new("SHA256"))
    Identity.new(cert, key, [ca.cert])
  end

  def pem_chain(identity)
    identity.chain.map(&:to_pem).join
  end

  def fingerprint(cert)
    Ace::Hitl::Lifecycle::TlsCredentials.sha256_fingerprint(cert)
  end

  def factory_for(cert, issuer)
    OpenSSL::X509::ExtensionFactory.new.tap do |factory|
      factory.subject_certificate = cert
      factory.issuer_certificate = issuer
    end
  end

  # Writes a leaf file (cert + chain) and a key file, returning their
  # paths — layout modes are NOT applied here; CredentialPathPolicy
  # fixtures apply the exact provisioning layout themselves.
  def write_identity(directory, prefix:, identity:, ca_pem: nil)
    FileUtils.mkdir_p(directory)
    cert_path = File.join(directory, "#{prefix}.pem")
    key_path = File.join(directory, "#{prefix}-key.pem")
    File.write(cert_path, identity.cert.to_pem + pem_chain(identity))
    File.write(key_path, identity.key.to_pem)
    ca_path = nil
    if ca_pem
      ca_path = File.join(directory, "#{prefix}-ca.pem")
      File.write(ca_path, ca_pem)
    end
    [cert_path, key_path, ca_path]
  end
end
