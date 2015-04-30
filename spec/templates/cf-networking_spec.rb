describe "cf-networking.yml" do
  subject do
    spiff_merge(template_path("cf-networking.yml"), stub)
  end

  context "using defaults" do
    let(:stub) do
      <<-STUB.strip_heredoc
        meta:
          networks:
            cf1:
              net_id: foo
            cf2:
              net_id: bar
      STUB
    end

    its([:networks, :cf1, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: foo
            subnet: foo
            security_groups: ~
            availability_zone: ~
          dns: ~
          gateway: 10.10.1.1
          name: default_unused
          range: 10.10.1.0/24
          reserved:
          - 10.10.1.2 - 10.10.1.5
          static:
          - 10.10.1.6 - 10.10.1.50
      RESULT
    end

    its([:networks, :cf2, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: bar
            subnet: bar
            security_groups: ~
            availability_zone: ~
          dns: ~
          gateway: 10.10.2.1
          name: default_unused
          range: 10.10.2.0/24
          reserved:
          - 10.10.2.2 - 10.10.2.5
          static:
          - 10.10.2.6 - 10.10.2.50
      RESULT
    end
  end

  context "using different shared networking setting" do
    let(:stub) do
      <<-STUB.strip_heredoc
        meta:
          networks:
            ipmask: "10.11"
            dns: [ 8.8.8.8 ]
            security_groups: [ foo, bar ]
            cf1:
              net_id: foo
            cf2:
              net_id: bar
      STUB
    end

    its([:networks, :cf1, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: foo
            subnet: foo
            security_groups: [ foo, bar ]
            availability_zone: ~
          dns: [ 8.8.8.8 ]
          gateway: 10.11.1.1
          name: default_unused
          range: 10.11.1.0/24
          reserved:
          - 10.11.1.2 - 10.11.1.5
          static:
          - 10.11.1.6 - 10.11.1.50
      RESULT
    end

    its([:networks, :cf2, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: bar
            subnet: bar
            security_groups: [ foo, bar ]
            availability_zone: ~
          dns: [ 8.8.8.8 ]
          gateway: 10.11.2.1
          name: default_unused
          range: 10.11.2.0/24
          reserved:
          - 10.11.2.2 - 10.11.2.5
          static:
          - 10.11.2.6 - 10.11.2.50
      RESULT
    end
  end

  context "using different network quad" do
    let(:stub) do
      <<-STUB.strip_heredoc
        meta:
          networks:
            ipmask: "10.11"
            cf1:
              quad: "8"
              net_id: foo
            cf2:
              quad: "9"
              net_id: bar
      STUB
    end

    its([:networks, :cf1, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: foo
            subnet: foo
            security_groups: ~
            availability_zone: ~
          dns: ~
          gateway: 10.11.8.1
          name: default_unused
          range: 10.11.8.0/24
          reserved:
          - 10.11.8.2 - 10.11.8.5
          static:
          - 10.11.8.6 - 10.11.8.50
      RESULT
    end

    its([:networks, :cf2, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: bar
            subnet: bar
            security_groups: ~
            availability_zone: ~
          dns: ~
          gateway: 10.11.9.1
          name: default_unused
          range: 10.11.9.0/24
          reserved:
          - 10.11.9.2 - 10.11.9.5
          static:
          - 10.11.9.6 - 10.11.9.50
      RESULT
    end
  end

  context "using custom networks" do
    let(:stub) do
      <<-STUB.strip_heredoc
        meta:
          networks:
            ipmask: "10.11"
            security_groups: [ foo, bar ]
            cf1:
              quad: "8"
              net_id: foo
              range: 100.20.0.0/20
              gateway: 100.20.0.1
              dns: [100.20.15.253, 100.20.15.252]
              reserved:
              - 100.20.0.2 - 100.20.0.254
              static:
              - 100.20.1.0 - 100.20.5.254
              security_groups: [ foo ]
              availability_zone: foo
            cf2:
              quad: "9"
              net_id: bar
              range: 100.21.0.0/20
              gateway: 100.21.0.1
              dns: [100.21.15.253, 100.21.15.252]
              reserved:
              - 100.21.0.2 - 100.21.0.254
              static:
              - 100.21.1.0 - 100.21.5.254
              security_groups: [ bar ]
              availability_zone: bar
      STUB
    end

    its([:networks, :cf1, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: foo
            subnet: foo
            security_groups: [ foo ]
            availability_zone: foo
          dns: [ 100.20.15.253, 100.20.15.252 ]
          gateway: 100.20.0.1
          name: default_unused
          range: 100.20.0.0/20
          reserved:
          - 100.20.0.2 - 100.20.0.254
          static:
          - 100.20.1.0 - 100.20.5.254
      RESULT
    end

    its([:networks, :cf2, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: bar
            subnet: bar
            security_groups: [ bar ]
            availability_zone: bar
          dns: [ 100.21.15.253, 100.21.15.252 ]
          gateway: 100.21.0.1
          name: default_unused
          range: 100.21.0.0/20
          reserved:
          - 100.21.0.2 - 100.21.0.254
          static:
          - 100.21.1.0 - 100.21.5.254
      RESULT
    end
  end
end
