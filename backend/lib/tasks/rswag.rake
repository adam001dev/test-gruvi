# frozen_string_literal: true

Rake::Task["rswag:specs:swaggerize"].clear if Rake::Task.task_defined?("rswag:specs:swaggerize")

namespace :rswag do
  namespace :specs do
    desc "Generate Swagger JSON files from integration specs"
    task swaggerize: :environment do
      ENV["RAILS_ENV"] ||= "test"

      require "rspec/core"
      require "rswag/specs"

      $LOAD_PATH.unshift(Rails.root.join("spec").to_s)
      require_relative Rails.root.join("spec", "spec_helper")
      require_relative Rails.root.join("spec", "rails_helper")
      require_relative Rails.root.join("spec", "swagger_helper")

      RSpec::Core::RakeTask.new(:swaggerize) do |t|
        t.pattern = "spec/swagger/**/*_spec.rb"
        t.rspec_opts = [ "--format Rswag::Specs::SwaggerFormatter", "--order defined" ]
      end

      Rake::Task["swaggerize"].invoke
    end
  end
end
