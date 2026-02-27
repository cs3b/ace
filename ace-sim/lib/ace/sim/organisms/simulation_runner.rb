# frozen_string_literal: true

module Ace
  module Sim
    module Organisms
      class SimulationRunner
        def initialize(source_resolver: nil, session_store: nil, stage_executor: nil, synthesis_builder: nil)
          @source_resolver = source_resolver || Molecules::SourceResolver.new
          @session_store = session_store || Molecules::SessionStore.new
          @stage_executor = stage_executor || Molecules::StageExecutor.new
          @synthesis_builder = synthesis_builder || Molecules::SynthesisBuilder.new
        end

        def run(session)
          resolved_source = source_resolver.resolve(session.source)
          run_id, run_dir = prepare_unique_run(session)

          chains = []
          session.providers.each do |provider|
            1.upto(session.repeat) do |iteration|
              chains << run_chain(
                session: session,
                run_dir: run_dir,
                provider: provider,
                iteration: iteration,
                resolved_source: resolved_source
              )
            end
          end

          synthesis = synthesis_builder.build(
            session: session,
            resolved_source: resolved_source,
            chains: chains
          )
          session_store.write_synthesis(run_dir, synthesis)

          session_store.write_session(
            run_dir,
            session.to_h.merge(
              "run_id" => run_id,
              "resolved_source" => resolved_source,
              "status" => synthesis["status"],
              "chain_count" => chains.length,
              "writeback_applied" => false
            )
          )

          {
            success: synthesis["status"] != "failed",
            status: synthesis["status"],
            run_id: run_id,
            run_dir: run_dir,
            chains: chains,
            synthesis: synthesis,
            error: synthesis["status"] == "failed" ? "All chains failed" : nil
          }
        rescue Ace::Sim::ValidationError => e
          {
            success: false,
            status: "failed",
            run_id: session.run_id,
            run_dir: nil,
            chains: [],
            synthesis: nil,
            error: e.message
          }
        rescue StandardError => e
          {
            success: false,
            status: "failed",
            run_id: session.run_id,
            run_dir: nil,
            chains: [],
            synthesis: nil,
            error: "#{e.class}: #{e.message}"
          }
        end

        private

        attr_reader :source_resolver, :session_store, :stage_executor, :synthesis_builder

        def run_chain(session:, run_dir:, provider:, iteration:, resolved_source:)
          current_input_path = resolved_source.fetch("path")
          step_results = []

          session.steps.each_with_index do |step, index|
            step_dir = session_store.prepare_step_dir(run_dir, provider, iteration, index + 1, step)
            result = stage_executor.execute(
              step: step,
              provider: provider,
              iteration: iteration,
              step_dir: step_dir,
              step_bundle_path: session.bundle_path_for(step),
              input_source_path: current_input_path
            )

            step_results << result
            break if result["status"] == "failed"

            current_input_path = result["output_path"]
          end

          {
            "provider" => provider,
            "iteration" => iteration,
            "status" => synthesis_builder.chain_status(step_results),
            "steps" => step_results
          }
        end

        def prepare_unique_run(session)
          attempts = 0
          begin
            attempts += 1
            run_dir = session_store.prepare_run(session.run_id)
            [session.run_id, run_dir]
          rescue Molecules::SessionStore::RunDirectoryExistsError
            raise Ace::Sim::ValidationError, "Could not allocate unique run id" if attempts >= 5

            session.regenerate_run_id!
            retry
          end
        end
      end
    end
  end
end
