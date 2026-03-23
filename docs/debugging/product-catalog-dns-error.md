## Troubleshooting Docker DNS resolution error

## Scenario:
While running a minimal stack of the opentelemetry ecommerce application, the frontend produced the following error:
" UNAVAILABLE: Name resolution failed for target dns:product-catalog:3550 " this indicated that the frontend service
was unable to resolve or reach the product-catalog service through Docker internal DNS network.

## Steps taken to troubleshoot

- Checked the  product-catalog contianer status "docker compose ps"
- Observed that the container crashes repeatedly and verfied the container exit code status.
- The product-catalog container exited with status 1 means application crashing during startup
- Checked the container logs and verfied the host directory src/product-catalog/products
- The directory was empty which caused the service to fail to startup.

## Root Cause Analysis:
- The product catalog service expects product data during startup.
In the minimal stack configuration, the database service was disabled to reduce resource usage.
As a result the product-catalog service couldn't retrieve product data, causing the application to exit during initialization.
Since the product-catalog container was not running, Docker didn't register it in the internal DNS. This led to Docker DNS resolution problem
observed by the frontend service.

## Fix:
- Ensured that the product-catalog service has access to product data by enabling the required database dependency, or
populating the products directory with the required JSON files. Once the service started successfully, Docker registers it in
the internal DNS and allowed frontend service to resolve it correctly.

## Key Takeaways:

- Docker DNS only resolves running containers on the network.
- Container exit codes are useful for diagnosing startup failures
- Service discovery errors often originate from downstream service crashes
- Checking service dependencies is significant when troubleshooting distributed systems.
 
