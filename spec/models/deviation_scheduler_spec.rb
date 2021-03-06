require 'spec_helper'

shared_examples 'a deviation scheduler' do
  let(:scheduler) { create(described_class.to_s.underscore.to_sym) }

  context 'asserting that profile_associator is triggered' do
    before do
      ProfileAssociator.should_receive(:perform_async).twice
    end

    describe '#add_deviating_strategy' do
      it 'triggers the profile_associator after adding deviating strategy' do
        scheduler.add_role('All', 2)
        scheduler.add_deviating_strategy('All', 'A')
        expect(scheduler.reload.roles.first.deviating_strategies).to eq(%w(A))
      end
    end

    describe '#remove_deviating_strategy' do
      it 'triggers the profile_associator' do
        scheduler.roles.create!(name: 'All', count: 2, reduced_count: 2,
                                deviating_strategies: %w(A B))
        scheduler.remove_deviating_strategy('All', 'B')
        expect(scheduler.reload.roles.first.deviating_strategies).to eq(%w(A))
      end
    end
  end
end

describe DeviationScheduler do
  it_behaves_like 'a deviation scheduler'

  describe '#profile_space' do
    it 'returns an array of profiles consistent with the current roles' do
      ProfileAssociator.stub(:perform_async)
      scheduler = create(:deviation_scheduler, size: 3)
      scheduler.add_role('A', 2)
      scheduler.add_role('B', 1)
      scheduler.add_strategy('A', 'S2')
      scheduler.add_strategy('B', 'S3')
      scheduler.add_strategy('B', 'S1')
      scheduler.add_deviating_strategy('A', 'S4')
      expect(scheduler.reload.profile_space.sort)
        .to eq(['A: 2 S2; B: 1 S3', 'A: 2 S2; B: 1 S1',
                'A: 1 S2, 1 S4; B: 1 S3', 'A: 1 S2, 1 S4; B: 1 S1'].sort)
    end
  end
end

describe DprDeviationScheduler do
  it_behaves_like 'a deviation scheduler'
end

describe HierarchicalDeviationScheduler do
  it_behaves_like 'a deviation scheduler'
end
