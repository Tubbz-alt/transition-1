require 'spec_helper'
require 'transition/import/organisations'
require 'transition/import/sites'

describe Transition::Import::Organisations do
  describe '.from_whitehall!', testing_before_all: true do
    before :all do
      Transition::Import::Organisations.from_whitehall!(
        Transition::Import::WhitehallOrgs.new('spec/fixtures/whitehall/orgs_abridged.yml')
      )
    end

    it 'has imported orgs - one per org in orgs_abridged.yml' do
      Organisation.count.should == 6
    end

    describe 'an organisation with multiple parents' do
      let(:bis) { Organisation.find_by_whitehall_slug('department-for-business-innovation-skills') }
      let(:fco) { Organisation.find_by_whitehall_slug('foreign-commonwealth-office') }

      subject(:ukti) { Organisation.find_by_whitehall_slug('uk-trade-investment') }

      its(:abbreviation)   { should eql 'UKTI' }
      its(:content_id)     { should eql '8ded75c7-29ea-4831-958c-4f07fd73425d'}
      its(:whitehall_slug) { should eql 'uk-trade-investment' }
      its(:whitehall_type) { should eql 'Non-ministerial department' }
      its(:homepage)       { should eql 'https://www.gov.uk/government/organisations/uk-trade-investment' }

      its(:parent_organisations) { should =~ [bis, fco] }
    end

    describe 'fudged CSS/URL details' do
      subject(:ago) { Organisation.find_by_whitehall_slug('attorney-generals-office') }

      its(:css)  { should eql 'attorney-generals-office' }
      its(:furl) { should eql 'www.gov.uk/ago' }
    end

  end
end
