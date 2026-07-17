# Gentics Portal | php - Helm Chart

## Introduction

This chart bootstraps a Gentics Portal | php.

## Links

* [Installation Guide](https://www.gentics.com/infoportal/cmp/operations/kubernetes/installation_kubernetes/)
* [Documentation](https://gentics.com/portal-php/docs/)
* [Changelog](https://gentics.com/portal-php/docs/changelog/)

## Changelog
### 1.1.2
* New boolean config item `disableSessionsMount` has been added, allowing control over whether the `/portal/storage/framework/sessions` volume is mounted. By default, it is set to `false`

### 1.1.1
* New boolean config item `service.useHttp2` has been added, allowing internal communication via `h2c` protocol.

### 1.1.0
* Update deprecated APIs:
* Kubernetes version 1.19.0 and above now uses `networking.k8s.io/v1`


## Building / Release

Increase `version` in `Chart.yaml` and create git Tag. Then this tag can be pushed to Artifactory

### package current version 
```bash
helm package ./
```

### Upload the generated/packaged file (check filename)

```bash
curl -u USERNAME:PASSWORD -s -w "%{http_code}\n" https://repo.gentics.com/repository/helm/ --upload-file ./gentics-portal-php-xxx.tgz
```
