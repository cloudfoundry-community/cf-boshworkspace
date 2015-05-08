cf-boshworkspace
================

This project's purpose is to help you easily deploy CloudFoundry in various
configurations, small to large, in AWS (Openstack support coming soon). You will
need an extant microbosh instance - see [bosh-bootstrap](https://github.com/cloudfoundry-community/bosh-bootrap)
for an easy-to-use way to get microbosh running.

You may also want to look at [terraform-aws-cf-install](https://github.com/cloudfoundry-community/terraform-aws-cf-install)
for even more automation around this process.

## Deploy Cloud Foundry

__Create deployment file__
Just as with the microbosh deployment file we need to fill in some information in our Cloud Foundry deployment file.

```
export CF_DOMAIN=<domain, like prod.mycloudfoundry.domain or 1.2.3.4.xip.io>
export CF_ADMIN_PASS=<password to use for CF admin, like c1oudc0wc10udc0w>
export CF_ELASTIC_IP=<Elastic IP that will be used as API endpoint, must be allocated but not assigned>
export IPMASK=<First two octects of IP range to use, set in 10.x, like 10.10>
export CF_SUBNET1=<ID of first subnet to use for CF machines, like sg-deadbeef>
export CF_SUBNET2=<ID of second subnet to use for CF machines, like sg-deadbeef>
export LB_SUBNET1=<ID of subnet to use for loadbalancer, like sg-deadbeef>
export CF_SG=<Name of the security group to use for Cloud Foundry machines, like cf or cf-security-group>
export CF_SUBNET1_AZ=<Availability Zone of CF_SUBNET1>
export CF_SUBNET2_AZ=<Availability Zone of CF_SUBNET2>
export LB_SUBNET1_AZ=<Availability Zone of LB_SUBNET1>
export DIRECTOR_UUID=$(bosh status | grep UUID | awk '{print $2}')
```

Now lets replace the placeholders in `cf-aws-tiny.yml` (you can replace that with `cf-aws-large.yml` in the loop below and get the bigger deployment)

```bash
for VAR in CF_DOMAIN CF_ADMIN_PASS CF_ELASTIC_IP IPMASK CF_SUBNET1_AZ CF_SUBNET2_AZ LB_SUBNET1_AZ CF_SUBNET1 CF_SUBNET2 LB_SUBNET1 CF_SG DIRECTOR_UUID
do
  eval REP=\$$VAR
  perl -pi -e "s/$VAR/$REP/g" deployments/cf-aws-tiny.yml
done
```

__Upload dependencies__
Our Cloud Foundry deployment depends on the `cf-release` and on the `bosh-stemcell`, before we can deploy we will need to make sure those dependencies have been resolved. Luckily the bosh-workspace has built-in support for resolving those depedencies.
```
bosh deployment cf-aws-tiny
bosh prepare deployment
```
> Alternatively when not using an inception server, you can use a remote release: 
`bosh upload release https://community-shared-boshreleases.s3.amazonaws.com/boshrelease-cf-196.tgz`

__Deploy__
With the dependencies resolved it's time to deploy Cloud Foundry version 196. The following changes have been made to the standard amazon templates:

- [Use haproxy instead of elbs](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-use-haproxy.yml)
- [Use postgresql instead of rds](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-use-postgresql.yml)
- [Use nfs instead of an s3 bucket for blobs](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-use-nfs.yml)
- [All secrets have been set to _c1oudc0w_](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-secrets.yml#L95)
- [SSL has been disabled](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-no-ssl.yml)
- [Single availability zone deployment](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-single-az.yml)

With the above changes __7 vms__ of different sizes will be deployed. If you use cf-aws-large.yml, it will be __19 vms__.

```
bosh deploy
```

## Scaling cf-aws-tiny

To achieve the VM savings over cf-aws-large.yml cf-aws-tiny.yml colocates a number of like jobs on the same VMs, allowing
you to scale groups of services with eachother. Here's a breakdown of what's running where, to help you decide which VMs to
scale, based on your traffic patterns:

| VM Name | Role | Jobs |
|------|----|-------------|
| data | Data Services | `postgres` `debian_nfs_server` `metron_agent` `consul_agent` |
| haproxy_z1 | Optional LoadBalancer | `haproxy` `metron_agent` `consul_agent` |
| api_z1 | Cloud Controller/Router | `routing-api` `gorouter` `cloud_controller_ng` `nfs_mounter` ` metron_agent` `consul_agent` |
| api_z2 | Cloud Controller/Router | `routing-api` `gorouter` `cloud_controller_ng` `nfs_mounter` ` metron_agent` `consul_agent` |
| backbone_z1 | Infrastructural Services | `nats` `nats_stream_forwarder` `doppler` `syslog_drain_binder` `etcd` `etcd_metrics_server` `metron_agent` `consul_agent` |
| backbone_z2 | Infrastructural Services | `nats` `nats_stream_forwarder` `doppler` `syslog_drain_binder` `etcd` `etcd_metrics_server` `metron_agent` `consul_agent` |
| health_z1 | Health Checking Services | `loggregator_trafficcontroller` `hm9000` `cloud_controller_clock` `collector` `metron_agent` `consul_agent` |
| health_z2 | Health Checking Services | `loggregator_trafficcontroller` `hm9000` `cloud_controller_clock` `collector` `metron_agent` `consul_agent` |
| services_z1 | Support Services | `uaa` `login` `cloud_controller_worker` `nfs_mounter` `metron_agent` `consul_agent` |
| services_z2 | Support Services | `uaa` `login` `cloud_controller_worker` `nfs_mounter` `metron_agent` `consul_agent` |
| runner_z1 | DEA nodes | `dea_next` `dea_logging_agent` `metron_agent` `consul_agent` |
| runner_z2 | DEA nodes | `dea_next` `dea_logging_agent` `metron_agent` `consul_agent` |

By default, none of the \*\_z2 nodes are enabled in cf-aws-tiny.yml, to keep the basic deployment minimal.
If you wish to make your deployment more fault tolerant, deploy some \*\_z2 instances to run in your second availability zone.

## Migrating from cf-tiny-dev to cf-tiny-scalable

Previously, a template called _cf-tiny-dev_ had been used to consolidate jobs into a small number of VMs. Recently, that
has been replaced with _cf-tiny-scalable_, allowing for multi-AZ scalable deployments of CloudFoundry on a smaller footprint
than the upstream deployment. However, it involved some job name changes, which requires some extra care when migrating from
one to the other. These steps are laid out below:

**CAUTION!** Do ***NOT*** run `bosh deploy` at any point during the migration, unless the instructions indicate it. bosh-workspace will
    erase your current deployment manifest, which you will have been manually updating to prepare the migration. You will
    then have a large headache, and a mouth full of explitives.

1.  Rename existing jobs:
    ```bash
for job in health services api haproxy; do
    # edit the instance names in your deployment
    vi .deployments/cf-aws-tiny.yml  # NOTE: '.deployments', not 'deployments'

    # rename the bosh job - takes about 1 min per job
    bosh rename job $job ${job}_z1
done
```
    Beware of using `sed` for the above steps - bosh won't let you rename if you make any changes other than job name.

    **NOTE:** If you happen to run into issues renaming a job, `bosh ssh` into the VM, find what service is failing, via
    `/var/vcap/bosh/bin/monit summary`, and troubleshoot the service until it will start up normally. Then retry the `bosh rename job`
    task.

2.  Ensure all VMs are named correctly:
   ```
$ bosh vms
Deployment 'cf-aws-tiny'
Director task 210
Task 210 done
+---------------+---------+---------------+-------------+
| Job/index     | State   | Resource Pool | IPs         |
+---------------+---------+---------------+-------------+
| api_z1/0      | running | medium_z1     | 10.10.3.7   |
| data/0        | running | large_z1      | 10.10.3.10  |
| haproxy_z1/0  | running | small_z1      | 52.7.24.173 |
|               |         |               | 10.10.2.6   |
| health_z1/0   | running | medium_z1     | 10.10.3.9   |
| runner_z1/0   | running | runner_z1     | 10.10.3.57  |
| services_z1/0 | running | medium_z1     | 10.10.3.8   |
+---------------+---------+---------------+-------------+
```
    Depending on your deployment, the IPs and resource pools may differ.

3.  Update your deployment template (something like `deployments/cf-aws-tiny.yml`) to include the `tiny/cf-tiny-scalable.yml` template, instead of `tiny/cf-tiny-dev.yml`
4.  Generate + deploy the new manifest via `bosh deploy`
5.  Celebrate by cracking open a tasty beverage!
