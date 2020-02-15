module Fixtures
  class << self
    def setup(scope)
      up_schemata
      scope.class_eval FIXTURE
      YARD.parse_string FIXTURE
    end

    def teardown
      down_schemata
      YARD::Registry.clear
    end

    private

    def up_schemata
      ActiveRecord::Base.establish_connection(
        adapter:  "sqlite3",
        database: ":memory:",
      )
      m = ActiveRecord::Migration.new
      m.verbose = false
      m.create_table :users do |t|
        t.string :name
        t.boolean :registered
        t.boolean :deleted
      end
      m.create_table :admin_logs do |t|
        t.integer :user_id
        t.boolean :checked
        t.string :data
        t.datetime :created_at
      end
    end

    def down_schemata
      m = ActiveRecord::Migration.new
      m.verbose = false
      m.drop_table :users
      m.drop_table :admin_logs
    end

    FIXTURE = <<~RUBY.freeze
      class ApplicationRecord < ActiveRecord::Base
        self.abstract_class = true
      end

      # @!record
      class User < ApplicationRecord
        # @!paranoid deleted
        acts_as_paranoid column: :deleted, sentinel_value: false

        # @!scoping registered
        # Lists registered users.
        scope :registered, -> { where(registered: true) }
      end

      module Admin
        def self.table_name_prefix
          'admin_'
        end
      end

      # @!record
      class Admin::Log < ApplicationRecord
        # @!scoping unchecked
        # List operation logs that has not checked yet
        scope :unchecked, -> { where(checked: false) }
      end
    RUBY
  end
end
