describe "cf-use-haproxy.yml" do
  subject do
    spiff_merge(template_path("cf-use-haproxy.yml"), stub)
  end

  context "using defaults" do
    let(:stub) do
      <<-STUB.strip_heredoc
        meta:
          floating_static_ips: [ 192.168.0.1 ]
          domain: 192.168.0.1.xip.io
          networks:
            lb1:
              net_id: foo
      STUB
    end

    its([:networks, :lb1, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: foo
            subnet: foo
            security_groups: ~
          dns: ~
          name: default_unused
          gateway: 10.10.0.1
          range: 10.10.0.0/24
          reserved:
          - 10.10.0.2 - 10.10.0.5
          static:
          - 10.10.0.6 - 10.10.0.50
      RESULT
    end

    its([:jobs, :ha_proxy_z1, :networks]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - name: floating
          static_ips: [ 192.168.0.1 ]
        - name: lb1
          default: [dns, gateway]
      RESULT
    end

    its([:properties, :ha_proxy, :ssl_pem]) do
      is_expected.to match /MIIEowIBAAKCAQEAp8E/
    end

    its([:properties, :login, :uaa_certificate]) do
      is_expected.to match /MIIEowIBAAKCAQEAp8E/
    end
  end

  context "using a custom certificate" do
    let(:stub) do
      <<-STUB.strip_heredoc
        meta:
          ha_proxy_ssl_pem: foo
          floating_static_ips: [ 192.168.0.1 ]
          domain: 192.168.0.1.xip.io
          networks:
            lb1:
              net_id: foo
      STUB
    end

    its([:properties, :ha_proxy, :ssl_pem]) do
      is_expected.to eq "foo"
    end

    its([:properties, :login, :uaa_certificate]) do
      is_expected.to match "foo"
    end
  end

  context "using different shared networking setting" do
    let(:stub) do
      <<-STUB.strip_heredoc
        meta:
          floating_static_ips: [ 192.168.0.1 ]
          domain: 192.168.0.1.xip.io
          networks:
            ipmask: "10.11"
            dns: [ 8.8.8.8 ]
            security_groups: [ foo, bar ]
            lb1:
              net_id: foo
      STUB
    end

    its([:networks, :lb1, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: foo
            subnet: foo
            security_groups: [ foo, bar ]
          dns: [ 8.8.8.8 ]
          gateway: 10.11.0.1
          name: default_unused
          range: 10.11.0.0/24
          reserved:
          - 10.11.0.2 - 10.11.0.5
          static:
          - 10.11.0.6 - 10.11.0.50
      RESULT
    end
  end

  context "using different network quad" do
    let(:stub) do
      <<-STUB.strip_heredoc
        meta:
          floating_static_ips: [ 192.168.0.1 ]
          domain: 192.168.0.1.xip.io
          networks:
            ipmask: "10.11"
            lb1:
              quad: "8"
              net_id: foo
      STUB
    end

    its([:networks, :lb1, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: foo
            subnet: foo
            security_groups: ~
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
  end

  context "using custom networks" do
    let(:stub) do
      <<-STUB.strip_heredoc
        meta:
          floating_static_ips: [ 192.168.0.1 ]
          domain: 192.168.0.1.xip.io
          networks:
            ipmask: "10.11"
            security_groups: [ foo, bar ]
            lb1:
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
      STUB
    end

    its([:networks, :lb1, :subnets]) do
      is_expected.to eq(YAML.load(<<-RESULT.strip_heredoc))
        - cloud_properties:
            net_id: foo
            subnet: foo
            security_groups: [ foo ]
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
  end
end
