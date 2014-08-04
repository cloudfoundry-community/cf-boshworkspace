cf-boshworkspace
================

## Deploy Cloud Foundry

__Create deployment file__
Just as with the microbosh deployment file we need to fill in some information in our Cloud Foundry deployment file.

```
export CF_ELASTIC_IP=<second_elastic_ip>
export SUBNET_ID=<default_vpc_subnet_id>
export DIRECTOR_UUID=$(bosh status | grep UUID | awk '{print $2}')
```

Now lets replace the placehorders in `micro_bosh.yml`

```bash
for VAR in CF_ELASTIC_IP SUBNET_ID DIRECTOR_UUID
do
  eval REP=\$$VAR
  perl -pi -e "s/$VAR/$REP/g" deployments/cf-aws-vpc.yml
done
```

__Upload dependencies__
Our Cloud Foundry deployment depends on the `cf-release` and on the `bosh-stemcell`, before we can deploy we will need to make sure those dependencies have been resolved. Luckily the bosh-workspace has build in support for resolving those depedencies. 
```
bosh deployment cf-aws-vpc
bosh prepare deployment
```
> Alternetavly when not using an inception server, you can use a remote release: 
`bosh upload release goo.gl/ptAhNw`

__Deploy__
With the dependencies resolved it's time to deploy Cloud Foundry version 175. The following changes have been made to the standard amazon templates:

- [Use haproxy instead of elbs](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-use-haproxy.yml)
- [Use postgresql instead of rds](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-use-postgresql.yml)
- [Use nfs instead of an s3 bucket for blobs](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-use-nfs.yml)
- [All secrets have been set to _c1oudc0w_](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-secrets.yml#L95)
- [SSL has been disabled](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-no-ssl.yml)
- [Single availability zone deployment](https://github.com/starkandwayne/cf-boshworkspace/blob/master/templates/cf-single-az.yml)

With the above changes __20 vms__ of different sizes will be deployed.

```
bosh deploy
```
