require_relative 'inferno_template/patient_group'

module InfernoTemplate
  class Suite < Inferno::TestSuite
    id :test_suite_template
    title 'Inferno Test Suite Template'
    description 'A basic test suite template for Inferno'

    # These inputs will be available to all tests in this suite
    input :url, :access_token,
          title: 'FHIR Server Base Url'

    input :credentials,
          title: 'OAuth Credentials',
          type: :oauth_credentials,
          optional: true

    # All FHIR requests in this suite will use this FHIR client
    fhir_client do
      url :url
      bearer_token :access_token 
      oauth_credentials :credentials
    end

    # All FHIR validation requests will use this FHIR validator
    validator do
      url ENV.fetch('VALIDATOR_URL')
    end

    # Tests and TestGroups can be defined inline
    group do
      id :capability_statement
      title 'Capability Statement'
      description 'Verify that the server has a CapabilityStatement'

      test do
        id :capability_statement_read
        title 'Read CapabilityStatement'
        description 'Read CapabilityStatement from /metadata endpoint'

        run do
          fhir_get_capability_statement

          assert_response_status(200)
          assert_resource_type(:capability_statement)
        end
      end
    end

    # Tests and TestGroups can be written in separate files and then included
    # using their id
    group from: :patient_group

    group do
      id :condition
      title 'Condition'

      input :patient_id

      test do
        id :condition_search_by_patient
        title 'Condition Search by patient'
        makes_request :condition_patient_search

        run do
          fhir_search('Condition', params: { patient: patient_id}, name: :condition_patient_search)

          assert_response_status(200)
          assert_resource_type('Bundle')
        end
      end

      test do
        id :condition_bundle_validation
        title 'Condition Bundle is Valid'
        uses_request :condition_patient_search

        run do
          assert_valid_bundle_entries(
            resource_types: {
              'Condition': 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'
            }
          )
        end
      end
    end

    group do
      id :vital_signs
      title 'Vital Signs'

      input :patient_id

      test do
        id :vital_signs_search_by_patient
        title 'Vital Signs Search by patient'
        makes_request :vital_signs_patient_search

        run do
          fhir_search('Observation', params: { patient: patient_id, category: 'vital-signs' }, name: :vital_signs_patient_search)

          assert_response_status(200)
          assert_resource_type('Bundle')
        end
      end

      test do
        id :vital_signs_bundle_validation
        title 'Vital Signs Bundle is Valid'
        uses_request :vital_signs_patient_search

        run do
          assert_valid_bundle_entries(
            resource_types: {
              'Observation': 'http://hl7.org/fhir/StructureDefinition/Observation'
            }
          )
        end
      end
    end
  end
end
