describe ManageIQ::Providers::Autosde::StorageManager::VolumeMapping do
  describe 'mutual exclusive of host_initiator and host_initiator_group' do
    it 'validates both reference present ' do
      record = described_class.new
      host_initiator = HostInitiator.new
      record.host_initiator = host_initiator
      host_initiator_group = HostInitiatorGroup.new
      record.host_initiator_group = host_initiator_group
      record.validate
      expect(record.errors[:mapping_object]).to_not be_empty
    end
    it 'validates only host_initiator reference present ' do
      record = described_class.new
      host_initiator = HostInitiator.new
      record.host_initiator = host_initiator
      record.validate
      expect(record.errors[:mapping_object]).to be_empty
    end
    it 'validates only host_initiator_group reference present ' do
      record = described_class.new
      host_initiator_group = HostInitiatorGroup.new
      record.host_initiator_group = host_initiator_group
      record.validate
      expect(record.errors[:mapping_object]).to be_empty
    end
  end
end
