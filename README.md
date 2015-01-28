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

With the above changes __5 vms__ of different sizes will be deployed. If you use cf-aws-large.yml, it will be __19 vms__.

```
bosh deploy
```
