# rubocop:disable LineLength
# rubocop:disable BlockLength
require 'rspec'
require 'yaml'
require 'bosh/template/evaluation_context'

describe 'routing-api.yml.erb' do
  let(:deployment_manifest_fragment) do
    {
      'index' => 0,
      'job' => { 'name' => 'i_like_bosh' },
      'properties' => {
        'routing_api' => {
          'max_ttl' => '120s',
          'auth_disabled' => false,
          'metrics_reporting_interval' => '30s',
          'statsd_endpoint' => 'localhost:8125',
          'debug_address' => '127.0.0.1:17002',
          'statsd_client_flush_interval' => '300ms',
          'system_domain' => 'system.domain',
          'log_level' => 'info',
          'port' => 3000,
          'router_groups' => [],
          'lock_ttl' => '10s',
          'lock_retry_interval' => '5s',
          'locket' => {
            'api_location' => '',
            'ca_cert' => '',
            'client_cert' => '',
            'client_key' => ''
          },
          'sqldb' => {
            'host' => 'some-host',
            'port' => 3306,
            'type' => 'mysql',
            'schema' => 'routing_api',
            'username' => 'user',
            'password' => 'password',
            'ca_cert' => 'some-cert'
          },
          'skip_consul_lock' => false,
          'admin_port' => 15897
        },
        'skip_ssl_validation' => false,
        'dns_health_check_host' => 'uaa.service.cf.internal',
        'uaa' => {
          'ca_cert' => 'blah-cert',
          'tls_port' => 900,
          'token_endpoint' => 'uaa.token_endpoint'
        },
        'metron' => {
          'port' => 3745
        },
        'consul' => {
          'servers' => 'http://127.0.0.1:8500'
        },
        'release_level_backup' => false
      }
    }
  end

  let(:erb_yaml) do
    File.read(File.join(File.dirname(__FILE__), '../jobs/routing-api/templates/routing-api.yml.erb'))
  end

  subject(:parsed_yaml) do
    binding = Bosh::Template::EvaluationContext.new(deployment_manifest_fragment).get_binding
    YAML.safe_load(ERB.new(erb_yaml).result(binding))
  end

  context 'given a generally valid manifest' do
    describe 'router_groups' do
      context 'when unspecified' do
        it 'defaults to empty' do
          expect(parsed_yaml['router_groups']).to eq([])
        end
      end

      context 'when a port range is specified' do
        before do
          deployment_manifest_fragment['properties']['routing_api']['router_groups'] = [{
            'name' => 'test-router-group',
            'reservable_ports' => '1024-1123',
            'type' => 'tcp'
          }, {
            'name' => 'test-router-group-2',
            'reservable_ports' => '1124,1125,1126',
            'type' => 'tcp'
          }, {
            'name' => 'test-router-group-3',
            'reservable_ports' => '1127, 1128',
            'type' => 'tcp'
          }]
        end
        it 'should parses the port properly' do
          expect(parsed_yaml['router_groups']).to eq([{
            'name' => 'test-router-group',
            'reservable_ports' => '1024-1123',
            'type' => 'tcp'
          }, {
            'name' => 'test-router-group-2',
            'reservable_ports' => '1124,1125,1126',
            'type' => 'tcp'
          }, {
            'name' => 'test-router-group-3',
            'reservable_ports' => '1127, 1128',
            'type' => 'tcp'
          }])
        end
      end
    end
  end
end
