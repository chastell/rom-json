require 'spec_helper'

require 'rom/lint/spec'

describe 'YAML adapter' do
  subject(:rom) { setup.finalize }

  let(:root) { Pathname(__FILE__).dirname.join('..') }

  let(:path) { "#{root}/fixtures/test_db.yml" }
  let(:setup) { ROM.setup(:yaml, path) }

  before do
    setup.relation(:users) do
      def by_name(name)
        restrict(name: name)
      end
    end

    setup.mappers do
      define(:users) do
        register_as :entity

        model name: 'User'

        attribute :name
        attribute :email

        embedded :roles, type: :array do
          attribute :name, from: 'role_name'
        end
      end
    end
  end

  describe 'env#relation' do
    it 'returns mapped object' do
      jane = rom.relation(:users).as(:entity).by_name('Jane').first

      expect(jane.name).to eql('Jane')
      expect(jane.email).to eql('jane@doe.org')
      expect(jane.roles.length).to eql(2)
      expect(jane.roles).to eql([
        { name: 'Member' }, { name: 'Admin' }
      ])
    end
  end

  describe 'multi-file setup' do
    it 'uses one-file-per-relation' do
      setup = ROM.setup(:yaml, "#{root}/fixtures/db")

      setup.relation(:users)
      setup.relation(:tasks)

      rom = setup.finalize

      expect(rom.relation(:users)).to match_array([
        { name: 'Jane', email: 'jane@doe.org' }
      ])

      expect(rom.relation(:tasks)).to match_array([
        { title: 'Task One' },
        { title: 'Task Two' },
        { title: 'Task Three' }
      ])
    end
  end
end
