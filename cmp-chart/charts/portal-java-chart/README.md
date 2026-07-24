# Gentics Portal | java - Helm Chart

## Introduction

This chart bootstraps a Gentics Portal | java.

## Links

* [Documentation](https://gentics.com/portal-java/docs/)
* [Changelog](https://gentics.com/portal-java/docs/changelog/)
* [Environment variables](https://gentics.com/portal-java/docs/development/configuration/#environment-variables)

## Changelog
### 1.2.9
* Allow to set LicenseKey in new structure (CMP 8.2) and optionally via an existing secret

### 1.2.8
* If persistence is disabled no shared volume will be created now

### 1.2.7
* Keycloak is now disabled in default values.yaml
* Allow to configure custom annotations for mesh pods with `podAnnotations`

### 1.2.6
* A new boolean config parameter `service.useHttp2` has been added, allowing the connections with `h2c` protocol.

### 1.2.5
* Add possibility to configure keycloak private client (with secret)

### 1.2.4
* Remove licenkey key insertion mechanism, as this is now natively supported by Portal | java

### 1.2.3
* Fixes for licenseKey, also write when file is empty

### 1.2.2
* Add licenseKey option to provide license key

### 1.2.1
* Add possibility to mount additional volumes

### 1.2.0
* Update deprecated APIs:
  * Kubernetes version 1.19.0 and above now uses `networking.k8s.io/v1`

### 1.1.0
* Make livenessProbe and readinessProbe customizable
* Add startupProbe and make it customizable
* Fix podAntiAffinity constraints
* Add option to fetch Mesh API key from a secret
* Change default CPU requests to 200m from 100m

## Building / Release

Increase `version` in `Chart.yaml` and create git Tag. Then this tag can be pushed to Artifactory

### package current version 
```bash
helm package ./
```

### Upload the generated/packaged file (check filename)

```bash
curl -u USERNAME:PASSWORD -s -w "%{http_code}\n" https://repo.gentics.com/repository/helm/ --upload-file ./gentics-portal-java-xxx.tgz
```
