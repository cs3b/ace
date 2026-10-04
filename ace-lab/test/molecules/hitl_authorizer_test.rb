# frozen_string_literal: true

require_relative "../test_helper"

# The lab-side HITL delivery authorization (spec 8wq.t.34i): transport
# authority is uid-exact, project-scoped by the trusted principals, and
# derived only from the trusted deployment document.
module Molecules
  class HitlAuthorizerTest < Minitest::Test
        def document
          {
            "hitl" => {"service_uid" => 4210, "transport_uids" => [4211, 4212]},
            "authorization" => {
              "principals" => {
                "4211" => {"projects" => ["ace"]},
                "4212" => {"projects" => ["other"]}
              }
            }
          }
        end

        def authorizer
          Ace::Lab::Molecules::HitlAuthorizer.new(
            principals: document.dig("authorization", "principals"),
            transport_uids: [4211, 4212],
            service_uid: 4210
          )
        end

        def test_transport_may_deliver_only_for_its_visible_projects
          assert authorizer.delivery_authorized?(uid: 4211, project_id: "ace")
          refute authorizer.delivery_authorized?(uid: 4211, project_id: "other")
          assert authorizer.delivery_authorized?(uid: 4212, project_id: "other")
        end

        def test_unknown_uids_and_missing_principals_authorize_nothing
          refute authorizer.delivery_authorized?(uid: 9999, project_id: "ace")
          # A transport uid with no principal at all is nobody.
          scoped = Ace::Lab::Molecules::HitlAuthorizer.new(principals: {}, transport_uids: [4211])
          refute scoped.delivery_authorized?(uid: 4211, project_id: "ace")
        end

        def test_service_uid_must_be_an_integer
          assert_equal 4210, authorizer.service_uid
          assert_nil Ace::Lab::Molecules::HitlAuthorizer.new(service_uid: "4210").service_uid
          assert_nil Ace::Lab::Molecules::HitlAuthorizer.new.service_uid
        end

        def test_from_trusted_document_reads_the_shared_format
          loader = Object.new
          doc = document
          loader.define_singleton_method(:trusted_document) { |_path| doc }
          resolved = Ace::Lab::Molecules::HitlAuthorizer.from_trusted_document("/etc/lab/ace-lab/authorization.yml", loader)
          assert_equal 4210, resolved.service_uid
          assert resolved.delivery_authorized?(uid: 4211, project_id: "ace")
        end
  end
end
